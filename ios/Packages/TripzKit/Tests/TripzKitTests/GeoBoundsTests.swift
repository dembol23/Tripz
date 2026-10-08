import Testing
@testable import TripzKit

struct GeoBoundsTests {
    @Test func noPointsMeansNoBounds() {
        #expect(GeoBounds(points: []) == nil)
    }

    @Test func boundsCoverEveryPoint() throws {
        let bounds = try #require(GeoBounds(points: [
            TrackPoint(latitude: 47.0, longitude: 8.0),
            TrackPoint(latitude: 47.2, longitude: 8.5),
            TrackPoint(latitude: 46.9, longitude: 8.1),
        ]))
        #expect(bounds.minLatitude == 46.9)
        #expect(bounds.maxLatitude == 47.2)
        #expect(bounds.minLongitude == 8.0)
        #expect(bounds.maxLongitude == 8.5)
        #expect(abs(bounds.latitudeSpan - 0.3) < 1e-9)
        #expect(abs(bounds.centerLatitude - 47.05) < 1e-9)
    }

    @Test func aSinglePointHasNoExtent() throws {
        let bounds = try #require(GeoBounds(points: [TrackPoint(latitude: 47, longitude: 8)]))
        #expect(bounds.approximateDiagonalMeters == 0)
    }

    @Test func oneDegreeOfLatitudeIsAbout111Km() throws {
        let bounds = try #require(GeoBounds(points: [
            TrackPoint(latitude: 0, longitude: 0), TrackPoint(latitude: 1, longitude: 0),
        ]))
        #expect(abs(bounds.approximateDiagonalMeters - 111_194.9) < 1)
    }

    @Test func degreesOfLongitudeShrinkTowardThePoles() throws {
        let bounds = try #require(GeoBounds(points: [
            TrackPoint(latitude: 60, longitude: 0), TrackPoint(latitude: 60, longitude: 1),
        ]))
        #expect(abs(bounds.approximateDiagonalMeters - 55_597.5) < 1)   // cos 60° = 0.5
    }
}
