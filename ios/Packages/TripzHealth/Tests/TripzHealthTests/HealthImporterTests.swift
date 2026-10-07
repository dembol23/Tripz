import Foundation
import Testing
import TripzKit
import TripzStorage
@testable import TripzHealth

struct HealthImporterTests {
    private struct FakeProvider: WorkoutProvider {
        var workouts: [HealthWorkout] = []
        var routes: [UUID: [TrackPoint]] = [:]
        var accessError: (any Error)?

        func requestAccess() async throws {
            if let accessError { throw accessError }
        }
        func hikingWorkouts() async throws -> [HealthWorkout] { workouts }
        func route(forWorkout id: UUID) async throws -> [TrackPoint] { routes[id] ?? [] }
    }
    
    private func points(_ count: Int) -> [TrackPoint] {
        (0..<count).map { TrackPoint(latitude: 47 + Double($0) * 0.001, longitude: 8) }
    }

    private struct TestError: Error {}

    private let start = Date(timeIntervalSince1970: 1_000_000)

    private func workout(distance: Double? = 5000, elevation: Double? = 700) -> HealthWorkout {
        HealthWorkout(
            id: UUID(),
            start: start,
            durationSeconds: 3600,
            distanceMeters: distance,
            elevationGainMeters: elevation
        )
    }

    @Test func importsWorkoutsAsAppleHealthActivities() async throws {
        let repository = ActivityRepository(try AppDatabase.inMemory())
        let source = workout()
        let importer = HealthImporter(provider: FakeProvider(workouts: [source]), repository: repository)

        let summary = try await importer.importNewWorkouts()

        #expect(summary == ImportSummary(imported: 1))
        let stored = try await repository.activities()
        let activity = try #require(stored.first)
        #expect(stored.count == 1)
        #expect(activity.source == .appleHealth(workoutId: source.id))
        #expect(activity.type == .hiking)
        #expect(activity.distanceMeters == 5000)
        #expect(activity.elevationGainMeters == 700)
        #expect(activity.durationSeconds == 3600)
        #expect(activity.start == start)
        #expect(activity.route == nil)
        #expect(activity.title.hasPrefix("Hike"))
    }

    @Test func runningTheImportTwiceDoesNotDuplicate() async throws {
        let repository = ActivityRepository(try AppDatabase.inMemory())
        let importer = HealthImporter(
            provider: FakeProvider(workouts: [workout(), workout()]),
            repository: repository
        )

        let first = try await importer.importNewWorkouts()
        let second = try await importer.importNewWorkouts()
        let stored = try await repository.activities()

        #expect(first == ImportSummary(imported: 2))
        #expect(second == ImportSummary(alreadyImported: 2))
        #expect(stored.count == 2)
    }

    @Test func newWorkoutsAreImportedOnALaterRun() async throws {
        let repository = ActivityRepository(try AppDatabase.inMemory())
        let old = workout()
        let new = workout()

        _ = try await HealthImporter(provider: FakeProvider(workouts: [old]), repository: repository)
            .importNewWorkouts()
        let summary = try await HealthImporter(
            provider: FakeProvider(workouts: [old, new]),
            repository: repository
        ).importNewWorkouts()

        #expect(summary == ImportSummary(imported: 1, alreadyImported: 1))
    }

    @Test func workoutsWithoutDistanceAreSkippedAndCounted() async throws {
        let repository = ActivityRepository(try AppDatabase.inMemory())
        let importer = HealthImporter(
            provider: FakeProvider(workouts: [workout(distance: nil), workout(distance: 0), workout()]),
            repository: repository
        )

        let summary = try await importer.importNewWorkouts()
        let stored = try await repository.activities()

        #expect(summary == ImportSummary(imported: 1, skippedWithoutDistance: 2))
        #expect(stored.count == 1)
    }

    @Test func reimportingDoesNotOverwriteUserEdits() async throws {
        let repository = ActivityRepository(try AppDatabase.inMemory())
        let importer = HealthImporter(provider: FakeProvider(workouts: [workout()]), repository: repository)
        _ = try await importer.importNewWorkouts()

        var activity = try #require(try await repository.activities().first)
        activity.title = "My favourite hike"
        try await repository.save(activity)

        _ = try await importer.importNewWorkouts()

        let stored = try await repository.activities()
        #expect(stored.count == 1)
        #expect(stored.first?.title == "My favourite hike")
    }

