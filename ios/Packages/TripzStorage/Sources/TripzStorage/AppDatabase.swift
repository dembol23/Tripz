import Foundation
import GRDB

public struct AppDatabase: Sendable {
    public let writer: any DatabaseWriter
    
    public init(_ writer: any DatabaseWriter) throws {
        self.writer = writer
        try Self.migrator.migrate(writer)
    }
    
    static var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        
        migrator.registerMigration("v1_activities") { db in
            try db.create(table: "activity") { t in
                t.primaryKey("id", .text)
                t.column("type", .text).notNull()
                t.column("title", .text).notNull()
                t.column("start", .datetime).notNull()
                t.column("durationSeconds", .double).notNull()
                t.column("distanceMeters", .double).notNull()
                t.column("elevationGainMeters", .double)
                t.column("notes", .text).notNull()
                t.column("sourceKind", .text).notNull()
                t.column("healthWorkoutId", .text)
            }
            
            try db.create(index: "activity_healthWorkoutId", on: "activity", columns: ["healthWorkoutId"], unique: true)
            
            try db.create(table: "routePoint") { t in
                t.column("activityId", .text).notNull().references("activity", onDelete: .cascade)
                t.column("position", .integer).notNull()
                t.column("latitude", .double).notNull()
                t.column("longitude", .double).notNull()
                t.column("elevationMeters", .double)
                t.column("timestamp", .datetime)
                t.primaryKey(["activityId", "position"])
            }
        }
        
        return migrator
    }
}
