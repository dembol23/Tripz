import Foundation
import GRDB
import Testing
@testable import TripzStorage

struct MigrationTests {
    private func makeDatabase() throws -> AppDatabase {
        try AppDatabase(DatabaseQueue())
    }
    
    private func insertActivity(
        _ db: Database,
        id: String = UUID().uuidString,
        healthWorkoutId: String? = nil
    ) throws {
        try db.execute(
            sql: """
                INSERT INTO activity
                (id, type, title, start, durationSeconds, distanceMeters,
                 notes, sourceKind, healthWorkoutId)
                VALUES (?, 'hiking', 'Test', ?, 3600, 5000, '', ?, ?)
                """,
            arguments: [
                id,
                Date(timeIntervalSince1970: 0),
                healthWorkoutId == nil ? "manual" : "appleHealth",
                healthWorkoutId,
            ]
        )
    }
    
    @Test func migrationCreatesTables() throws {
        let database = try makeDatabase()
	let activityTableExists = try database.writer.read { db in
	    try db.tableExists("activity")
	}
	let routePointTableExists = try database.writer.read { db in
	    try db.tableExists("routePoint")
	}	
	#expect(activityTableExists)
	#expect(routePointTableExists)
    }
    
    @Test func manualActivitiesMayShareNullWorkoutId() throws {
        let database = try makeDatabase()
        try database.writer.write { db in
            try insertActivity(db)
            try insertActivity(db)
        }
    }
    
    @Test func sameHealthWorkoutCannotBeStoredTwice() throws {
        let database = try makeDatabase()
        #expect(throws: DatabaseError.self) {
            try database.writer.write { db in
                try insertActivity(db, healthWorkoutId: "workout-1")
                try insertActivity(db, healthWorkoutId: "workout-1")
            }
        }
    }
    
    @Test func deletingActivityDeletesItsRoutePoints() throws {
        let database = try makeDatabase()
        let id = UUID().uuidString
        try database.writer.write { db in
            try insertActivity(db, id: id)
            try db.execute(
                sql: """
                    INSERT INTO routePoint (activityId, position, latitude, longitude)
                    VALUES (?, 0, 47.0, 8.0)
                    """,
                arguments: [id]
            )
            try db.execute(sql: "DELETE FROM activity WHERE id = ?", arguments: [id])
        }
        let remaining = try database.writer.read { db in
            try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM routePoint")
        }
        #expect(remaining == 0)
    }
    
}
