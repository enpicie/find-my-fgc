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
// Defined in Configure.swift so the test suite exercises this exact wiring.
configureMiddleware(app)

// MARK: - Startup Validation
// Read once so misconfiguration fails immediately at boot, not at first request.
guard let startGGKey = Environment.get("STARTGG_API_KEY"),
      let mapsKey = Environment.get("GOOGLE_MAPS_API_KEY") else {
    app.logger.critical("Required environment variables STARTGG_API_KEY and GOOGLE_MAPS_API_KEY must be set.")
    exit(1)
}

// MARK: - Routes
// Defined in Configure.swift so the test suite exercises these exact routes.
configureRoutes(app, startGGKey: startGGKey, mapsKey: mapsKey)

do {
    try await app.execute()
} catch {
    try await app.asyncShutdown()
    throw error
}
try await app.asyncShutdown()
