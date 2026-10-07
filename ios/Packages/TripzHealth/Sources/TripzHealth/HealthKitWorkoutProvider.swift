import Foundation
import HealthKit
import CoreLocation
import TripzKit

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
            read: [
                HKObjectType.workoutType(),
                HKQuantityType(.distanceWalkingRunning),
                HKSeriesType.workoutRoute()
            ]
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
    
    public func route(forWorkout id: UUID) async throws -> [TrackPoint] {
        let store = HKHealthStore()
        
        let workoutQuery = HKSampleQueryDescriptor(
            predicates: [.workout(HKQuery.predicateForObject(with: id))],
            sortDescriptors: [],
            limit: 1
        )
        guard let workout = try await workoutQuery.result(for: store).first else { return [] }
        
        let routeQuery = HKSampleQueryDescriptor(
            predicates: [.workoutRoute(HKQuery.predicateForObjects(from: workout))],
            sortDescriptors: [SortDescriptor(\.startDate)]
        )
        
        var points: [TrackPoint] = []
        for route in try await routeQuery.result(for: store) {
            for try await location in HKWorkoutRouteQueryDescriptor(route).results(for: store) {
                guard location.horizontalAccuracy >= 0 else { continue }
                points.append(Self.makePoint(location))
            }
        }
        return points
    }
    
    private static func makePoint(_ location: CLLocation) -> TrackPoint {
        TrackPoint(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            elevationMeters: location.verticalAccuracy >= 0 ? location.altitude : nil,
            timestamp: location.timestamp
        )
    }
}
