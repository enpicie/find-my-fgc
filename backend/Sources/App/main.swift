import Vapor

// MARK: - Request Models
struct TournamentRequest: Content {
    let lat: Double
    let lng: Double
    let radius: String
    let gameIds: [Int]?
}

// MARK: - GraphQL Structure
struct GraphQLRequest: Content {
    let query: String
    let variables: TournamentVariables
}

struct TournamentVariables: Content {
    let coordinates: String
    let radius: String
    let videogameIds: [String]?
}

// MARK: - start.gg Response Models
struct StartGGResponse: Content {
    let data: StartGGData?
    let errors: [StartGGError]?
}

struct StartGGError: Content {
    let message: String
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

// MARK: - Output Models
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

// MARK: - App Configuration
let app = try await Application.make()
defer { app.shutdown() }

// Explicitly bind to 0.0.0.0 and port 8080
// This is critical for Docker and some cloud environments
app.http.server.configuration.hostname = "0.0.0.0"
app.http.server.configuration.port = 8080

// CORS Config
let corsConfiguration = CORSMiddleware.Configuration(
    allowedOrigin: .all,
    allowedMethods: [.GET, .POST, .OPTIONS],
    allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin]
)
app.middleware.use(CORSMiddleware(configuration: corsConfiguration))

// MARK: - Routes
app.post("tournaments") { req -> [TournamentOutput] in
    let search = try req.content.decode(TournamentRequest.self)
    
    guard let apiKey = Environment.get("STARTGG_API_KEY") else {
        req.logger.error("Environment variable STARTGG_API_KEY is missing")
        throw Abort(.internalServerError, reason: "STARTGG_API_KEY is not set.")
    }
    
    let coordinateString = "\(search.lat),\(search.lng)"
    
    // Prepare videogameIds: use [String] if provided, otherwise nil (which becomes null in JSON)
    let videogameIds: [String]? = (search.gameIds != nil && !search.gameIds!.isEmpty) 
        ? search.gameIds!.map { String($0) } 
        : nil
    
    let variables = TournamentVariables(
        coordinates: coordinateString,
        radius: search.radius,
        videogameIds: videogameIds
    )
    
    let gqlPayload = GraphQLRequest(
        query: GQLQueries.tournamentsByLocation,
        variables: variables
    )
    
    let response = try await req.client.post("https://api.start.gg/gql/alpha") { gqlReq in
        try gqlReq.content.encode(gqlPayload, as: .json)
        gqlReq.headers.add(name: "Authorization", value: "Bearer \(apiKey)")
    }
    
    // Check if the upstream request was successful
    guard response.status == .ok else {
        let body = response.body?.getString(at: 0, length: response.body?.readableBytes ?? 0) ?? "No body"
        req.logger.error("start.gg API error: \(response.status) - \(body)")
        throw Abort(.badRequest, reason: "start.gg API returned status \(response.status)")
    }
    
    let startGGResponse = try response.content.decode(StartGGResponse.self)
    
    if let errors = startGGResponse.errors {
        req.logger.error("start.gg API Errors: \(errors.map { $0.message }.joined(separator: ", "))")
        throw Abort(.badRequest, reason: "start.gg returned errors in response body.")
    }
    
    guard let nodes = startGGResponse.data?.tournaments?.nodes else {
        return []
    }
    
    return nodes.map { node in
        let image = node.images?.first(where: { $0.type == "profile" })?.url ?? 
                    node.images?.first(where: { $0.type == "banner" })?.url ?? 
                    node.images?.first?.url ?? ""
        
        let locationStr = [node.city, node.addrState]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
            
        // Collect unique game names from events
        let gameNames = Array(Set(node.events?.compactMap { $0.videogame?.name } ?? []))
            .sorted()
            .joined(separator: ", ")

        return TournamentOutput(
            id: "\(node.id)",
            name: node.name,
            location: locationStr.isEmpty ? "Location Unknown" : locationStr,
            venueAddress: node.venueAddress ?? "Online / See Details",
            date: "\(node.startAt)",
            externalUrl: "https://start.gg\(node.url)",
            image: image,
            games: gameNames
        )
    }
}

try await app.execute()