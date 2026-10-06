import Foundation
import Testing
import TripzKit
@testable import TripzStorage

struct ActivityMappingTests {
    private let start = Date(timeIntervalSince1970: 1_000_000)
    
    private func makeActivity(source: ActivitySource = .manual, route: Route? = nil) -> Activity {
        Activity(title: "Pilatus", start: start, durationSeconds: 3600, distanceMeters: 5000, elevationGainMeters: 700, notes: "Clear sky", source: source, route: route)
    }
    
    @Test func manualActivitySurvivesRecordRoundTrip() throws {
        let original = makeActivity()
        let restored = try ActivityRecord(original).makeActivity(route: nil)
        #expect(restored == original)
    }
    
    @Test func healthActivityKeepsItsWorkoutId() throws {
        let workoutId = UUID()
        let original = makeActivity(source: .appleHealth(workoutId: workoutId))
        let record = ActivityRecord(original)
        #expect(record.sourceKind == "appleHealth")
        #expect(record.healthWorkoutId == workoutId.uuidString)
        #expect(try record.makeActivity(route: nil) == original)
    }
    
    @Test func manualActivityStoresNoWorkoutId() throws {
        let record = ActivityRecord(makeActivity())
        #expect(record.sourceKind == "manual")
        #expect(record.healthWorkoutId == nil)
    }
    
    @Test func routePointsKeepOrderAndOptionalFields() throws {
        let first = TrackPoint(latitude: 1, longitude: 2, elevationMeters: 300, timestamp: start)
        let second = TrackPoint(latitude: 3, longitude: 4)
        let records = RoutePointRecord.records(for: Route(points: [first, second]), activityId: UUID())
        #expect(records.map(\.position) == [0, 1])
        #expect(records.map(\.trackPoint) == [first, second])
    }
    
    @Test func emptyRouteProducesNoRecords() {
        #expect(RoutePointRecord.records(for: Route(points: []), activityId: UUID()).isEmpty)
    }
    
    @Test func invalidRowsAreRejected() {
        let valid = ActivityRecord(makeActivity())
        
        var badId = valid
        badId.id = "not-a-uuid"
        
        var badType = valid
        badType.type = "skydiving"
        
        var badSource = valid
        badSource.sourceKind = "strava"
        
        var healthWithoutWorkout = valid
        healthWithoutWorkout.sourceKind = "appleHealth"
        healthWithoutWorkout.healthWorkoutId = nil
        
        for record in [badId, badType, badSource, healthWithoutWorkout] {
            #expect(throws: StorageError.self) {
                _ = try record.makeActivity(route: nil)
            }
        }
    }
}
