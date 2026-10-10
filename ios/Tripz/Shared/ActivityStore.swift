import Observation
import TripzStorage
import Foundation

@MainActor
@Observable
final class ActivityStore {
    enum State {
        case loading
        case loaded([ActivitySummary])
        case failed(String)
    }
    
    private(set) var state: State = .loading
    let repository: ActivityRepository
    
    init(repository: ActivityRepository) {
        self.repository = repository
    }
    
    func run() async {
        do {
            for try await summaries in repository.activityUpdates() {
                state = .loaded(summaries)
            }
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
