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
    private let onImported: @MainActor () async -> Void
    
    init(importer: HealthImporter, onImported: @escaping @MainActor () async -> Void) {
        self.importer = importer
        self.onImported = onImported
    }
    
    func start() async {
        state = .importing
        do {
            let summary = try await importer.importNewWorkouts()
            state = .finished(summary)
            await onImported()
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
