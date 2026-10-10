import SwiftUI
import TripzStorage

struct FeedView: View {
    let dependencies: AppDependencies

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Feed")
                .activityDestination(repository: dependencies.repository)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch dependencies.activities.state {
        case .loading:
            ProgressView()
        case .failed(let message):
            ContentUnavailableView(
                "Couldn't load activities",
                systemImage: "exclamationmark.triangle",
                description: Text(message)
            )
        case .loaded(let summaries) where summaries.isEmpty:
            ContentUnavailableView(
                "No activities yet",
                systemImage: "figure.hiking",
                description: Text("Import a hike from Apple Health.")
            )
        case .loaded(let summaries):
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(summaries) { summary in
                        NavigationLink(value: ActivityRoute(activityId: summary.id)) {
                            ActivityCardView(summary: summary, previews: dependencies.previews)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .background(Color(.systemGroupedBackground))
        }
    }
}
