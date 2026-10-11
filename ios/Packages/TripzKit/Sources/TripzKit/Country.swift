import Foundation

public struct CountryPolygon: Sendable {
    public let outer: [GeoPoint]
    public let holes: [[GeoPoint]]
    let bounds: GeoBounds
    
    public init?(outer: [GeoPoint], holes: [[GeoPoint]] = []) {
        guard outer.count >= 3 else { return nil }
        var minLat = outer[0].latitude, maxLat = minLat
        var minLon = outer[0].longitude, maxLon = minLon
        for point in outer.dropFirst() {
            minLat = min(minLat, point.latitude)
            maxLat = max(maxLat, point.latitude)
            minLon = min(minLon, point.longitude)
            maxLon = max(maxLon, point.longitude)
        }
        self.outer = outer
        self.holes = holes
        self.bounds = GeoBounds(minLatitude: minLat, maxLatitude: maxLat, minLongitude: minLon, maxLongitude: maxLon)
    }
    
    func contains(latitude: Double, longitude: Double) -> Bool {
        guard bounds.minLatitude <= latitude, latitude <= bounds.maxLatitude,
              bounds.minLongitude <= longitude, longitude <= bounds.maxLongitude else { return false }
        var crossings = Self.crossings(of: outer, latitude, longitude)
        for hole in holes {
            crossings += Self.crossings(of: hole, latitude, longitude)
        }
        return crossings % 2 == 1
    }

    func isNear(latitude: Double, longitude: Double, meters: Double) -> Bool {
        let latitudePadding = meters / Self.metersPerDegree
        let longitudePadding = latitudePadding / max(cos(latitude * .pi / 180), 0.01)
        return bounds.minLatitude - latitudePadding <= latitude
            && latitude <= bounds.maxLatitude + latitudePadding
            && bounds.minLongitude - longitudePadding <= longitude
            && longitude <= bounds.maxLongitude + longitudePadding
    }

    func distanceMeters(latitude: Double, longitude: Double) -> Double {
        let longitudeScale = cos(latitude * .pi / 180) * Self.metersPerDegree
        var best = Double.infinity
        for ring in [outer] + holes {
            var previous = ring[ring.count - 1]
            for current in ring {
                let distance = Self.distanceToSegment(
                    ax: (previous.longitude - longitude) * longitudeScale,
                    ay: (previous.latitude - latitude) * Self.metersPerDegree,
                    bx: (current.longitude - longitude) * longitudeScale,
                    by: (current.latitude - latitude) * Self.metersPerDegree
                )
                best = min(best, distance)
                previous = current
            }
        }
        return best
    }

    private static let metersPerDegree = 111_194.9

    private static func crossings(of ring: [GeoPoint], _ latitude: Double, _ longitude: Double) -> Int {
        var count = 0
        var previous = ring[ring.count - 1]
        for current in ring {
            if (current.latitude > latitude) != (previous.latitude > latitude) {
                let crossingLongitude = (previous.longitude - current.longitude)
                    * (latitude - current.latitude) / (previous.latitude - current.latitude)
                    + current.longitude
                if longitude < crossingLongitude { count += 1 }
            }
            previous = current
        }
        return count
    }

    private static func distanceToSegment(ax: Double, ay: Double, bx: Double, by: Double) -> Double {
        let dx = bx - ax
        let dy = by - ay
        let lengthSquared = dx * dx + dy * dy
        guard lengthSquared > 0 else { return hypot(ax, ay) }
        let t = max(0, min(1, -(ax * dx + ay * dy) / lengthSquared))
        return hypot(ax + t * dx, ay + t * dy)
    }
}

public struct Country: Identifiable, Sendable {
    public let code: String
    public let polygons: [CountryPolygon]
    public let focusBounds: GeoBounds
    public var id: String { code }
    
    public init?(code: String, polygons: [CountryPolygon]) {
        self.code = code
        self.polygons = polygons
        let largest = polygons.max {
            $0.bounds.latitudeSpan * $0.bounds.longitudeSpan < $1.bounds.latitudeSpan * $1.bounds.longitudeSpan
        }
        guard let largest else { return nil }
        self.focusBounds = largest.bounds
    }
}
