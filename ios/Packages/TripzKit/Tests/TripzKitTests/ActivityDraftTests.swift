import Foundation
import Testing
@testable import TripzKit

struct ActivityDraftTests {
    private let now = Date(timeIntervalSince1970: 1_000_000)
    
    private func validDraft() -> ActivityDraft {
        ActivityDraft(title: "Pilatus", start: now.addingTimeInterval(-3600), durationSeconds: 3600, distanceMeters: 5000)
    }
    
    private func errors(for draft: ActivityDraft) -> [ActivityValidationError] {
        do {
            _ = try draft.makeActivity(now: now)
            return []
        } catch {
            return error.errors
        }
    }
    
    @Test func validDraftBecomesManualActivity() throws {
        let activity = try validDraft().makeActivity(now: now)
        #expect(activity.title == "Pilatus")
        #expect(activity.source == .manual)
        #expect(activity.route == nil)
    }
    
    @Test func titleIsTrimmed() throws {
        var draft = validDraft()
        draft.title = "  Pilatus   "
        #expect(try draft.makeActivity(now: now).title == "Pilatus")
    }
    
    @Test func blankTitleIsRejected() {
        var draft = validDraft()
        draft.title = "   "
        #expect(errors(for: draft) == [.emptyTitle])
    }
    
    @Test func tooLongTitleIsRejected() {
        var draft = validDraft()
        draft.title = String(repeating: "a", count: 121)
        #expect(errors(for: draft) == [.titleTooLong(maximum: 120)])
    }
    
    @Test func futureStartIsRejected() {
        var draft = validDraft()
        draft.start = now.addingTimeInterval(1)
        #expect(errors(for: draft) == [.startInFuture])
    }
    
    @Test func startExactlyNowIsAccepted() {
        var draft = validDraft()
        draft.start = now
        #expect(errors(for: draft).isEmpty)
    }
    
    @Test(arguments: [0.0, -1.0])
    func nonPositiveDistanceIsRejected(value: Double) {
        var draft = validDraft()
        draft.distanceMeters = value
        #expect(errors(for: draft) == [.distanceNotPositive])
    }
    
    @Test(arguments: [0.0, -1.0])
    func nonPositiveDurationIsRejected(value: Double) {
        var draft = validDraft()
        draft.durationSeconds = value
        #expect(errors(for: draft) == [.durationNotPositive])
    }
    
    @Test func negativeElevationGainIsRejectedButZeroIsFine() {
        var draft = validDraft()
        draft.elevationGainMeters = -1
        #expect(errors(for: draft) == [.elevationGainNegative])
        draft.elevationGainMeters = 0
        #expect(errors(for: draft).isEmpty)
    }
    
    @Test func allProblemsAreReportedTogether() {
        let draft = ActivityDraft(start: now.addingTimeInterval(10))
        #expect(Set(errors(for: draft)) == [.emptyTitle, .startInFuture, .durationNotPositive, .distanceNotPositive])
    }
    
}
