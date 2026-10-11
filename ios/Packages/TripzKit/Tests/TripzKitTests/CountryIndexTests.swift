import Foundation
import Testing
@testable import TripzKit

struct CountryIndexTests {
    private func square(_ minLat: Double, _ maxLat: Double, _ minLon: Double, _ maxLon: Double) -> [GeoPoint] {
        [
            GeoPoint(latitude: minLat, longitude: minLon),
            GeoPoint(latitude: minLat, longitude: maxLon),
            GeoPoint(latitude: maxLat, longitude: maxLon),
            GeoPoint(latitude: maxLat, longitude: minLon),
        ]
    }

    /// "AA" is a 10 degree square with a 2 degree hole. "BB" fills the hole,
    /// like Lesotho inside South Africa.
    private func makeIndex() throws -> CountryIndex {
        let aaShape = try #require(CountryPolygon(outer: square(0, 10, 0, 10), holes: [square(4, 6, 4, 6)]))
        let bbShape = try #require(CountryPolygon(outer: square(4, 6, 4, 6)))
        let aa = try #require(Country(code: "AA", polygons: [aaShape]))
        let bb = try #require(Country(code: "BB", polygons: [bbShape]))
        return CountryIndex(countries: [aa, bb])
    }

    @Test func aPointInsideACountryIsFound() throws {
        let index = try makeIndex()
        #expect(index.countryCode(latitude: 2, longitude: 2) == "AA")
    }

    @Test func aPointInAHoleBelongsToTheEnclave() throws {
        let index = try makeIndex()
        #expect(index.countryCode(latitude: 5, longitude: 5) == "BB")
    }

    @Test func aPointInOpenSeaIsInNoCountry() throws {
        let index = try makeIndex()
        #expect(index.countryCode(latitude: 20, longitude: 20) == nil)
    }

    @Test func aPointJustOffshoreSnapsToTheNearestCountry() throws {
        let index = try makeIndex()
        // 0.045 degrees east of the border at latitude 5 is about 5 km.
        #expect(index.countryCode(latitude: 5, longitude: 10.045) == "AA")
    }

    @Test func aPointFarOffshoreIsInNoCountry() throws {
        let index = try makeIndex()
        // 0.5 degrees is about 55 km, beyond the tolerance.
        #expect(index.countryCode(latitude: 5, longitude: 10.5) == nil)
    }

    @Test func aRouteReportsEveryCountryItTouches() throws {
        let index = try makeIndex()
        let route = [
            TrackPoint(latitude: 2, longitude: 2),
            TrackPoint(latitude: 5, longitude: 5),
            TrackPoint(latitude: 3, longitude: 3),
            TrackPoint(latitude: 30, longitude: 30),
        ]
        #expect(index.countryCodes(visitedBy: route) == ["AA", "BB"])
    }

    @Test func malformedDataIsRejected() {
        let wrongVersion = Data(#"{"version":2,"scale":1000,"countries":[]}"#.utf8)
        #expect(throws: CountryIndex.LoadError.unsupportedVersion(2)) {
            _ = try CountryIndex(jsonData: wrongVersion)
        }
        let oddRing = Data(#"{"version":1,"scale":1,"countries":[{"code":"AA","polygons":[[[0,0,1]]]}]}"#.utf8)
        #expect(throws: CountryIndex.LoadError.malformedRing) {
            _ = try CountryIndex(jsonData: oddRing)
        }
    }
}
