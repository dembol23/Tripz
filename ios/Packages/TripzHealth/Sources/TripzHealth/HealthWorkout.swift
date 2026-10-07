import Foundation

public struct HealthWorkout: Hashable, Sendable {
    public let id: UUID
    public let start: Date
    public let durationSeconds: Double
    public let distanceMeters: Double?
    public let elevationGainMeters: Double?

    public init(
        id: UUID,
        start: Date,
        durationSeconds: Double,
        distanceMeters: Double?,
        elevationGainMeters: Double?
    ) {
        self.id = id
        self.start = start
        self.durationSeconds = durationSeconds
        self.distanceMeters = distanceMeters
        self.elevationGainMeters = elevationGainMeters
    }
}
