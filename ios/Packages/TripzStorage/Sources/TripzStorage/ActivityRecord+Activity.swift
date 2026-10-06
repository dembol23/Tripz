import Foundation
import TripzKit

enum StorageError: Error, Equatable {
    case invalidRow(String)
}

extension ActivityRecord {
    private enum SourceKind {
        static let manual = "manual"
        static let appleHealth = "appleHealth"
    }
    
    init(_ activity: Activity) {
        let kind: String
        let workoutId: String?
        switch activity.source {
            case .manual:
                kind = SourceKind.manual
                workoutId = nil
            case .appleHealth(let id):
                kind = SourceKind.appleHealth
                workoutId = id.uuidString
        }
        self.init(
            id: activity.id.uuidString,
            type: activity.type.rawValue,
            title: activity.title,
            start: activity.start,
            durationSeconds: activity.durationSeconds,
            distanceMeters: activity.distanceMeters,
            elevationGainMeters: activity.elevationGainMeters,
            notes: activity.notes,
            sourceKind: kind,
            healthWorkoutId: workoutId
        )
    }
    
    func makeActivity(route: Route?) throws -> Activity {
        guard let uuid = UUID(uuidString: id) else {
            throw StorageError.invalidRow("activity id is not a UUID: \(id)")
        }
        guard let activityType = ActivityType(rawValue: type) else {
            throw StorageError.invalidRow("unknown activity type: \(type)")
        }
        
        let activitySource: ActivitySource
        switch sourceKind {
        case SourceKind.manual:
            activitySource = .manual
        case SourceKind.appleHealth:
            guard let raw = healthWorkoutId, let workoutUUID = UUID(uuidString: raw) else {
                throw StorageError.invalidRow("Apple Health activity without a valid workout id")
            }
            activitySource = .appleHealth(workoutId: workoutUUID)
        default:
            throw StorageError.invalidRow("unknown source kind \(sourceKind)")
        }
        return Activity(id: uuid, type: activityType, title: title, start: start, durationSeconds: durationSeconds, distanceMeters: distanceMeters, elevationGainMeters: elevationGainMeters, notes:    notes, source: activitySource, route: route)
    }
}
