import Vapor

struct NLPService {
    static func geocode(query: String, client: any Client, apiKey: String, logger: Logger) async throws -> ResolvedLocation {
        logger.info("NLP geocode request", metadata: ["query": "\(query)"])

        let systemMsg = "You are a specialized geocoding agent. Your task is to take a user's location query and resolve it to a JSON object containing 'lat' (Float), 'lng' (Float), and 'displayName' (String). Handle landmarks, slang, and common city nicknames."

        let payload = GeminiRequest(
            contents: [
                .init(parts: [.init(text: "Resolve this location: \(query)")])
            ],
            systemInstruction: .init(parts: [.init(text: systemMsg)]),
            generationConfig: .init(responseMimeType: "application/json")
        )
        
        // Use header auth so the key never appears in server access logs.
        let url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent"

        let response = try await client.post(URI(string: url)) { req in
            try req.content.encode(payload, as: .json)
            req.headers.add(name: "x-goog-api-key", value: apiKey)
        }
        
        let rawBody = response.body.map { String(buffer: $0) } ?? "(empty)"

        guard response.status == .ok else {
            logger.error("Gemini API error", metadata: ["status": "\(response.status)", "body": "\(rawBody)"])
            throw Abort(.badGateway, reason: "Gemini API returned status \(response.status)")
        }

        logger.debug("Gemini raw response", metadata: ["body": "\(rawBody)"])

        let geminiResult: GeminiGeocodeResponse
        do {
            geminiResult = try response.content.decode(GeminiGeocodeResponse.self)
        } catch {
            logger.error("Gemini decode failed", metadata: ["error": "\(error)", "body": "\(rawBody)"])
            throw error
        }

        guard let jsonString = geminiResult.candidates.first?.content.parts.first?.text else {
            logger.error("Gemini response missing content", metadata: ["candidates": "\(geminiResult.candidates.count)", "body": "\(rawBody)"])
            throw Abort(.internalServerError, reason: "NLP Geocoding failed to return valid content.")
        }

        logger.info("Gemini geocode result", metadata: ["raw": "\(jsonString)"])

        guard let data = jsonString.data(using: .utf8) else {
            throw Abort(.internalServerError, reason: "NLP response contained invalid UTF-8 data.")
        }
        let location = try JSONDecoder().decode(ResolvedLocation.self, from: data)
        logger.info("Resolved location", metadata: ["lat": "\(location.lat)", "lng": "\(location.lng)", "display": "\(location.displayName)"])
        return location
    }
}