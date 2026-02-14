import Vapor

struct TournamentRequest: Content {
    let query: String
    let radius: String
    let gameIds: [Int]?
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

struct UnifiedResponse: Content {
    let tournaments: [TournamentOutput]
    let center: LocationCoord
    let displayName: String
}