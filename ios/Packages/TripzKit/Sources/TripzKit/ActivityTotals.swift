import Foundation

public struct ActivityTotals: Equatable, Sendable {
    public let count: Int
    public let distanceMeters: Double
    public let durationSeconds: Double
    public let elevationGainMeters: Double

    public init(_ activities: [Activity]) {
        count = activities.count
        distanceMeters = activities.reduce(0) { $0 + $1.distanceMeters }
        durationSeconds = activities.reduce(0) { $0 + $1.durationSeconds }
        elevationGainMeters = activities.reduce(0) { $0 + ($1.elevationGainMeters ?? 0) }
    }
}
