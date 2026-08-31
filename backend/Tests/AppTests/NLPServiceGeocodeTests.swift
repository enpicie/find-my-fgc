import XCTest
import Vapor
@testable import App

/// Drives the real `NLPService.geocode` through a stubbed `Client`.
///
/// `NLPServiceTests` covers the pure classifier; this file covers what the classifier is
/// *for* — the country component actually reaching the Maps request, and the guard that
/// refuses Google's country-centroid fallback. Both are invisible failures if they
/// regress: the API keeps returning HTTP 200 with a confident-looking location.
///
/// `GeocodeCache.shared` is a process-wide singleton, so every test here uses a query
/// string no other test uses.
final class NLPServiceGeocodeTests: XCTestCase {

    // MARK: - Fixtures

    private static func mapsResult(
        status: String = "OK",
        address: String = "Somewhere",
        lat: Double = 1.0,
        lng: Double = 2.0,
        types: String = "[\"postal_code\"]",
        partialMatch: Bool = false
    ) -> String {
        """
        {
          "status": "\(status)",
          "results": [
            {
              "formatted_address": "\(address)",
              "geometry": { "location": { "lat": \(lat), "lng": \(lng) } },
              "types": \(types),
              "partial_match": \(partialMatch)
            }
          ]
        }
        """
    }

    /// The URL is built with percent encoding, so the colon in `country:US` may arrive
    /// escaped. Normalise before asserting rather than pinning one spelling.
    private func requestURL(_ client: StubClient) throws -> String {
        let url = try XCTUnwrap(client.requests.first).url.string
        return url.replacingOccurrences(of: "%3A", with: ":").replacingOccurrences(of: "%3a", with: ":")
    }

    private func geocode(_ query: String, client: StubClient) async throws -> ResolvedLocation {
        try await NLPService.geocode(query: query, client: client, apiKey: "test-maps-key", logger: testLogger)
    }

    // MARK: - The country component reaches the request

    func testUSZIPQueryIsConstrainedToTheUS() async throws {
        let body = Self.mapsResult(address: "Lake Oswego, OR 97035, USA", lat: 45.4, lng: -122.7)
        let client = StubClient { _ in jsonClientResponse(body) }

        let location = try await self.geocode("97035", client: client)

        let url = try self.requestURL(client)
        XCTAssertTrue(url.contains("components=country:US"), url)
        XCTAssertEqual(location.displayName, "Lake Oswego, OR 97035, USA")
        XCTAssertEqual(location.lat, 45.4)
        XCTAssertEqual(location.lng, -122.7)
    }

    func testCanadianPostalCodeQueryIsConstrainedToCanada() async throws {
        let body = Self.mapsResult(address: "Toronto, ON M5V 3L9, Canada")
        let client = StubClient { _ in jsonClientResponse(body) }

        _ = try await self.geocode("M5V 3L9", client: client)

        let url = try self.requestURL(client)
        XCTAssertTrue(url.contains("components=country:CA"), url)
    }

    /// The regression that matters most. Pinning free text to a country would silently
    /// move "london" from the UK to Ontario. The request must carry no components filter.
    func testFreeTextQueryIsSentUnconstrained() async throws {
        let body = Self.mapsResult(address: "London, UK", types: "[\"locality\",\"political\"]")
        let client = StubClient { _ in jsonClientResponse(body) }

        _ = try await self.geocode("london", client: client)

        let url = try self.requestURL(client)
        XCTAssertFalse(url.contains("components="), url)
        XCTAssertTrue(url.contains("address=london"), url)
    }

    // MARK: - Country-centroid fallback rejection

    /// With a country component applied, Google answers an unresolvable ZIP with the
    /// country itself rather than ZERO_RESULTS. Returning that would hand the user a
    /// confident 200 pointing at rural Colorado. It must fail instead.
    func testCountryCentroidFallbackIsRejected() async throws {
        let body = Self.mapsResult(
            address: "United States",
            lat: 37.09024,
            lng: -95.712891,
            types: "[\"country\",\"political\"]",
            partialMatch: true
        )
        let client = StubClient { _ in jsonClientResponse(body) }

        do {
            let location = try await self.geocode("55555", client: client)
            XCTFail("expected the country-centroid fallback to be rejected, got \(location)")
        } catch {
            guard let abort = error as? AbortError else {
                return XCTFail("expected an AbortError, got \(error)")
            }
            XCTAssertEqual(abort.status, .unprocessableEntity)
            XCTAssertTrue(abort.reason.contains("55555"), abort.reason)
            // The rejected centroid must not leak into the message as a real place.
            XCTAssertFalse(abort.reason.contains("United States"), abort.reason)
        }
    }

