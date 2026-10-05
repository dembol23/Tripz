import Foundation

public enum ActivitySource: Hashable, Sendable {
    case manual
    case appleHealth(workoutId: UUID)
}
