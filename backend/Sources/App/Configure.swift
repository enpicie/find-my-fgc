import Vapor

// Application wiring, deliberately kept out of main.swift.
//
// main.swift is top-level executable code: it cannot be invoked from a test, so a test
// that wanted to check the middleware order had no choice but to build its own
// Application and re-declare the configuration — which asserts against a copy and stays
// green no matter what the server actually does. Both main.swift and CORSMiddlewareTests
// call the functions below, so the ordering that is tested is the ordering that ships.

// MARK: - Middleware

/// Installs the application's middleware stack.
func configureMiddleware(_ app: Application) {
    // ALLOWED_ORIGIN should be set to your CloudFront domain in production.
    // Falls back to .all when unset (local dev / docker-compose).
    let allowedOrigin: CORSMiddleware.AllowOriginSetting = Environment.get("ALLOWED_ORIGIN")
        .map { .custom($0) } ?? .all

    let corsConfiguration = CORSMiddleware.Configuration(
        allowedOrigin: allowedOrigin,
        allowedMethods: [.GET, .POST, .OPTIONS],
        allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith]
    )

    // `at: .beginning` is load-bearing — do not drop it. Vapor seeds app.middleware with
    // RouteLoggingMiddleware and ErrorMiddleware, and the default `use(_:)` appends, which
    // would leave CORS *inside* ErrorMiddleware. A thrown Abort then reaches CORS as a failed
    // future, so CORSMiddleware's `response.map { ... }` never runs, and ErrorMiddleware —
    // sitting upstream — turns the error into a Response that never passes back through CORS.
    // The result is error responses with no Access-Control-* headers, which a browser reports
    // as an opaque "Failed to fetch" instead of the API's actual reason string. Inserting CORS
    // at the front puts it outside ErrorMiddleware, so error responses get the headers too.
    app.middleware.use(CORSMiddleware(configuration: corsConfiguration), at: .beginning)
}

// MARK: - Routes

/// Registers the application's routes. The API keys are passed in rather than read here so
/// that a missing key fails at boot (see main.swift) rather than on the first request.
func configureRoutes(_ app: Application, startGGKey: String, mapsKey: String) {
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
}