    /// A rejected result must not be cached: a later, working lookup of the same query
    /// has to reach Google again rather than replay the failure or a stale centroid.
    func testRejectedFallbackIsNotCached() async throws {
        let fallback = Self.mapsResult(address: "United States", types: "[\"country\"]", partialMatch: true)
        let failing = StubClient { _ in jsonClientResponse(fallback) }
        _ = try? await self.geocode("01828", client: failing)

        let real = Self.mapsResult(address: "Lawrence, MA 01828, USA", lat: 42.7, lng: -71.1)
        let succeeding = StubClient { _ in jsonClientResponse(real) }
        let location = try await self.geocode("01828", client: succeeding)

        XCTAssertEqual(succeeding.requests.count, 1, "the failed lookup should not have been cached")
        XCTAssertEqual(location.displayName, "Lawrence, MA 01828, USA")
    }

    /// The guard is scoped to `country != nil` on purpose. A free-text search for a
    /// country is a legitimate result and must still resolve.
    func testCountryTypedResultIsAcceptedForUnconstrainedQueries() async throws {
        let body = Self.mapsResult(address: "Japan", lat: 36.2, lng: 138.25, types: "[\"country\",\"political\"]")
        let client = StubClient { _ in jsonClientResponse(body) }

        let location = try await self.geocode("japan", client: client)

        XCTAssertEqual(location.displayName, "Japan")
        XCTAssertEqual(location.lat, 36.2)
    }

    // MARK: - Upstream failures

    func testZeroResultsIsSurfacedAsUnprocessableEntity() async throws {
        let client = StubClient { _ in jsonClientResponse("{\"status\":\"ZERO_RESULTS\",\"results\":[]}") }

        do {
            _ = try await self.geocode("nowhere at all zz", client: client)
            XCTFail("expected ZERO_RESULTS to throw")
        } catch {
            guard let abort = error as? AbortError else {
                return XCTFail("expected an AbortError, got \(error)")
            }
            XCTAssertEqual(abort.status, .unprocessableEntity)
            XCTAssertTrue(abort.reason.contains("ZERO_RESULTS"), abort.reason)
        }
    }

    /// A bad API key is an operator problem, not a user problem — the reason string has to
    /// say so rather than looking like an unknown place name.
    func testRequestDeniedExplainsTheAPIKey() async throws {
        let client = StubClient { _ in jsonClientResponse("{\"status\":\"REQUEST_DENIED\",\"results\":[]}") }

        do {
            _ = try await self.geocode("denied key probe", client: client)
            XCTFail("expected REQUEST_DENIED to throw")
        } catch {
            guard let abort = error as? AbortError else {
                return XCTFail("expected an AbortError, got \(error)")
            }
            XCTAssertEqual(abort.status, .unprocessableEntity)
            XCTAssertTrue(abort.reason.contains("GOOGLE_MAPS_API_KEY"), abort.reason)
        }
    }

    func testNonOKHTTPStatusIsSurfacedAsBadGateway() async throws {
        let client = StubClient { _ in jsonClientResponse("{}", status: .internalServerError) }

        do {
            _ = try await self.geocode("maps down probe", client: client)
            XCTFail("expected a non-200 Maps response to throw")
        } catch {
            guard let abort = error as? AbortError else {
                return XCTFail("expected an AbortError, got \(error)")
            }
            XCTAssertEqual(abort.status, .badGateway)
        }
    }

    // MARK: - Cache

    func testSuccessfulLookupIsCached() async throws {
        let body = Self.mapsResult(address: "Cached Place")
        let client = StubClient { _ in jsonClientResponse(body) }

        _ = try await self.geocode("cache probe query", client: client)
        let second = try await self.geocode("CACHE PROBE QUERY", client: client)

        XCTAssertEqual(client.requests.count, 1, "the second lookup should have been served from cache")
        XCTAssertEqual(second.displayName, "Cached Place")
    }
}
