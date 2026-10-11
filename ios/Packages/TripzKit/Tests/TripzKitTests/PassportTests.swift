import Foundation
import Testing
@testable import TripzKit

struct PassportTests {
    private func square(_ minLat: Double, _ maxLat: Double, _ minLon: Double, _ maxLon: Double) -> [GeoPoint] {
        [
            GeoPoint(latitude: minLat, longitude: minLon), GeoPoint(latitude: minLat, longitude: maxLon),
            GeoPoint(latitude: maxLat, longitude: maxLon), GeoPoint(latitude: maxLat, longitude: minLon),
        ]
    }

    /// "AA" covers 0...10, "BB" covers 20...30.
    private func makeIndex() throws -> CountryIndex {
        let aaShape = try #require(CountryPolygon(outer: square(0, 10, 0, 10)))
        let bbShape = try #require(CountryPolygon(outer: square(0, 10, 20, 30)))
        let aa = try #require(Country(code: "AA", polygons: [aaShape]))
        let bb = try #require(Country(code: "BB", polygons: [bbShape]))
        return CountryIndex(countries: [aa, bb])
    }

    private func trip(_ seconds: TimeInterval, _ points: [(Double, Double)]) -> Passport.Trip {
        Passport.Trip(
            start: Date(timeIntervalSince1970: seconds),
            points: points.map { TrackPoint(latitude: $0.0, longitude: $0.1) }
        )
    }

    @Test func tripsInTheSameCountryAreCountedAndTheLatestDateWins() throws {
        let index = try makeIndex()
        let visits = Passport.visits(
            for: [trip(100, [(2, 2)]), trip(200, [(3, 3), (4, 4)])],
            in: index
        )
        #expect(visits == [CountryVisit(code: "AA", activityCount: 2, lastVisit: Date(timeIntervalSince1970: 200))])
    }

    @Test func oneTripCountsOncePerCountryEvenWhenItCrossesTwice() throws {
        let index = try makeIndex()
        let visits = Passport.visits(
            for: [trip(100, [(2, 2), (2, 25), (2, 2), (2, 25)])],
            in: index
        )
        #expect(visits.map(\.code).sorted() == ["AA", "BB"])
        #expect(visits.allSatisfy { $0.activityCount == 1 })
    }

    @Test func mostRecentCountryComesFirst() throws {
        let index = try makeIndex()
        let visits = Passport.visits(for: [trip(100, [(2, 2)]), trip(200, [(2, 25)])], in: index)
        #expect(visits.map(\.code) == ["BB", "AA"])
    }

    @Test func tripsOutsideEveryCountryProduceNothing() throws {
        let index = try makeIndex()
        #expect(Passport.visits(for: [trip(100, [(50, 50)]), trip(200, [])], in: index).isEmpty)
    }
}
