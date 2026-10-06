import Foundation
import GRDB
import TripzKit

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
        
        try await writer.write { db in
            try record.save(db)
            try RoutePointRecord
                .filter(Column("activityId") == record.id)
                .deleteAll(db)
            for point in points {
                try point.insert(db)
            }
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
    
}
