import Foundation

enum GQLQueries {
    static let tournamentsByLocation = """
    query TournamentsByLocation($coordinates: String!, $radius: String!, $videogameIds: [ID]) {
      tournaments(query: {
        filter: {
          location: {
            distanceFrom: $coordinates,
            distance: $radius
          },
          videogameIds: $videogameIds,
          hasOfflineEvents: true,
          upcoming: true
        }
      }) {
        nodes {
          id
          name
          city
          addrState
          venueAddress
          startAt
          url
          images {
            type
            url
          }
          events(filter: { videogameId: $videogameIds }) {
            id
            name
            videogame {
              id
              name
            }
          }
        }
      }
    }
    """
}