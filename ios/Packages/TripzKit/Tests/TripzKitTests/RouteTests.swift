import Testing
@testable import TripzKit

struct RouteTests {
    @Test func trackPointOptionalFieldsDefaultToNil() {
        let point = TrackPoint(latitude: 47.0, longtitude: 8.0)
        #expect(point.elevationMeters == nil)
        #expect(point.timestamp == nil)
    }
    
    @Test func routeKeepsPointOrder() {
        let first = TrackPoint(latitude: 1, longtitude: 1)
        let second = TrackPoint(latitude: 2, longtitude: 2)
        #expect(Route(points: [first, second]).points == [first, second])
    }
}
