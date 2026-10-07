import Testing
@testable import TripzKit

struct GeoTests {
    private func point(_ lat: Double, _ lon: Double) -> TrackPoint {
        TrackPoint(latitude: lat, longitude: lon)
    }

    @Test func identicalPointsHaveZeroDistance() {
        #expect(Geo.distanceMeters(from: point(47, 8), to: point(47, 8)) == 0)
    }

    @Test func oneDegreeOfLatitudeIsAbout111Km() {
        let d = Geo.distanceMeters(from: point(0, 0), to: point(1, 0))
        #expect(abs(d - 111_194.9) < 1)
    }

    @Test func oneDegreeOfLongitudeAtEquatorMatches() {
        let d = Geo.distanceMeters(from: point(0, 0), to: point(0, 1))
        #expect(abs(d - 111_194.9) < 1)
    }

    @Test func longitudeDegreesShrinkTowardThePoles() {
        let equator = Geo.distanceMeters(from: point(0, 0), to: point(0, 1))
        let alps = Geo.distanceMeters(from: point(47, 0), to: point(47, 1))
        #expect(alps < equator * 0.7)
    }

    @Test func distanceIsSymmetric() {
        let a = point(46.95, 8.27)
        let b = point(47.38, 8.54)
        #expect(Geo.distanceMeters(from: a, to: b) == Geo.distanceMeters(from: b, to: a))
    }

    @Test func halfWayAroundTheEarth() {
        let d = Geo.distanceMeters(from: point(0, 0), to: point(0, 180))
        #expect(abs(d - 20_015_086.8) < 1)
    }
}
