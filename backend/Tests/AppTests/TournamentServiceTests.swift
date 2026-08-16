import XCTest
import Vapor
@testable import App

/// Drives the real `TournamentService.fetchTournaments` through a stubbed `Client`.
///
/// The previous version of this file re-implemented the `nodes.map` body inline and
/// asserted against its own copy, so it passed regardless of what the service actually
/// did. It reported "Street Fighter 6" for a field the service has never populated —
/// see `testGamesIsAlwaysEmptyEvenThoughEventsAreRequested`.
final class TournamentServiceTests: XCTestCase {

    private let location = ResolvedLocation(lat: 37.7749, lng: -122.4194, displayName: "San Francisco, CA, USA")

    private static let fullNode = """
    {
      "id": 123,
      "name": "Test Tournament",
      "city": "San Francisco",
      "addrState": "CA",
      "venueAddress": "123 Main St",
      "lat": 37.7749,
      "lng": -122.4194,
      "startAt": 1715856000,
      "url": "/tournament/test",
      "images": [
        { "url": "banner.png", "type": "banner" },
        { "url": "profile.png", "type": "profile" }
      ],
      "events": [
        { "id": 1, "name": "SF6 Singles", "videogame": { "id": 43868, "name": "Street Fighter 6" } }
      ]
    }
    """

    private static func payload(_ nodes: String...) -> String {
        "{\"data\":{\"tournaments\":{\"nodes\":[\(nodes.joined(separator: ","))]}}}"
    }

    private func fetch(
        body: String,
        status: HTTPStatus = .ok,
        radius: String = "50mi",
        gameIds: [Int]? = nil,
        apiKey: String = "test-key",
        client: StubClient? = nil
    ) async throws -> [TournamentOutput] {
        let client = client ?? StubClient { _ in jsonClientResponse(body, status: status) }
        return try await TournamentService.fetchTournaments(
            location: self.location,
            radius: radius,
            gameIds: gameIds,
            client: client,
            apiKey: apiKey,
            logger: testLogger
        )
    }

    // MARK: - Output mapping

    func testMapsNodeOntoTournamentOutput() async throws {
        let outputs = try await self.fetch(body: Self.payload(Self.fullNode))

        XCTAssertEqual(outputs.count, 1)
        let output = try XCTUnwrap(outputs.first)
        XCTAssertEqual(output.id, "123")
        XCTAssertEqual(output.name, "Test Tournament")
        XCTAssertEqual(output.location, "San Francisco, CA")
        XCTAssertEqual(output.venueAddress, "123 Main St")
        XCTAssertEqual(output.lat, 37.7749)
        XCTAssertEqual(output.lng, -122.4194)
        XCTAssertEqual(output.date, "1715856000")
        XCTAssertEqual(output.externalUrl, "https://start.gg/tournament/test")
    }

    /// The profile image must win over any other image, regardless of array order.
    func testPrefersProfileImageOverOtherImages() async throws {
        let outputs = try await self.fetch(body: Self.payload(Self.fullNode))
        XCTAssertEqual(try XCTUnwrap(outputs.first).image, "profile.png")
    }

    func testFallsBackToFirstImageWhenNoProfileImageExists() async throws {
        let node = """
        {
          "id": 1, "name": "No Profile", "startAt": 1, "url": "/t/a",
          "images": [{ "url": "banner.png", "type": "banner" }]
        }
        """
        let outputs = try await self.fetch(body: Self.payload(node))
        XCTAssertEqual(try XCTUnwrap(outputs.first).image, "banner.png")
    }

    /// Optional fields absent from the start.gg payload must degrade to the documented
    /// placeholders rather than crashing or emitting "nil" into the response.
    func testMissingOptionalFieldsDegradeToPlaceholders() async throws {
        let node = """
        { "id": 7, "name": "Bare Node", "startAt": 1715856000, "url": "/t/bare" }
        """
        let outputs = try await self.fetch(body: Self.payload(node))
        let output = try XCTUnwrap(outputs.first)
        XCTAssertEqual(output.location, "")
        XCTAssertEqual(output.venueAddress, "See Details")
        XCTAssertEqual(output.image, "")
        XCTAssertNil(output.lat)
        XCTAssertNil(output.lng)
    }

