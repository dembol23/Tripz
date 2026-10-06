import Foundation
import GRDB

extension AppDatabase {
    public static func onDisk(at url: URL) throws -> AppDatabase {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let pool = try DatabasePool(path: url.path)
        return try AppDatabase(pool)
    }
    
    public static func inMemory() throws -> AppDatabase {
        try AppDatabase(DatabaseQueue())
    }
}
