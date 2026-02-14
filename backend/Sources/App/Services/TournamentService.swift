import Vapor

struct TournamentService {
    static func fetchTournaments(
        location: ResolvedLocation,
        radius: String,
        gameIds: [Int]?,
        client: Client,
        apiKey: String
    ) async throws -> [TournamentOutput] {
        let videogameIds: [String]? = (gameIds != nil && !gameIds!.isEmpty) 
            ? gameIds!.map { String($0) } 
            : nil
        
        let variables = TournamentVariables(
            coordinates: "\(location.lat),\(location.lng)",
            radius: radius,
            videogameIds: videogameIds
        )
        
        // Updated to use StartGGQueries instead of GQLQueries
        let gqlPayload = GraphQLRequest(query: StartGGQueries.tournamentsByLocation, variables: variables)
        
        let response = try await client.post("https://api.start.gg/gql/alpha") { req in
            try req.content.encode(gqlPayload, as: .json)
            req.headers.add(name: "Authorization", value: "Bearer \(apiKey)")
        }
        
        let startGGData = try response.content.decode(StartGGResponse.self)
        let nodes = startGGData.data?.tournaments?.nodes ?? []
        
        return nodes.map { node in
            let image = node.images?.first(where: { $0.type == "profile" })?.url ?? node.images?.first?.url ?? ""
            let locStr = [node.city, node.addrState].compactMap { $0 }.joined(separator: ", ")
            let gameNames = Array(Set(node.events?.compactMap { $0.videogame?.name } ?? [])).sorted().joined(separator: ", ")

            return TournamentOutput(
                id: "\(node.id)",
                name: node.name,
                location: locStr,
                venueAddress: node.venueAddress ?? "See Details",
                date: "\(node.startAt)",
                externalUrl: "https://start.gg\(node.url)",
                image: image,
                games: gameNames
            )
        }
    }
}
