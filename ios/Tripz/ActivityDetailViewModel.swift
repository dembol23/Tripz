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
        case notFound
        case failed(String)
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
}
