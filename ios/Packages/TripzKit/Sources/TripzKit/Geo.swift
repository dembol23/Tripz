import Foundation

public enum Geo {
    public static let earthRadiusMeters = 6_371_000.0
    
    public static func distanceMeters(from a: TrackPoint, to b: TrackPoint) -> Double {
        let lat1 = a.latitude * .pi / 180
        let lat2 = b.latitude * .pi / 180
        let deltaLat = lat2 - lat1
        let deltaLon = (b.longitude - a.longitude) * .pi / 180
        
        let h = sin(deltaLat / 2) * sin(deltaLat / 2) + cos(lat1) * cos(lat2) * sin(deltaLon / 2) * sin(deltaLon / 2)
        return 2 * earthRadiusMeters * atan2(h.squareRoot(), (1 - h).squareRoot())
    }
}
