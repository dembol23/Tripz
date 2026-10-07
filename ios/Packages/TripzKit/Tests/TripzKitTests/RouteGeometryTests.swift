import Testing
@testable import TripzKit

struct RouteGeometryTests {
    private let equatorRoute = Route(points: [
        TrackPoint(latitude: 0, longitude: 0, elevationMeters: 100),
        TrackPoint(latitude: 0, longitude: 1, elevationMeters: 200),
        TrackPoint(latitude: 0, longitude: 2, elevationMeters: 300),
    ])

    @Test func cumulativeDistancesStartAtZeroAndNeverDecrease() {
        let geometry = RouteGeometry(route: equatorRoute)
        #expect(geometry.cumulativeDistances.first == 0)
        #expect(geometry.cumulativeDistances == geometry.cumulativeDistances.sorted())
        #expect(abs(geometry.totalDistanceMeters - 222_389.9) < 2)
    }

    @Test func positionAtZeroAndBeyondTheEndsIsClamped() {
        let geometry = RouteGeometry(route: equatorRoute)
        #expect(geometry.point(atDistance: -5)?.longitude == 0)
        #expect(geometry.point(atDistance: 0)?.longitude == 0)
        #expect(geometry.point(atDistance: 10_000_000)?.longitude == 2)
    }

    @Test func positionBetweenPointsIsInterpolated() throws {
        let geometry = RouteGeometry(route: equatorRoute)
        let halfSegment = geometry.cumulativeDistances[1] * 1.5
        let point = try #require(geometry.point(atDistance: halfSegment))
        #expect(abs(point.longitude - 1.5) < 1e-6)
        #expect(abs((point.elevationMeters ?? 0) - 250) < 1e-6)
    }

    @Test func emptyAndSinglePointRoutes() {
        #expect(RouteGeometry(route: Route(points: [])).point(atDistance: 5) == nil)
        let single = RouteGeometry(route: Route(points: [TrackPoint(latitude: 1, longitude: 2)]))
        #expect(single.totalDistanceMeters == 0)
        #expect(single.point(atDistance: 50)?.latitude == 1)
    }

    @Test func duplicatePointsDoNotDivideByZero() {
        let p = TrackPoint(latitude: 0, longitude: 0)
        let geometry = RouteGeometry(route: Route(points: [
            p, p, TrackPoint(latitude: 0, longitude: 1),
        ]))
        #expect(geometry.point(atDistance: 1) != nil)
    }
    
    @Test func samplesSkipPointsWithoutElevationButKeepTheirDistance() {
        let geometry = RouteGeometry(route: Route(points: [
            TrackPoint(latitude: 0, longitude: 0, elevationMeters: 10),
            TrackPoint(latitude: 0, longitude: 1),                      // no elevation
            TrackPoint(latitude: 0, longitude: 2, elevationMeters: 30),
        ]))
        let samples = geometry.elevationSamples()
        #expect(samples.count == 2)
        #expect(samples.last?.distanceMeters == geometry.totalDistanceMeters)
    }

    @Test func tooFewElevationsProduceNoSamples() {
        let geometry = RouteGeometry(route: Route(points: [
            TrackPoint(latitude: 0, longitude: 0, elevationMeters: 10),
            TrackPoint(latitude: 0, longitude: 1),
        ]))
        #expect(geometry.elevationSamples().isEmpty)
    }

    @Test func longRoutesAreThinnedButKeepBothEnds() {
        let points = (0..<1000).map {
            TrackPoint(latitude: 0, longitude: Double($0) * 0.0001, elevationMeters: Double($0))
        }
        let all = RouteGeometry(route: Route(points: points)).elevationSamples(maximumCount: 1000)
        let thinned = RouteGeometry(route: Route(points: points)).elevationSamples(maximumCount: 300)
        #expect(thinned.count == 300)
        #expect(thinned.first == all.first)
        #expect(thinned.last == all.last)
    }
}
