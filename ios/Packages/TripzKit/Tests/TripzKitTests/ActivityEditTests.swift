import Foundation
import Testing
@testable import TripzKit

struct ActivityEditTests {
    private func errors(for edit: ActivityEdit) -> [ActivityValidationError] {
        do {
            _ = try edit.validated()
            return []
        } catch {
            return error.errors
        }
    }

    @Test func startsFromTheActivity() {
        let activity = Activity(title: "Pilatus", start: Date(timeIntervalSince1970: 0),
                                durationSeconds: 3600, distanceMeters: 5000, notes: "Clear sky")
        #expect(ActivityEdit(activity) == ActivityEdit(title: "Pilatus", notes: "Clear sky"))
    }

    @Test func titleIsTrimmedButNotesAreKeptAsTyped() throws {
        let valid = try ActivityEdit(title: "  Rigi  ", notes: "  line one\nline two  ").validated()
        #expect(valid.title == "Rigi")
        #expect(valid.notes == "  line one\nline two  ")
    }

    @Test func blankTitleIsRejected() {
        #expect(errors(for: ActivityEdit(title: "   ", notes: "")) == [.emptyTitle])
    }

    @Test func titleLimitIsInclusive() {
        let atLimit = String(repeating: "a", count: ActivityDraft.maximumTitleLength)
        #expect(errors(for: ActivityEdit(title: atLimit, notes: "")).isEmpty)
        #expect(errors(for: ActivityEdit(title: atLimit + "a", notes: ""))
                == [.titleTooLong(maximum: ActivityDraft.maximumTitleLength)])
    }
}
