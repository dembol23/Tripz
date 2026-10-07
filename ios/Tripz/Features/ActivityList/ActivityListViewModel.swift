import Observation
import TripzKit
import TripzStorage
import Foundation

@MainActor
@Observable
final class ActivityListViewModel {
    enum State {
        case loading
        case loaded([Activity])
        case failed(String)
    }

    private(set) var state: State = .loading
    private let repository: ActivityRepository

    init(repository: ActivityRepository) {
        self.repository = repository
    }

    func load() async {
        do {
            state = .loaded(try await repository.activities())
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
    
#if DEBUG
    func addSampleActivity() async {
        do {
            try await repository.save(SampleData.pilatusHike())
            await load()
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
#endif
    
}
