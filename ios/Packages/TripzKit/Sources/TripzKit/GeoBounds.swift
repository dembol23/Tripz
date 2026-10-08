import Foundation

public struct GeoBounds: Equatable, Sendable {
    public let minLatitude: Double
    public let maxLatitude: Double
    public let minLongitude: Double
    public let maxLongitude: Double
    
    public init?(points: [TrackPoint]) {
        guard let first = points.first else { return nil }
        var minLat = first.latitude, maxLat = first.latitude
        var minLon = first.longitude, maxLon = first.longitude
        for point in points.dropFirst() {
            minLat = min(minLat, point.latitude)
            maxLat = max(maxLat, point.latitude)
            minLon = min(minLon, point.longitude)
            maxLon = max(maxLon, point.longitude)
        }
        minLatitude = minLat
        maxLatitude = maxLat
        minLongitude = minLon
        maxLongitude = maxLon
    }
    
    public var centerLatitude: Double { (minLatitude + maxLatitude) / 2 }
    public var centerLongitude: Double { (minLongitude + maxLongitude) / 2 }
    public var latitudeSpan: Double { maxLatitude - minLatitude }
    public var longitudeSpan: Double { maxLongitude - minLongitude }
    
    public var approximateDiagonalMeters: Double {
        let metersPerDegree = 111_194.9
        let height = latitudeSpan * metersPerDegree
        let width = longitudeSpan * metersPerDegree * cos(centerLatitude * .pi / 180)
        return hypot(width, height)
    }
}
