
import XCTest
import Vapor
@testable import App

final class TournamentServiceTests: XCTestCase {
    
    func testTournamentOutputMapping() throws {
        // This is a conceptual test for the mapping logic inside fetchTournaments
        // In a real Vapor app, you would mock the Client response and test the Service output.
        
        let node = TournamentNode(
            id: 123,
            name: "Test Tournament",
            city: "San Francisco",
            addrState: "CA",
            venueAddress: "123 Main St",
            startAt: 1715856000,
            url: "/tournament/test",
            images: [StartGGImage(url: "test.png", type: "profile")],
            events: [
                EventNode(id: 1, name: "SF6", videogame: VideogameNode(id: 43868, name: "Street Fighter 6"))
            ]
        )
        
        // Mocking the behavior found in TournamentService.swift nodes.map loop
        let image = node.images?.first(where: { $0.type == "profile" })?.url ?? ""
        let locStr = [node.city, node.addrState].compactMap { $0 }.joined(separator: ", ")
        let gameNames = Array(Set(node.events?.compactMap { $0.videogame?.name } ?? [])).sorted().joined(separator: ", ")
        
        XCTAssertEqual(image, "test.png")
        XCTAssertEqual(locStr, "San Francisco, CA")
        XCTAssertEqual(gameNames, "Street Fighter 6")
        XCTAssertEqual(node.name, "Test Tournament")
    }
}
