import TripzKit
import Foundation

public protocol WorkoutProvider: Sendable {
    func requestAccess() async throws

    func hikingWorkouts() async throws -> [HealthWorkout]
    
    func route(forWorkout id: UUID) async throws -> [TrackPoint]
}
