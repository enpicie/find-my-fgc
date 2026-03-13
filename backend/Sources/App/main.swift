import Vapor

// .detect() reads --env from CLI args, so CMD ["serve", "--env", "production", ...]
// in the Dockerfile correctly sets production mode at container startup.
// LoggingSystem.bootstrap must be called before Application.make so that
// LOG_LEVEL env var is respected by all loggers.
var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)
let app = try await Application.make(env)

// MARK: - Server Configuration
app.http.server.configuration.hostname = "0.0.0.0"
app.http.server.configuration.port = 8080

// MARK: - HTTP Client Configuration
// Prevents hung requests to Maps / start.gg from blocking event loop threads.
app.http.client.configuration.timeout = .init(connect: .seconds(5), read: .seconds(15))

// MARK: - Middleware
// ALLOWED_ORIGIN should be set to your CloudFront domain in production.
// Falls back to .all when unset (local dev / docker-compose).
let allowedOrigin: CORSMiddleware.AllowOriginSetting = Environment.get("ALLOWED_ORIGIN")
    .map { .custom($0) } ?? .all

let corsConfiguration = CORSMiddleware.Configuration(
    allowedOrigin: allowedOrigin,
    allowedMethods: [.GET, .POST, .OPTIONS],
    allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith]
)
app.middleware.use(CORSMiddleware(configuration: corsConfiguration))

// MARK: - Startup Validation
// Read once so misconfiguration fails immediately at boot, not at first request.
guard let startGGKey = Environment.get("STARTGG_API_KEY"),
      let mapsKey = Environment.get("GOOGLE_MAPS_API_KEY") else {
    app.logger.critical("Required environment variables STARTGG_API_KEY and GOOGLE_MAPS_API_KEY must be set.")
    exit(1)
}

// MARK: - Routes

// Health check — targeted by ECS container agent and ALB target group.
app.get("health") { _ in HTTPStatus.ok }

app.post("tournaments") { req -> UnifiedResponse in
    let rawBody = req.body.string ?? "(empty)"
    req.logger.debug("POST /tournaments raw body", metadata: ["body": "\(rawBody)"])

    let search: TournamentRequest
    do {
        search = try req.content.decode(TournamentRequest.self)
    } catch {
        req.logger.error("Request decode failed", metadata: ["error": "\(error)", "body": "\(rawBody)"])
        throw error
    }

    req.logger.info("POST /tournaments", metadata: [
        "query": "\(search.query)", "radius": "\(search.radius)", "gameIds": "\(search.gameIds ?? [])"
    ])

    let location = try await NLPService.geocode(
        query: search.query,
        client: req.client,
        apiKey: mapsKey,
        logger: req.logger
    )

    let tournaments = try await TournamentService.fetchTournaments(
        location: location,
        radius: search.radius,
        gameIds: search.gameIds,
        client: req.client,
        apiKey: startGGKey,
        logger: req.logger
    )

    req.logger.info("POST /tournaments complete", metadata: ["tournamentCount": "\(tournaments.count)"])
    return UnifiedResponse(
        tournaments: tournaments,
        center: LocationCoord(lat: location.lat, lng: location.lng),
        displayName: location.displayName
    )
}

do {
    try await app.execute()
} catch {
    try await app.asyncShutdown()
    throw error
}
try await app.asyncShutdown()
