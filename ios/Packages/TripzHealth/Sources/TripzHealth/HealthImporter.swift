import Foundation
import TripzKit
import TripzStorage

public struct ImportSummary: Equatable, Sendable {
    public var imported: Int
    public var alreadyImported: Int
    public var skippedWithoutDistance: Int

    public var found: Int { imported + alreadyImported + skippedWithoutDistance }

    public init(imported: Int = 0, alreadyImported: Int = 0, skippedWithoutDistance: Int = 0) {
        self.imported = imported
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

        var summary = ImportSummary()
        for workout in workouts {
            guard let distance = workout.distanceMeters, distance > 0 else {
                summary.skippedWithoutDistance += 1
                continue
            }
            do {
                try await repository.save(Self.makeActivity(from: workout, distance: distance))
                summary.imported += 1
            } catch ActivityRepositoryError.workoutAlreadyImported {
                summary.alreadyImported += 1
            }
        }
        return summary
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
