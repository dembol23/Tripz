import SwiftUI
import TripzKit
import TripzStorage

struct ActivityListView: View {
    @State private var viewModel: ActivityListViewModel
    
    init(repository: ActivityRepository) {
        _viewModel = State(initialValue: ActivityListViewModel(repository: repository))
    }
    
    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Activities")
        }
        .task{ await viewModel.load() }
    }
    
    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
            case .loading:
                ProgressView()
            case .failed(let message):
                ContentUnavailableView("Couldn't load activities", systemImage: "exclamationmark.triangle", description: Text(message))
            case .loaded(let activities) where activities.isEmpty:
                ContentUnavailableView(
                    "No activities yet",
                    systemImage: "figure.hiking",
                    description: Text("Add a hike manually or import one from Apple Health.")
                )
            case .loaded(let activities):
                List(activities) { activity in
                    ActivityRow(activity: activity)
                }
            }
        }
}

private struct ActivityRow: View {
    let activity: Activity

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(activity.title)
                .font(.headline)
            Text(activity.start.formatted(date: .abbreviated, time: .shortened))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(
                Measurement(value: activity.distanceMeters, unit: UnitLength.meters)
                    .formatted(.measurement(width: .abbreviated, usage: .road))
            )
            .font(.subheadline)
        }
    }
}

#Preview("Empty") {
    // try! is acceptable in previews only: a crash here just means a broken preview.
    ActivityListView(repository: ActivityRepository(try! AppDatabase.inMemory()))
}
