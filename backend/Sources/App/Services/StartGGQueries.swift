import Foundation

enum StartGGQueries {
    static let tournamentsByLocation = """
    query TournamentsByLocation($coordinates: String!, $radius: String!, $videogameIds: [ID]) {
      tournaments(query: {
        filter: {
          location: {
            distanceFrom: $coordinates,
            distance: $radius
          },
          videogameIds: $videogameIds,
          hasOnlineEvents: false,
          upcoming: true
        }
      }) {
        nodes {
          id
          name
          city
          addrState
          venueAddress
          lat
          lng
          startAt
          hasOnlineEvents
          url
          images {
            type
            url
          }
          events {
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
