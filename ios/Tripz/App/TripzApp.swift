import SwiftUI
import TripzStorage

@main struct TripzApp: App {
    private enum Startup {
        case ready(ActivityRepository)
        case failed(String)
    }
    
    private let startup: Startup
    
    init() {
        do {
            let url = URL.applicationSupportDirectory
                .appending(path: "Tripz", directoryHint: .isDirectory)
                .appending(path: "tripz.sqlite")
            startup = .ready(ActivityRepository(try AppDatabase.onDisk(at: url)))
        } catch {
            startup = .failed(error.localizedDescription)
        }
    }

    var body: some Scene {
        WindowGroup {
            switch startup {
            case .ready(let repository):
                ActivityListView(repository: repository)
            case .failed(let message):
                ContentUnavailableView(
                    "Tripz can't start",
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
            }
        }
    }
}
