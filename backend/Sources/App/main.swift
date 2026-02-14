
import Vapor

// MARK: - Input Models
struct TournamentRequest: Content {
    let query: String
    let radius: String
    let gameIds: [Int]?
}

// MARK: - Gemini Geocoding Models
struct GeminiGeocodeResponse: Content {
    struct Candidate: Content {
        struct ContentPart: Content {
            let text: String
        }
        let content: ContentPart
    }
    let candidates: [Candidate]
}

struct ResolvedLocation: Content {
    let lat: Double
    let lng: Double
    let displayName: String
}

// MARK: - Output Models
struct UnifiedResponse: Content {
    let tournaments: [TournamentOutput]
    let center: LocationCoord
    let displayName: String
}

struct LocationCoord: Content {
    let lat: Double
    let lng: Double
}

struct TournamentOutput: Content {
    let id: String
    let name: String
    let location: String
    let venueAddress: String
    let date: String
    let externalUrl: String
    let image: String
    let games: String
}

// MARK: - start.gg Request/Response Models
struct GraphQLRequest: Content {
    let query: String
    let variables: TournamentVariables
}

struct TournamentVariables: Content {
    let coordinates: String
    let radius: String
    let videogameIds: [String]?
}

struct StartGGResponse: Content {
    let data: StartGGData?
}

struct StartGGData: Content {
    let tournaments: TournamentsNode?
}

struct TournamentsNode: Content {
    let nodes: [TournamentNode]?
}

struct TournamentNode: Content {
    let id: Int
    let name: String
    let city: String?
    let addrState: String?
    let venueAddress: String?
    let startAt: Int
    let url: String
    let images: [StartGGImage]?
    let events: [EventNode]?
}

struct EventNode: Content {
    let id: Int
    let name: String
    let videogame: VideogameNode?
}

struct VideogameNode: Content {
    let id: Int
    let name: String
}

struct StartGGImage: Content {
    let url: String
    let type: String
}

// MARK: - App Setup
let app = try await Application.make()
defer { app.shutdown() }

app.http.server.configuration.hostname = "0.0.0.0"
app.http.server.configuration.port = 8080

let corsConfiguration = CORSMiddleware.Configuration(
    allowedOrigin: .all,
    allowedMethods: [.GET, .POST, .OPTIONS],
    allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith]
)
app.middleware.use(CORSMiddleware(configuration: corsConfiguration))

// MARK: - Helper Function: Geocode via Gemini
func geocode(query: String, client: Client, apiKey: String) async throws -> ResolvedLocation {
    let prompt = "Convert this location to JSON with lat (Double), lng (Double), and displayName (String): \(query)"
    let url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=\(apiKey)"
    
    let geminiPayload: [String: AnyJSON] = [
        "contents": .array([
            .object([
                "parts": .array([
                    .object(["text": .string(prompt)])
                ])
            ])
        ]),
        "generationConfig": .object([
            "responseMimeType": .string("application/json")
        ])
    ]
    
    let response = try await client.post(URI(string: url)) { req in
        try req.content.encode(geminiPayload, as: .json)
    }
    
    let geminiResult = try response.content.decode(GeminiGeocodeResponse.self)
    guard let jsonString = geminiResult.candidates.first?.content.text else {
        throw Abort(.internalServerError, reason: "AI failed to geocode location")
    }
    
    let data = jsonString.data(using: .utf8)!
    return try JSONDecoder().decode(ResolvedLocation.self, from: data)
}

// MARK: - Routes
app.post("tournaments") { req -> UnifiedResponse in
    let search = try req.content.decode(TournamentRequest.self)
    
    guard let startGGKey = Environment.get("STARTGG_API_KEY"),
          let geminiKey = Environment.get("GEMINI_API_KEY") else {
        throw Abort(.internalServerError, reason: "API keys not configured on server")
    }
    
    // 1. Geocode the user's query using Gemini on the backend
    let location = try await geocode(query: search.query, client: req.client, apiKey: geminiKey)
    
    // 2. Fetch Tournaments from start.gg
    let videogameIds: [String]? = (search.gameIds != nil && !search.gameIds!.isEmpty) 
        ? search.gameIds!.map { String($0) } 
        : nil
    
    let variables = TournamentVariables(
        coordinates: "\(location.lat),\(location.lng)",
        radius: search.radius,
        videogameIds: videogameIds
    )
    
    let gqlPayload = GraphQLRequest(query: GQLQueries.tournamentsByLocation, variables: variables)
    
    let startGGResponse = try await req.client.post("https://api.start.gg/gql/alpha") { gqlReq in
        try gqlReq.content.encode(gqlPayload, as: .json)
        gqlReq.headers.add(name: "Authorization", value: "Bearer \(startGGKey)")
    }
    
    let startGGData = try startGGResponse.content.decode(StartGGResponse.self)
    let nodes = startGGData.data?.tournaments?.nodes ?? []
    
    let tournaments = nodes.map { node in
        let image = node.images?.first(where: { $0.type == "profile" })?.url ?? node.images?.first?.url ?? ""
        let locStr = [node.city, node.addrState].compactMap { $0 }.joined(separator: ", ")
        let gameNames = Array(Set(node.events?.compactMap { $0.videogame?.name } ?? [])).sorted().joined(separator: ", ")

        return TournamentOutput(
            id: "\(node.id)",
            name: node.name,
            location: locStr,
            venueAddress: node.venueAddress ?? "See Details",
            date: "\(node.startAt)",
            externalUrl: "https://start.gg\(node.url)",
            image: image,
            games: gameNames
        )
    }
    
    return UnifiedResponse(
        tournaments: tournaments,
        center: LocationCoord(lat: location.lat, lng: location.lng),
        displayName: location.displayName
    )
}

try await app.execute()
