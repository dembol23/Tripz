import Testing
@testable import TripzKit

struct ActivityTypeTests {
    @Test func rawValuesAreStable() {
        #expect(ActivityType.hiking.rawValue == "hiking")
    }
}
