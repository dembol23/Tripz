import Foundation
import GRDB
import Testing
import TripzKit
@testable import TripzStorage

struct ActivityRepositoryTests {
    private let start = Date(timeIntervalSince1970: 1_000_000)
    
    private func makeRepository() throws -> (repository: ActivityRepository, database:AppDatabase) {
        let database = try AppDatabase(DatabaseQueue())
        return (ActivityRepository(database), database)
    }
    
    private func makeActivity(
        title: String = "Pilatus",
        start: Date? = nil,
        route: Route? = nil
    ) -> Activity {
        Activity(title: title, start: start ?? self.start, durationSeconds: 3600, distanceMeters: 5000, route: route)
    }
    
    private let route = Route(points: [
        TrackPoint(latitude: 47.0, longitude: 8.0, elevationMeters: 500, timestamp: Date(timeIntervalSince1970: 1_000_000)),
        TrackPoint(latitude: 47.1, longitude: 8.1),
        TrackPoint(latitude: 47.2, longitude: 8.2, elevationMeters: 900),
    ])
    
    @Test func savedManualActivityCanBeFetched() async throws {
        let (repository, _) = try makeRepository()
        let activity = makeActivity()
        try await repository.save(activity)
        let fetched = try await repository.activity(id: activity.id)
        #expect(fetched == activity)
    }

    @Test func routeSurvivesRoundTripInOrder() async throws {
        let (repository, _) = try makeRepository()
        let activity = makeActivity(route: route)
        try await repository.save(activity)
        let fetched = try await repository.activity(id: activity.id)
        #expect(fetched?.route == route)
    }

    @Test func savingAgainUpdatesInsteadOfDuplicating() async throws {
        let (repository, _) = try makeRepository()
        var activity = makeActivity(route: route)
        try await repository.save(activity)

        activity.title = "Pilatus (renamed)"
        activity.route = Route(points: [TrackPoint(latitude: 1, longitude: 2)])
        try await repository.save(activity)

        let all = try await repository.activities(includingRoutes: true)
        #expect(all.count == 1)
        #expect(all.first?.title == "Pilatus (renamed)")
        #expect(all.first?.route?.points.count == 1)
    }

    @Test func emptyRouteReadsBackAsNil() async throws {
        let (repository, _) = try makeRepository()
        let activity = makeActivity(route: Route(points: []))
        try await repository.save(activity)
        let fetched = try await repository.activity(id: activity.id)
        #expect(fetched?.route == nil)
    }

    @Test func fetchingUnknownIDReturnsNil() async throws {
        let (repository, _) = try makeRepository()
        let fetched = try await repository.activity(id: UUID())
        #expect(fetched == nil)
    }

    @Test func listIsNewestFirstAndOmitsRoutesByDefault() async throws {
        let (repository, _) = try makeRepository()
        let older = makeActivity(title: "Older", start: start, route: route)
        let newer = makeActivity(title: "Newer", start: start.addingTimeInterval(86_400))
        try await repository.save(older)
        try await repository.save(newer)

        let list = try await repository.activities()
        #expect(list.map(\.title) == ["Newer", "Older"])
        #expect(list.allSatisfy { $0.route == nil })

        let withRoutes = try await repository.activities(includingRoutes: true)
        #expect(withRoutes.last?.route == route)
    }

    @Test func deleteRemovesActivityAndItsRoutePoints() async throws {
        let (repository, database) = try makeRepository()
        let activity = makeActivity(route: route)
        try await repository.save(activity)

        try await repository.delete(id: activity.id)

        let fetched = try await repository.activity(id: activity.id)
        let remainingPoints = try await database.writer.read { db in
            try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM routePoint") ?? 0
        }
        #expect(fetched == nil)
        #expect(remainingPoints == 0)
    }
}
