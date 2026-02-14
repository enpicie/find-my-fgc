import Vapor

struct NLPService {
    static func geocode(query: String, client: Client, apiKey: String) async throws -> ResolvedLocation {
        let systemMsg = "You are a specialized geocoding agent. Your task is to take a user's location query and resolve it to a JSON object containing 'lat' (Float), 'lng' (Float), and 'displayName' (String). Handle landmarks, slang, and common city nicknames."
        
        let payload = GeminiRequest(
            contents: [
                .init(parts: [.init(text: "Resolve this location: \(query)")])
            ],
            systemInstruction: .init(parts: [.init(text: systemMsg)]),
            generationConfig: .init(responseMimeType: "application/json")
        )
        
        let url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent?key=\(apiKey)"
        
        let response = try await client.post(URI(string: url)) { req in
            try req.content.encode(payload, as: .json)
        }
        
        guard response.status == .ok else {
            throw Abort(.badGateway, reason: "Gemini API returned status \(response.status)")
        }
        
        let geminiResult = try response.content.decode(GeminiGeocodeResponse.self)
        guard let jsonString = geminiResult.candidates.first?.content.text else {
            throw Abort(.internalServerError, reason: "NLP Geocoding failed to return valid content.")
        }
        
        let data = jsonString.data(using: .utf8)!
        return try JSONDecoder().decode(ResolvedLocation.self, from: data)
    }
}