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
    static func geocode(query: String, client: any Client, apiKey: String, logger: Logger) async throws -> ResolvedLocation {
        if let cached = await GeocodeCache.shared.get(query) {
            logger.info("Geocode cache hit", metadata: ["query": "\(query)"])
            return cached
        }

        logger.info("Geocode request", metadata: ["query": "\(query)"])

        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let url = "https://maps.googleapis.com/maps/api/geocode/json?address=\(encodedQuery)&key=\(apiKey)"

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
