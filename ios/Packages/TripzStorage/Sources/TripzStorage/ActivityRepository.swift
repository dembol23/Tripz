import Foundation
import GRDB
import TripzKit

public enum ActivityRepositoryError: Error, Equatable {
    case workoutAlreadyImported(workoutId: UUID)
    case activityNotFound(id: UUID)
}

public struct ActivityRepository: Sendable {
    private let writer: any DatabaseWriter
    
    public init(_ database: AppDatabase) {
        self.writer = database.writer
    }
    
    /// Inserts a new activity, or replaces an existing one with the same id.
    /// The activity row and its route points change in one transaction.
    public func save(_ activity: Activity) async throws {
        let record = ActivityRecord(activity)
        let points = activity.route.map {
            RoutePointRecord.records(for: $0, activityId: activity.id)
        } ?? []
        
        do{
            try await writer.write { db in
                try record.save(db)
                try RoutePointRecord
                    .filter(Column("activityId") == record.id)
                    .deleteAll(db)
                for point in points {
                    try point.insert(db)
                }
            }
        }catch let error as DatabaseError
                    where error.extendedResultCode == .SQLITE_CONSTRAINT_UNIQUE {
            if case .appleHealth(let workoutId) = activity.source {
                throw ActivityRepositoryError.workoutAlreadyImported(workoutId: workoutId)
            }
            throw error
        }
    }
    
    /// Returns the activity with its route, or nil if it doesn't exist.
    public func activity(id: UUID) async throws -> Activity? {
        try await writer.read { db in
            guard let record = try ActivityRecord.fetchOne(db, key: id.uuidString) else {
                return nil
            }
            return try Self.makeActivity(from: record, includingRoute: true, in: db)
        }
    }
    
    /// Returns all activities, newest first.
    /// Routes are left out by default: a list doesn't need thousands of
    /// points per row. Ask for them only when you need them.
    public func activities(includingRoutes: Bool = false) async throws -> [Activity] {
        try await writer.read { db in
            let records = try ActivityRecord
                .order(Column("start").desc)
                .fetchAll(db)
            return try records.map {
                try Self.makeActivity(from: $0, includingRoute: includingRoutes, in: db)
            }
        }
    }
    
    /// Deletes the activity. Its route points are removed with it.
    public func delete(id: UUID) async throws {
        try await writer.write { db in
            _ = try ActivityRecord.deleteOne(db, key: id.uuidString)
        }
    }
    
    /// Changes only the title and notes. Route points are not touched, so editing
    /// a long hike does not rewrite thousands of rows.
    public func updateDetails(id: UUID, title: String, notes: String) async throws {
        let changed = try await writer.write { db -> Int in
            try db.execute(
                sql: "UPDATE activity SET title = ?, notes = ? WHERE id = ?",
                arguments: [title, notes, id.uuidString]
            )
            return db.changesCount
        }
        guard changed > 0 else { throw ActivityRepositoryError.activityNotFound(id: id) }
    }
    
    public func activityUpdates() -> some AsyncSequence<[Activity], any Error> {
        ValueObservation
            .tracking { db in
                try ActivityRecord.order(Column("start").desc).fetchAll(db)
                    .map { try $0.makeActivity(route: nil) }
            }
            .values(in: writer)
    }
    
    private static func makeActivity(
        from record: ActivityRecord,
        includingRoute: Bool,
        in db: Database
    ) throws -> Activity {
        var route: Route?
        if includingRoute {
            let points = try RoutePointRecord
                .filter(Column("activityId") == record.id)
                .order(Column("position"))
                .fetchAll(db)
            route = points.isEmpty ? nil : Route(points: points.map(\.trackPoint))
        }
        return try record.makeActivity(route: route)
    }
    
    public func healthImports() async throws -> [UUID: HealthImportState] {
        try await writer.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT a.id, a.healthWorkoutId,
                       EXISTS (SELECT 1 FROM routePoint r WHERE r.activityId = a.id) AS hasRoute
                FROM activity a
                WHERE a.healthWorkoutId IS NOT NULL
                """)
            var result: [UUID: HealthImportState] = [:]
            for row in rows {
                guard let activityId = UUID(uuidString: row["id"]),
                      let workoutId = UUID(uuidString: row["healthWorkoutId"]) else {
                    throw StorageError.invalidRow("Apple Health activity with a malformed id")
                }
                result[workoutId] = HealthImportState(activityId: activityId, hasRoute: row["hasRoute"])
            }
            return result
        }
    }
    
}

public struct HealthImportState: Equatable, Sendable {
    public let activityId: UUID
    public let hasRoute: Bool
}
