import Vapor

// Simple in-memory geocode cache. Keys are lowercased query strings.
// Actor ensures safe concurrent access across async request handlers.
actor GeocodeCache {
    static let shared = GeocodeCache()
    private var store: [String: ResolvedLocation] = [:]

    func get(_ key: String) -> ResolvedLocation? { store[key.lowercased()] }
    func set(_ key: String, _ value: ResolvedLocation) { store[key.lowercased()] = value }
}

// MARK: - Google Maps Geocoding API response models

private struct MapsGeocodeResponse: Content {
    let status: String
    let results: [MapsResult]

    struct MapsResult: Content {
        let formatted_address: String
        let geometry: Geometry
        let types: [String]?
        let partial_match: Bool?

        struct Geometry: Content {
            let location: LatLng

            struct LatLng: Content {
                let lat: Double
                let lng: Double
            }
        }
    }
}

// MARK: - Service

struct NLPService {
    // A bare postal code is globally ambiguous, and Google's geocoder handles that
    // badly without a country hint: some valid US ZIPs come back ZERO_RESULTS
    // ("90210", "44444"), and others resolve to the wrong country entirely
    // ("01828" -> Warsaw, "55555" -> Saudi Arabia). Constraining the lookup to the
    // country whose format the query matches fixes both. Free-text queries are left
    // unrestricted so international searches — and ambiguous names like "london",
    // which resolves to London, UK — keep behaving as they do today.
    static func countryComponent(for query: String) -> String? {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        if isUSZIPCode(trimmed) { return "US" }
        if isCanadianPostalCode(trimmed) { return "CA" }
        return nil
    }

    // Matches "12345" and ZIP+4 "12345-6789".
    private static func isUSZIPCode(_ value: String) -> Bool {
        let parts = value.split(separator: "-", omittingEmptySubsequences: false)
        func isDigits(_ s: Substring, _ count: Int) -> Bool {
            s.count == count && s.allSatisfy { $0.isASCII && $0.isNumber }
        }
        switch parts.count {
        case 1: return isDigits(parts[0], 5)
        case 2: return isDigits(parts[0], 5) && isDigits(parts[1], 4)
        default: return false
        }
    }

    // Matches "J4H 2P3" and "J4H2P3" (letter-digit-letter digit-letter-digit).
    private static func isCanadianPostalCode(_ value: String) -> Bool {
        let chars = Array(value.uppercased().filter { !$0.isWhitespace })
        guard chars.count == 6, chars.allSatisfy(\.isASCII) else { return false }
        return chars[0].isLetter && chars[1].isNumber && chars[2].isLetter
            && chars[3].isNumber && chars[4].isLetter && chars[5].isNumber
    }

    static func geocode(query: String, client: any Client, apiKey: String, logger: Logger) async throws -> ResolvedLocation {
        if let cached = await GeocodeCache.shared.get(query) {
            logger.info("Geocode cache hit", metadata: ["query": "\(query)"])
            return cached
        }

        let country = countryComponent(for: query)
        logger.info("Geocode request", metadata: ["query": "\(query)", "country": "\(country ?? "unrestricted")"])

        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        var url = "https://maps.googleapis.com/maps/api/geocode/json?address=\(encodedQuery)&key=\(apiKey)"
        if let country {
            url += "&components=country:\(country)"
        }

        let response = try await client.get(URI(string: url))
        let rawBody = response.body.map { String(buffer: $0) } ?? "(empty)"

        guard response.status == .ok else {
            logger.error("Maps API HTTP error", metadata: ["status": "\(response.status)", "body": "\(rawBody)"])
            throw Abort(.badGateway, reason: "Geocoding API returned status \(response.status)")
        }

        let mapsResponse: MapsGeocodeResponse
        do {
            mapsResponse = try response.content.decode(MapsGeocodeResponse.self)
        } catch {
            logger.error("Maps API decode failed", metadata: ["error": "\(error)", "body": "\(rawBody)"])
            throw error
        }

        guard mapsResponse.status == "OK", let result = mapsResponse.results.first else {
            logger.error("Maps API returned no results", metadata: ["status": "\(mapsResponse.status)", "query": "\(query)"])
            let reason = mapsResponse.status == "REQUEST_DENIED"
                ? "Geocoding API key is invalid or not authorized. Check GOOGLE_MAPS_API_KEY and ensure the Geocoding API is enabled."
                : "Could not resolve location: \"\(query)\" (Maps status: \(mapsResponse.status))"
            throw Abort(.unprocessableEntity, reason: reason)
        }

        // With a country component applied, Google answers an unresolvable postal code
        // by falling back to the country itself rather than ZERO_RESULTS: "01828" and
        // "55555" both come back OK/partial_match with types ["country"], pointing at the
        // contiguous-US centroid in rural Colorado. Accepting that would return HTTP 200
        // and a confident displayName for a location the user never asked for, hiding the
        // failure inside the zero-result rate. Fail honestly instead.
        if country != nil, result.types?.contains("country") == true {
            logger.error("Geocode fell back to country centroid", metadata: [
                "query": "\(query)",
                "country": "\(country ?? "")",
                "display": "\(result.formatted_address)",
                "partial": "\(result.partial_match ?? false)",
            ])
            throw Abort(.unprocessableEntity, reason: "Could not resolve location: \"\(query)\"")
        }

        let location = ResolvedLocation(
            lat: result.geometry.location.lat,
            lng: result.geometry.location.lng,
            displayName: result.formatted_address
        )
        logger.info("Resolved location", metadata: ["lat": "\(location.lat)", "lng": "\(location.lng)", "display": "\(location.displayName)"])
        await GeocodeCache.shared.set(query, location)
        return location
    }
}
