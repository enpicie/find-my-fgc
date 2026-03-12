import Vapor

struct TournamentService {
    static func fetchTournaments(
        location: ResolvedLocation,
        radius: String,
        gameIds: [Int]?,
        client: any Client,
        apiKey: String,
        logger: Logger
    ) async throws -> [TournamentOutput] {
        logger.info("StartGG request", metadata: [
            "lat": "\(location.lat)", "lng": "\(location.lng)",
            "radius": "\(radius)", "gameIds": "\(gameIds ?? [])"
        ])

        let videogameIds = gameIds.map { $0.map(String.init) } ?? []

        let variables = TournamentVariables(
            coordinates: "\(location.lat),\(location.lng)",
            radius: radius,
            videogameIds: videogameIds
        )

        let gqlPayload = GraphQLRequest(query: StartGGQueries.tournamentsByLocation, variables: variables)

        if let payloadData = try? JSONEncoder().encode(gqlPayload),
           let payloadString = String(data: payloadData, encoding: .utf8) {
            logger.debug("StartGG GQL payload", metadata: ["payload": "\(payloadString)"])
        }

        let response = try await client.post("https://api.start.gg/gql/alpha") { req in
            try req.content.encode(gqlPayload, as: .json)
            req.headers.add(name: "Authorization", value: "Bearer \(apiKey)")
        }

        let rawBody = response.body.map { String(buffer: $0) } ?? "(empty)"

        guard response.status == .ok else {
            logger.error("StartGG API error", metadata: ["status": "\(response.status)", "body": "\(rawBody)"])
            throw Abort(.badGateway, reason: "StartGG API returned status \(response.status)")
        }

        logger.debug("StartGG raw response", metadata: ["body": "\(rawBody)"])

        let startGGData: StartGGResponse
        do {
            startGGData = try response.content.decode(StartGGResponse.self)
        } catch {
            logger.error("StartGG decode failed", metadata: ["error": "\(error)", "body": "\(rawBody)"])
            throw error
        }

        let nodes = startGGData.data?.tournaments?.nodes ?? []
        logger.info("StartGG response", metadata: ["tournamentCount": "\(nodes.count)"])
        
        return nodes.map { node in
            let image = node.images?.first(where: { $0.type == "profile" })?.url ?? node.images?.first?.url ?? ""
            let locStr = [node.city, node.addrState].compactMap { $0 }.joined(separator: ", ")

            return TournamentOutput(
                id: "\(node.id)",
                name: node.name,
                location: locStr,
                venueAddress: node.venueAddress ?? "See Details",
                date: "\(node.startAt)",
                externalUrl: "https://start.gg\(node.url)",
                image: image,
                games: ""
            )
        }
    }
}
