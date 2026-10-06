import Foundation

public struct TrackPoint: Hashable, Sendable {
    public let latitude: Double
    public let longitude: Double
    public let elevationMeters: Double?
    public let timestamp: Date?
    
    public init(latitude: Double, longitude: Double, elevationMeters: Double? = nil, timestamp: Date? = nil) {
        self.latitude = latitude
        self.longitude = longitude
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
