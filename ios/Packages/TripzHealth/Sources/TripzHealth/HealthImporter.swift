import Foundation
import TripzKit
import TripzStorage

public struct ImportSummary: Equatable, Sendable {
    public var imported: Int
    public var routesAdded: Int
    public var alreadyImported: Int
    public var skippedWithoutDistance: Int

    public var found: Int { imported + routesAdded + alreadyImported + skippedWithoutDistance }

    public init(
        imported: Int = 0,
        routesAdded: Int = 0,
        alreadyImported: Int = 0,
        skippedWithoutDistance: Int = 0
    ) {
        self.imported = imported
        self.routesAdded = routesAdded
        self.alreadyImported = alreadyImported
        self.skippedWithoutDistance = skippedWithoutDistance
    }
}

public struct HealthImporter: Sendable {
    private let provider: any WorkoutProvider
    private let repository: ActivityRepository

    public init(provider: any WorkoutProvider, repository: ActivityRepository) {
        self.provider = provider
        self.repository = repository
    }

    public func importNewWorkouts() async throws -> ImportSummary {
        try await provider.requestAccess()
        let workouts = try await provider.hikingWorkouts()
        let existing = try await repository.healthImports()

        var summary = ImportSummary()
        for workout in workouts {
            if let state = existing[workout.id] {
                if !state.hasRoute, try await addRoute(to: state.activityId, workoutId: workout.id) {
                    summary.routesAdded += 1
                } else {
                    summary.alreadyImported += 1
                }
                continue
            }

            guard let distance = workout.distanceMeters, distance > 0 else {
                summary.skippedWithoutDistance += 1
                continue
            }

            var activity = Self.makeActivity(from: workout, distance: distance)
            let points = try await provider.route(forWorkout: workout.id)
            if points.count >= 2 { activity.route = Route(points: points) }

            do {
                try await repository.save(activity)
                summary.imported += 1
            } catch ActivityRepositoryError.workoutAlreadyImported {
                summary.alreadyImported += 1
            }
        }
        return summary
    }

    private func addRoute(to activityId: UUID, workoutId: UUID) async throws -> Bool {
        let points = try await provider.route(forWorkout: workoutId)
        guard points.count >= 2,
              var activity = try await repository.activity(id: activityId) else { return false }
        activity.route = Route(points: points)
        try await repository.save(activity)
        return true
    }

    static func makeActivity(from workout: HealthWorkout, distance: Double) -> Activity {
        Activity(
            type: .hiking,
            title: "Hike, " + workout.start.formatted(date: .abbreviated, time: .omitted),
            start: workout.start,
            durationSeconds: workout.durationSeconds,
            distanceMeters: distance,
            elevationGainMeters: workout.elevationGainMeters,
            source: .appleHealth(workoutId: workout.id)
        )
    }
}
