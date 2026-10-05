import Foundation
import Testing
@testable import TripzKit

struct ActivitySourceTests {
    @Test func sameWorkoutIdIsEqual() {
        let id = UUID()
        #expect(ActivitySource.appleHealth(workoutId: id) == .appleHealth(workoutId: id))
    }
    
    @Test func differentWorkoutIdsAreNotEqual() {
        #expect(ActivitySource.appleHealth(workoutId: UUID()) != .appleHealth(workoutId: UUID()))
    }
    
    @Test func manualDiffersFromHealth() {
        #expect(ActivitySource.manual != .appleHealth(workoutId: UUID()))
    }
}
