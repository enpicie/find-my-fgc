import Vapor

struct LocationCoord: Content {
    let lat: Double
    let lng: Double
}

struct ResolvedLocation: Content {
    let lat: Double
    let lng: Double
    let displayName: String
}