    /// A node with a city but no state must not emit a dangling separator.
    func testLocationOmitsSeparatorWhenStateIsMissing() async throws {
        let node = """
        { "id": 8, "name": "City Only", "city": "Toronto", "startAt": 1, "url": "/t/c" }
        """
        let outputs = try await self.fetch(body: Self.payload(node))
        XCTAssertEqual(try XCTUnwrap(outputs.first).location, "Toronto")
    }

    /// KNOWN DEFECT, pinned on purpose.
    ///
    /// `StartGGQueries.tournamentsByLocation` asks start.gg for every event's videogame
    /// name, `TournamentNode` decodes them, and the frontend has a `games` field to show —
    /// but `fetchTournaments` hardcodes `games: ""`, so the data is fetched and thrown
    /// away. The previous test asserted "Street Fighter 6" here against its own inline
    /// copy of the mapping and therefore never saw this. This assertion documents the
    /// current, real behaviour; when the mapper is fixed, this test should be updated to
    /// the real expectation and will fail loudly until it is.
    func testGamesIsAlwaysEmptyEvenThoughEventsAreRequested() async throws {
        let outputs = try await self.fetch(body: Self.payload(Self.fullNode))
        XCTAssertEqual(try XCTUnwrap(outputs.first).games, "")
    }

    // MARK: - Request contract

    func testRequestCarriesCoordinatesRadiusGamesAndAuthorization() async throws {
        let client = StubClient { _ in jsonClientResponse(Self.payload()) }
        _ = try await self.fetch(body: "", radius: "25mi", gameIds: [1386, 43868], apiKey: "secret-key", client: client)

        let request = try XCTUnwrap(client.requests.first)
        XCTAssertEqual(request.method, .POST)
        XCTAssertTrue(request.url.string.contains("api.start.gg/gql/alpha"), request.url.string)
        XCTAssertEqual(request.headers.first(name: "Authorization"), "Bearer secret-key")

        let sent = String(buffer: try XCTUnwrap(request.body))
        XCTAssertTrue(sent.contains("37.7749,-122.4194"), sent)
        XCTAssertTrue(sent.contains("25mi"), sent)
        XCTAssertTrue(sent.contains("1386"), sent)
        XCTAssertTrue(sent.contains("43868"), sent)
    }

    /// A nil game filter must send an empty list, not null — start.gg rejects null here.
    func testNilGameIdsSendsEmptyList() async throws {
        let client = StubClient { _ in jsonClientResponse(Self.payload()) }
        _ = try await self.fetch(body: "", gameIds: nil, client: client)

        let sent = String(buffer: try XCTUnwrap(try XCTUnwrap(client.requests.first).body))
        XCTAssertTrue(sent.contains("\"videogameIds\":[]"), sent)
    }

    // MARK: - Failure handling

    func testEmptyNodeListYieldsNoTournaments() async throws {
        let outputs = try await self.fetch(body: Self.payload())
        XCTAssertTrue(outputs.isEmpty)
    }

    /// start.gg answers a GraphQL error with `{"data": null, "errors": [...]}`.
    /// That must be an empty result, not a crash.
    func testNullDataYieldsNoTournaments() async throws {
        let outputs = try await self.fetch(body: "{\"data\":null}")
        XCTAssertTrue(outputs.isEmpty)
    }

    func testNonOKStatusIsSurfacedAsBadGateway() async throws {
        do {
            _ = try await self.fetch(body: "{}", status: .internalServerError)
            XCTFail("expected fetchTournaments to throw on a non-200 start.gg response")
        } catch {
            guard let abort = error as? AbortError else {
                return XCTFail("expected an AbortError, got \(error)")
            }
            XCTAssertEqual(abort.status, .badGateway)
        }
    }

    func testUndecodableBodyIsSurfacedAsAnError() async throws {
        do {
            _ = try await self.fetch(body: Self.payload("{\"id\":\"not-an-int\",\"name\":\"x\",\"startAt\":1,\"url\":\"/t\"}"))
            XCTFail("expected fetchTournaments to throw on an undecodable body")
        } catch {
            XCTAssertTrue(error is DecodingError, "expected a DecodingError, got \(error)")
        }
    }
}
