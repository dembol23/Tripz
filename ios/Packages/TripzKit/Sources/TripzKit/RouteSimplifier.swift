import Foundation

public enum RouteSimplifier {
    public static func simplify(_ points: [TrackPoint], toleranceMeters: Double) -> [TrackPoint] {
        guard points.count > 2, toleranceMeters > 0 else { return points }
        
        let meanLatitude = points.reduce(0) { $0 + $1.latitude } / Double(points.count)
        let metersPerDegreeLatitude = 111_194.9
        let metersPerDegreeLongitude = metersPerDegreeLatitude * cos(meanLatitude * .pi / 180)
        let flat = points.map {
            Point(x: $0.longitude * metersPerDegreeLongitude, y: $0.latitude * metersPerDegreeLatitude)
        }
        
        var keep = [Bool](repeating: false, count: points.count)
        keep[0] = true
        keep[points.count - 1] = true
        
        var pending = [(first: 0, last: points.count - 1)]
        while let (first, last) = pending.popLast() {
            guard last - first > 1 else { continue }
            var farthestIndex = first
            var farthestDeviation = 0.0
            for index in (first + 1)..<last {
                let d = deviation(of: flat[index], fromSegment: flat[first], to: flat[last])
                if d > farthestDeviation {
                    farthestDeviation = d
                    farthestIndex = index
                }
            }
            
            if farthestDeviation > toleranceMeters {
                keep[farthestIndex] = true
                pending.append((first, farthestIndex))
                pending.append((farthestIndex, last))
            }
        }
        
        return points.indices.filter { keep[$0] }.map { points[$0] }
    }
    
    private struct Point {
        var x: Double
        var y: Double
    }
    
    private static func deviation(of p: Point, fromSegment a:Point, to b: Point) -> Double {
        let dx = b.x - a.x
        let dy = b.y - a.y
        let lengthSquared = dx * dx + dy * dy
        guard lengthSquared > 0 else { return hypot(p.x - a.x, p.y - a.y) }
        let t = max(0, min(1, ((p.x - a.x) * dx + (p.y - a.y) * dy) / lengthSquared))
        return hypot(p.x - (a.x + t * dx), p.y - (a.y + t * dy))
    }
}
