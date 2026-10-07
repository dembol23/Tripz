import Foundation

public struct ActivityEdit: Equatable, Sendable {
    public var title: String
    public var notes: String
    
    public init(title: String, notes: String) {
        self.title = title
        self.notes = notes
    }
    
    public init(_ activity: Activity) {
        self.init(title: activity.title, notes: activity.notes)
    }
    
    public func validated() throws(ActivityValidationFailure) -> ActivityEdit {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        var errors: [ActivityValidationError] = []
        if trimmed.isEmpty { errors.append(.emptyTitle) }
        if trimmed.count > ActivityDraft.maximumTitleLength {
            errors.append(.titleTooLong(maximum: ActivityDraft.maximumTitleLength))
        }
        guard errors.isEmpty else { throw ActivityValidationFailure(errors: errors) }
        return ActivityEdit(title: trimmed, notes: notes)
    }
}
