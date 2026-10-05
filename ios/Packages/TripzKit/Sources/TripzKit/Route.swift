import Foundation

public struct TrackPoint: Hashable, Sendable {
    public let latitude: Double
    public let longtitude: Double
    public let elevationMeters: Double?
    public let timestamp: Date?
    
    public init(latitude: Double, longtitude: Double, elevationMeters: Double? = nil, timestamp: Date? = nil) {
        self.latitude = latitude
        self.longtitude = longtitude
        self.elevationMeters = elevationMeters
        self.timestamp = timestamp
    }
}

public struct Route: Hashable, Sendable {
    public let points: [TrackPoint]
    
    public init(points: [TrackPoint]) {
        self.points = points
    }
}
