import Foundation
import GRDB
import TripzKit

struct ActivityRecord: Codable, FetchableRecord,PersistableRecord, Equatable {
    static let databaseTableName = "activity"
    
    var id: String
    var type: String
    var title: String
    var start: Date
    var durationSeconds: Double
    var distanceMeters: Double
    var elevationGainMeters: Double?
    var notes: String
    var sourceKind: String
    var healthWorkoutId: String?
}
