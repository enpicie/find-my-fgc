import XCTest
import Vapor
import XCTVapor
@testable import App

/// Proves that error responses carry CORS headers.
///
/// The bug this guards against is invisible from the server side: the API returns a
/// perfectly good 422 with a human-readable reason, but because the response has no
/// Access-Control-Allow-Origin header the browser discards it and the user sees an
/// opaque "Failed to fetch" with no explanation. It only reproduces through the real
/// middleware chain, in the real order, so these tests call `configureMiddleware` and
/// `configureRoutes` — the same functions main.swift calls — rather than re-declaring
/// the configuration locally. A test that built its own CORS config would pass even
/// with the fix reverted, which is exactly the failure mode being avoided here.
final class CORSMiddlewareTests: XCTestCase {

    private static let origin = "https://findmyfgc.example.com"

    /// The reason string the geocode 422 path produces in production. Nothing here needs
    /// the network: the route under test fails at request decoding, before any client call.
    private static let abortReason = "Could not resolve location: \"55555\""

    private func withConfiguredApp(_ body: (Application) async throws -> Void) async throws {
        let app = try await Application.make(.testing)
        do {
            configureMiddleware(app)
            configureRoutes(app, startGGKey: "test-startgg-key", mapsKey: "test-maps-key")

            // Stands in for any handler that throws — NLPService.geocode throws exactly
            // this Abort when Google cannot resolve a query. Reaching the real one would
            // require a live Maps call, so the thrown error is reproduced directly and the
            // middleware chain around it is the real one.
            app.get("test-throws-abort") { (_: Request) throws -> String in
                throw Abort(.unprocessableEntity, reason: Self.abortReason)
            }

            try await body(app)
        } catch {
            try? await app.asyncShutdown()
            throw error
        }
        try await app.asyncShutdown()
    }

    // MARK: - The regression under test

    /// THE test. Revert `at: .beginning` in configureMiddleware and this fails: the status
    /// and body stay correct, only the CORS header disappears.
    func testThrownAbortStillCarriesCORSHeaders() async throws {
        try await self.withConfiguredApp { app in
            try await app.test(.GET, "test-throws-abort", headers: ["Origin": Self.origin]) { res in
                XCTAssertEqual(res.status, .unprocessableEntity)
                XCTAssertEqual(res.headers.first(name: .accessControlAllowOrigin), "*")
                XCTAssertNotNil(res.headers.first(name: .accessControlAllowMethods))
                // The whole point of getting the headers onto the error: the browser can
                // now read the reason instead of reporting an opaque network failure.
                XCTAssertTrue(String(buffer: res.body).contains("Could not resolve location"), String(buffer: res.body))
            }
        }
    }

    /// The same guarantee via a real route rather than a test-only one: POST /tournaments
    /// with a body that cannot be decoded throws before any outbound request is made, so
    /// this exercises the production handler's own error path end to end.
    func testRealRouteErrorResponseCarriesCORSHeaders() async throws {
        try await self.withConfiguredApp { app in
            try await app.test(
                .POST,
                "tournaments",
                headers: ["Origin": Self.origin, "Content-Type": "application/json"],
                body: ByteBuffer(string: "{\"unexpected\":true}")
            ) { res in
                XCTAssertGreaterThanOrEqual(res.status.code, 400, "expected the decode failure to be an error response")
                XCTAssertEqual(res.headers.first(name: .accessControlAllowOrigin), "*")
            }
        }
    }

    /// Structural companion to the behavioural tests above: names the cause directly, so a
    /// regression reports "CORS is behind ErrorMiddleware" rather than just a missing header.
    func testCORSMiddlewareIsRegisteredAheadOfErrorMiddleware() async throws {
        try await self.withConfiguredApp { app in
            let stack = app.middleware.resolve()
            let corsIndex = stack.firstIndex { $0 is CORSMiddleware }
            let errorIndex = stack.firstIndex { $0 is ErrorMiddleware }

            let cors = try XCTUnwrap(corsIndex, "CORSMiddleware is not registered at all")
            let error = try XCTUnwrap(errorIndex, "ErrorMiddleware is not registered at all")
            XCTAssertEqual(cors, 0, "CORSMiddleware must be first so it wraps everything downstream")
            XCTAssertLessThan(cors, error, "CORSMiddleware must sit outside ErrorMiddleware")
        }
    }

    // MARK: - Surrounding CORS behaviour

    func testSuccessResponseCarriesCORSHeaders() async throws {
        try await self.withConfiguredApp { app in
            try await app.test(.GET, "health", headers: ["Origin": Self.origin]) { res in
                XCTAssertEqual(res.status, .ok)
                XCTAssertEqual(res.headers.first(name: .accessControlAllowOrigin), "*")
            }
        }
    }

    /// The browser preflights POST /tournaments before it will send the real request.
    func testPreflightRequestIsAnswered() async throws {
        try await self.withConfiguredApp { app in
            try await app.test(
                .OPTIONS,
                "tournaments",
                headers: [
                    "Origin": Self.origin,
                    "Access-Control-Request-Method": "POST",
                    "Access-Control-Request-Headers": "content-type",
                ]
            ) { res in
                XCTAssertEqual(res.status, .ok)
                XCTAssertEqual(res.headers.first(name: .accessControlAllowOrigin), "*")
                let methods = res.headers.first(name: .accessControlAllowMethods) ?? ""
                XCTAssertTrue(methods.contains("POST"), methods)
                XCTAssertTrue(methods.contains("OPTIONS"), methods)
                let allowedHeaders = res.headers.first(name: .accessControlAllowHeaders) ?? ""
                XCTAssertTrue(allowedHeaders.lowercased().contains("content-type"), allowedHeaders)
            }
        }
    }

    /// Documents that CORS headers are origin-gated: a same-origin or server-to-server
    /// request gets none, which is why the bug never showed up in curl.
    func testRequestWithoutOriginGetsNoCORSHeaders() async throws {
        try await self.withConfiguredApp { app in
            try await app.test(.GET, "test-throws-abort") { res in
                XCTAssertEqual(res.status, .unprocessableEntity)
                XCTAssertNil(res.headers.first(name: .accessControlAllowOrigin))
            }
        }
    }
}
