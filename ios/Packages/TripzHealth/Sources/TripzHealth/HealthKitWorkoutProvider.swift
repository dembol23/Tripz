import Foundation
import HealthKit

public enum HealthAccessError: Error, LocalizedError {
    case unavailable

    public var errorDescription: String? {
        "Health data isn't available on this device."
    }
}

public struct HealthKitWorkoutProvider: WorkoutProvider {
    public init() {}

    public func requestAccess() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthAccessError.unavailable
        }
        let store = HKHealthStore()
        try await store.requestAuthorization(
            toShare: [],
            read: [HKObjectType.workoutType(), HKQuantityType(.distanceWalkingRunning)]
        )
    }

    public func hikingWorkouts() async throws -> [HealthWorkout] {
        let store = HKHealthStore()
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.workout(HKQuery.predicateForWorkouts(with: .hiking))],
            sortDescriptors: [SortDescriptor(\.startDate, order: .reverse)]
        )
        return try await descriptor.result(for: store).map(Self.makeWorkout)
    }

    private static func makeWorkout(_ workout: HKWorkout) -> HealthWorkout {
        let distance = workout
            .statistics(for: HKQuantityType(.distanceWalkingRunning))?
            .sumQuantity()?
            .doubleValue(for: .meter())

        let elevationGain = (workout.metadata?[HKMetadataKeyElevationAscended] as? HKQuantity)?
            .doubleValue(for: .meter())

        return HealthWorkout(
            id: workout.uuid,
            start: workout.startDate,
            durationSeconds: workout.duration,
            distanceMeters: distance,
            elevationGainMeters: elevationGain
        )
    }
}