    @Test func failedAccessStopsTheImportAndSavesNothing() async throws {
        let repository = ActivityRepository(try AppDatabase.inMemory())
        let importer = HealthImporter(
            provider: FakeProvider(workouts: [workout()], accessError: TestError()),
            repository: repository
        )

        await #expect(throws: TestError.self) {
            _ = try await importer.importNewWorkouts()
        }
        let stored = try await repository.activities()
        #expect(stored.isEmpty)
    }
    
    @Test func newWorkoutIsImportedWithItsRoute() async throws {
        let repository = ActivityRepository(try AppDatabase.inMemory())
        let source = workout()
        let provider = FakeProvider(workouts: [source], routes: [source.id: points(3)])

        let summary = try await HealthImporter(provider: provider, repository: repository)
            .importNewWorkouts()

        #expect(summary == ImportSummary(imported: 1))
        let stored = try await repository.activities(includingRoutes: true)
        #expect(stored.first?.route?.points.count == 3)
    }

    @Test func workoutWithoutRouteIsStillImported() async throws {
        let repository = ActivityRepository(try AppDatabase.inMemory())
        let importer = HealthImporter(provider: FakeProvider(workouts: [workout()]), repository: repository)

        let summary = try await importer.importNewWorkouts()
        let stored = try await repository.activities(includingRoutes: true)

        #expect(summary == ImportSummary(imported: 1))
        #expect(stored.first?.route == nil)
    }

    @Test func aSinglePointIsNotARoute() async throws {
        let repository = ActivityRepository(try AppDatabase.inMemory())
        let source = workout()
        let provider = FakeProvider(workouts: [source], routes: [source.id: points(1)])

        _ = try await HealthImporter(provider: provider, repository: repository).importNewWorkouts()
        let stored = try await repository.activities(includingRoutes: true)

        #expect(stored.first?.route == nil)
    }

    @Test func routeIsAddedToAnActivityImportedEarlierWithoutOne() async throws {
        let repository = ActivityRepository(try AppDatabase.inMemory())
        let source = workout()

        _ = try await HealthImporter(provider: FakeProvider(workouts: [source]), repository: repository)
            .importNewWorkouts()

        var activity = try #require(try await repository.activities().first)
        activity.title = "My favourite hike"
        try await repository.save(activity)

        let summary = try await HealthImporter(
            provider: FakeProvider(workouts: [source], routes: [source.id: points(4)]),
            repository: repository
        ).importNewWorkouts()

        #expect(summary == ImportSummary(routesAdded: 1))
        let stored = try await repository.activities(includingRoutes: true)
        #expect(stored.count == 1)
        #expect(stored.first?.id == activity.id)
        #expect(stored.first?.title == "My favourite hike")
        #expect(stored.first?.route?.points.count == 4)
    }

    @Test func anExistingRouteIsNeverReplaced() async throws {
        let repository = ActivityRepository(try AppDatabase.inMemory())
        let source = workout()

        _ = try await HealthImporter(
            provider: FakeProvider(workouts: [source], routes: [source.id: points(3)]),
            repository: repository
        ).importNewWorkouts()
        let summary = try await HealthImporter(
            provider: FakeProvider(workouts: [source], routes: [source.id: points(9)]),
            repository: repository
        ).importNewWorkouts()

        #expect(summary == ImportSummary(alreadyImported: 1))
        let stored = try await repository.activities(includingRoutes: true)
        #expect(stored.first?.route?.points.count == 3)
    }

    @Test func aWorkoutThatStillHasNoRouteCountsAsAlreadyImported() async throws {
        let repository = ActivityRepository(try AppDatabase.inMemory())
        let importer = HealthImporter(provider: FakeProvider(workouts: [workout()]), repository: repository)

        _ = try await importer.importNewWorkouts()
        let summary = try await importer.importNewWorkouts()

        #expect(summary == ImportSummary(alreadyImported: 1))
    }
}
