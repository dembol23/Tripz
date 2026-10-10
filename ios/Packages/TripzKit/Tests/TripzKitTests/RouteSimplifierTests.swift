import Testing
@testable import TripzKit

struct RouteSimplifierTests {
    private func eastLine(count: Int = 11) -> [TrackPoint] {
        (0..<count).map { TrackPoint(latitude: 0, longitude: Double($0) * 0.001) }  // ~111 m apart
    }

    @Test func straightLineCollapsesToItsEndpoints() {
        let points = eastLine()
        #expect(RouteSimplifier.simplify(points, toleranceMeters: 1) == [points[0], points[10]])
    }

    @Test func aCornerIsKept() {
        let east = (0...5).map { TrackPoint(latitude: 0, longitude: Double($0) * 0.001) }
        let north = (1...5).map { TrackPoint(latitude: Double($0) * 0.001, longitude: 0.005) }
        let points = east + north
        #expect(RouteSimplifier.simplify(points, toleranceMeters: 5) == [points[0], points[5], points[10]])
    }

    @Test func smallWobbleIsDroppedAndLargeOneKept() {
        var points = eastLine()
        points[5] = TrackPoint(latitude: 0.00001, longitude: 0.005)   // ~1.1 m off the line
        #expect(RouteSimplifier.simplify(points, toleranceMeters: 5).count == 2)
        #expect(RouteSimplifier.simplify(points, toleranceMeters: 0.5).contains(points[5]))

        points[5] = TrackPoint(latitude: 0.0001, longitude: 0.005)    // ~11 m off the line
        #expect(RouteSimplifier.simplify(points, toleranceMeters: 5).contains(points[5]))
    }

    @Test func keepsOriginalPointsInOriginalOrder() {
        let points = (0..<50).map {
            TrackPoint(latitude: Double($0 % 7) * 0.0003, longitude: Double($0) * 0.0005)
        }
        let simplified = RouteSimplifier.simplify(points, toleranceMeters: 10)
        #expect(simplified.first == points.first)
        #expect(simplified.last == points.last)
        #expect(simplified == points.filter { simplified.contains($0) })
    }

    @Test func aClosedLoopKeepsItsFarthestPoint() {
        let a = TrackPoint(latitude: 0, longitude: 0)
        let b = TrackPoint(latitude: 0.001, longitude: 0.001)
        #expect(RouteSimplifier.simplify([a, b, a], toleranceMeters: 1) == [a, b, a])
    }

    @Test func zeroToleranceAndShortRoutesAreReturnedUnchanged() {
        let points = eastLine(count: 5)
        #expect(RouteSimplifier.simplify(points, toleranceMeters: 0) == points)
        #expect(RouteSimplifier.simplify(Array(points.prefix(2)), toleranceMeters: 100) == Array(points.prefix(2)))
    }
}
