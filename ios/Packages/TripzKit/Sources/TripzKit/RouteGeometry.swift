import Foundation

public struct RouteGeometry: Sendable {
    public let points: [TrackPoint]
    public let cumulativeDistances: [Double]
    public var totalDistanceMeters: Double { cumulativeDistances.last ?? 0 }
    
    public init(route: Route) {
        self.points = route.points
        var distances: [Double] = []
        distances.reserveCapacity(points.count)
        var running = 0.0
        for (index, point) in points.enumerated() {
            if index > 0 {
                running += Geo.distanceMeters(from: points[index-1], to: point)
            }
            distances.append(running)
        }
        cumulativeDistances = distances
    }
    
    public func point(atDistance distance: Double) -> TrackPoint? {
        guard let first = points.first, let last = points.last else {return nil}
        if distance <= 0.0 { return first }
        if distance >= totalDistanceMeters { return last }
        
        var low = 0
        var high = cumulativeDistances.count - 1
        while low < high {
            let mid = (low + high) / 2
            if cumulativeDistances[mid] < distance { low = mid + 1 } else { high = mid }
        }
        
        let upper = low
        let lower = upper - 1
        let span = cumulativeDistances[upper] - cumulativeDistances[lower]
        guard span > 0 else { return points[upper] }
        
        let t = (distance - cumulativeDistances[lower]) / span
        let a = points[lower]
        let b = points[upper]
        func lerp(_ x: Double, _ y: Double) -> Double { x + (y - x) * t}
        
        let elevation: Double? = {
            guard let ea = a.elevationMeters, let eb = b.elevationMeters else { return nil }
            return lerp(ea, eb)
        }()
        
        return TrackPoint(latitude: lerp(a.latitude, b.latitude), longitude: lerp(a.longitude, b.longitude), elevationMeters: elevation)
    }
}

public struct ElevationSample: Hashable, Sendable {
    public let distanceMeters: Double
    public let elevationMeters: Double
}

extension RouteGeometry {
    public func elevationSamples(maximumCount: Int = 300) -> [ElevationSample] {
        let all = zip(points, cumulativeDistances).compactMap{point, distance in
            point.elevationMeters.map {
                ElevationSample(distanceMeters: distance, elevationMeters: $0)
            }
        }
        guard all.count >= 2 else { return [] }
        guard maximumCount >= 2, all.count > maximumCount else { return all }
        
        let step = Double(all.count - 1) / Double(maximumCount - 1)
        return (0..<maximumCount).map { all[Int((Double($0) * step).rounded())] }
    }
}
