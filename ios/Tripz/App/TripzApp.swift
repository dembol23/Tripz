import SwiftUI

@main
struct TripzApp: App {
    private let dependencies: Result<AppDependencies, any Error>

    init() {
        dependencies = Result { try AppDependencies.live() }
    }

    var body: some Scene {
        WindowGroup {
            switch dependencies {
            case .success(let dependencies):
                MainTabView(dependencies: dependencies)
            case .failure(let error):
                ContentUnavailableView(
                    "Tripz can't start",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error.localizedDescription)
                )
            }
        }
    }
}
