import Observation
import TripzHealth
import Foundation

@MainActor
@Observable
final class HealthImportViewModel {
    enum State {
        case idle
        case importing
        case finished(ImportSummary)
        case failed(String)
    }
    
    private(set) var state: State = .idle
    private let importer: HealthImporter
    
    init(importer: HealthImporter) {
        self.importer = importer
    }
    
    func start() async {
        state = .importing
        do {
            let summary = try await importer.importNewWorkouts()
            state = .finished(summary) 
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
