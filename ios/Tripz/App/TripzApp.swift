import SwiftUI
import TripzStorage
import TripzHealth

@main struct TripzApp: App {
    private enum Startup {
        case ready(ActivityRepository, RoutePreviewStore)
        case failed(String)
    }
    
    private let startup: Startup
    
    init() {
        do {
            let url = URL.applicationSupportDirectory
                .appending(path: "Tripz", directoryHint: .isDirectory)
                .appending(path: "tripz.sqlite")
            let repository = ActivityRepository(try AppDatabase.onDisk(at: url))
            startup = .ready(repository, RoutePreviewStore(repository: repository))
        } catch {
            startup = .failed(error.localizedDescription)
        }
    }

    var body: some Scene {
        WindowGroup {
            switch startup {
            case .ready(let repository, let previews):
                ActivityListView(
                    repository: repository,
                    importer: HealthImporter(provider: HealthKitWorkoutProvider(), repository: repository),
                    previews: previews
                )
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
