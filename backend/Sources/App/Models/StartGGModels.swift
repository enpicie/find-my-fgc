import Vapor

struct GraphQLRequest: Content {
    let query: String
    let variables: TournamentVariables
}

struct TournamentVariables: Content {
    let coordinates: String
    let radius: String
    let videogameIds: [String]?
}

struct StartGGResponse: Content {
    let data: StartGGData?
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
