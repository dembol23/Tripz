import Foundation

public struct Activity: Identifiable, Hashable, Sendable {
    public let id: UUID
    public var type: ActivityType
    public var title: String
    public var start: Date
    public var durationSeconds: Double
    public var distanceMeters: Double
    public var elevationGainMeters: Double?
    public var notes: String
    public var source: ActivitySource
    public var route: Route?
    
    public init(id: UUID = UUID(), type: ActivityType = .hiking, title: String, start: Date, durationSeconds: Double, distanceMeters: Double, elevationGainMeters: Double? = nil, notes: String = "", source: ActivitySource = .manual, route: Route? = nil) {
        self.id = id
        self.type = type
        self.title = title
        self.start = start
        self.durationSeconds = durationSeconds
        self.distanceMeters = distanceMeters
        self.elevationGainMeters = elevationGainMeters
        self.notes = notes
        self.source = source
        self.route = route
    }
}
