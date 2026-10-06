import Foundation
import GRDB
import TripzKit

struct RoutePointRecord: Codable, FetchableRecord,PersistableRecord, Equatable {
    static let databaseTableName = "routePoint"
    
    var activityId: String
    var position: Int
    var latitude: Double
    var longitude: Double
    var elevationMeters: Double?
    var timestamp: Date?
}

extension RoutePointRecord {
    static func records(for route: Route, activityId: UUID) -> [RoutePointRecord] {
        route.points.enumerated().map { index, point in
            RoutePointRecord(activityId: activityId.uuidString, position: index, latitude: point.latitude, longitude: point.longitude, elevationMeters: point.elevationMeters, timestamp: point.timestamp)
        }
    }
    
    var trackPoint: TrackPoint {
        TrackPoint(latitude: latitude, longitude: longitude, elevationMeters: elevationMeters, timestamp: timestamp)
    }
}
