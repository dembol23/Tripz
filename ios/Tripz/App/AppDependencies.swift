import Foundation
import TripzStorage
import TripzHealth

@MainActor
struct AppDependencies {
    let repository: ActivityRepository
    let importer: HealthImporter
    let previews: RoutePreviewStore
    let activities: ActivityStore
    
    init(database: AppDatabase) {
        let repository = ActivityRepository(database)
        self.repository = repository
        self.importer = HealthImporter(provider: HealthKitWorkoutProvider(), repository: repository)
        self.previews = RoutePreviewStore(repository: repository)
        self.activities = ActivityStore(repository: repository)
    }
    
    static func live() throws -> AppDependencies {
        let url = URL.applicationSupportDirectory
            .appending(path: "Tripz", directoryHint: .isDirectory)
            .appending(path: "tripz.sqlite")
        return AppDependencies(database: try .onDisk(at: url))
    }
    
    static func preview() throws -> AppDependencies {
        AppDependencies(database: try .inMemory())
    }
}
