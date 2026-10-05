import Foundation

public enum ActivityValidationError: Error, Hashable, Sendable {
    case emptyTitle
    case titleTooLong(maximum: Int)
    case startInFuture
    case durationNotPositive
    case distanceNotPositive
    case elevationGainNegative
}

public struct ActivityValidationFailure: Error, Hashable, Sendable {
    public let errors: [ActivityValidationError]
}

public struct ActivityDraft: Hashable, Sendable {
    public static let maximumTitleLength = 120
    
    public var title: String
    public var start: Date
    public var durationSeconds: Double
    public var distanceMeters: Double
    public var elevationGainMeters: Double?
    public var notes: String
    
    public init(title: String = "", start: Date, durationSeconds: Double = 0, distanceMeters: Double = 0, elevationGainMeters: Double? = nil, notes: String = "") {
        self.title = title
        self.start = start
        self.durationSeconds = durationSeconds
        self.distanceMeters = distanceMeters
        self.elevationGainMeters = elevationGainMeters
        self.notes = notes
    }
    
    public func makeActivity(now: Date) throws(ActivityValidationFailure) -> Activity {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        var errors: [ActivityValidationError] = []
        
        if trimmedTitle.isEmpty { errors.append(.emptyTitle) }
        if trimmedTitle.count > Self.maximumTitleLength { errors.append(.titleTooLong(maximum: Self.maximumTitleLength)) }
        if start > now { errors.append(.startInFuture) }
        if durationSeconds <= 0 { errors.append(.durationNotPositive) }
        if distanceMeters <= 0 { errors.append(.distanceNotPositive) }
        if let gain = elevationGainMeters, gain < 0 { errors.append(.elevationGainNegative) }
        
        guard errors.isEmpty else { throw ActivityValidationFailure(errors: errors) }
        
        return Activity(title: trimmedTitle, start: start, durationSeconds: durationSeconds, distanceMeters: distanceMeters, elevationGainMeters: elevationGainMeters, notes: notes)
    }
}
