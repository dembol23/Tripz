import SwiftUI
import TripzStorage

struct ActivityRoute: Hashable {
    let activityId: UUID
}

extension View {
    func activityDestination(repository: ActivityRepository) -> some View {
        navigationDestination(for: ActivityRoute.self) { route in
            ActivityDetailView(activityId: route.activityId, repository: repository)
        }
    }
}
