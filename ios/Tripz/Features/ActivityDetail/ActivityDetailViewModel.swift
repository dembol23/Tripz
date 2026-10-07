import Foundation
import Observation
import TripzKit
import TripzStorage

@MainActor
@Observable
final class ActivityDetailViewModel {
    enum State {
        case loading
        case loaded(Activity)
        case deleted
        case notFound
        case failed(String)
    }
    
    
    var isDeleted: Bool {
        if case .deleted = state { true } else { false }
    }
    
    private(set) var state: State = .loading
    private let id: UUID
    private let repository: ActivityRepository
    
    init(id: UUID, repository: ActivityRepository) {
        self.id = id
        self.repository = repository
    }
    
    func load() async {
        do {
            if let activity = try await repository.activity(id: id) {
                state = .loaded(activity)
            } else {
                state = .notFound
            }
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
    
    func apply(_ edit: ActivityEdit) async -> String? {
        guard case .loaded(var loaded) = state else { return nil }
        do {
            let valid = try edit.validated()
            try await repository.updateDetails(id: id, title: valid.title, notes: valid.notes)
            loaded.title = valid.title
            loaded.notes = valid.notes
            state = .loaded(loaded)
            return nil
        } catch let failure as ActivityValidationFailure {
            return failure.errors.contains(.emptyTitle)
            ? "Give the activity a title."
            : "The title is too long (maximum \(ActivityDraft.maximumTitleLength) characters)."
        } catch {
            return error.localizedDescription
        }
    }
    
    func delete() async -> String? {
        do {
            try await repository.delete(id: id)
            state = .deleted
            return nil
        } catch {
            return error.localizedDescription
        }
    }
}
