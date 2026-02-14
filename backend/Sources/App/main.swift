import Vapor

let app = try await Application.make()
defer { app.shutdown() }

// MARK: - Server Configuration
app.http.server.configuration.hostname = "0.0.0.0"
app.http.server.configuration.port = 8080

// MARK: - Middleware
let corsConfiguration = CORSMiddleware.Configuration(
    allowedOrigin: .all,
    allowedMethods: [.GET, .POST, .OPTIONS],
    allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith]
)
app.middleware.use(CORSMiddleware(configuration: corsConfiguration))

// MARK: - Routes
app.post("tournaments") { req -> UnifiedResponse in
    let search = try req.content.decode(TournamentRequest.self)
    
    guard let startGGKey = Environment.get("STARTGG_API_KEY"),
          let geminiKey = Environment.get("GEMINI_API_KEY") else {
        throw Abort(.internalServerError, reason: "Server configuration error: API keys are missing.")
    }
    
    // 1. NLP Geocoding Mode: Resolve user query to coordinates
    let location = try await NLPService.geocode(
        query: search.query, 
        client: req.client, 
        apiKey: geminiKey
    )
    
    // 2. Fetch Tournament Data: Query start.gg using resolved coordinates
    let tournaments = try await TournamentService.fetchTournaments(
        location: location,
        radius: search.radius,
        gameIds: search.gameIds,
        client: req.client,
        apiKey: startGGKey
    )
    
    return UnifiedResponse(
        tournaments: tournaments,
        center: LocationCoord(lat: location.lat, lng: location.lng),
        displayName: location.displayName
    )
}

try await app.execute()