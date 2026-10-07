import SwiftUI
import TripzKit
import TripzStorage
import TripzHealth

struct ActivityListView: View {
    @State private var viewModel: ActivityListViewModel
    private let repository: ActivityRepository
    private let importer: HealthImporter
    @State private var isShowingImport = false
    
    init(repository: ActivityRepository, importer: HealthImporter) {
        _viewModel = State(initialValue: ActivityListViewModel(repository: repository))
        self.repository = repository
        self.importer = importer
        _viewModel = State(initialValue: ActivityListViewModel(repository: repository))
    }
    
    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Activities")
                .toolbar {
//                #if DEBUG
//                    Button("Add sample", systemImage: "plus") {
//                        Task { await viewModel.addSampleActivity() }
//                    }
//                #endif
                    ToolbarItem(placement: .primaryAction) {
                        Button("Import from Health", systemImage: "heart.text.square") {
                            isShowingImport = true
                        }
                    }
                }
                .sheet(isPresented: $isShowingImport) {
                    HealthImportView(importer: importer){ await viewModel.load() }
                }

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
                    NavigationLink {
                        ActivityDetailView(activityId: activity.id, repository: repository)
                    } label: {
                        ActivityRow(activity: activity)
                    }
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
                Formatting.distance(meters: activity.distanceMeters)
            )
            .font(.subheadline)
        }
    }
}

//#Preview("Empty") {
//    // try! is acceptable in previews only: a crash here just means a broken preview.
//    ActivityListView(repository: ActivityRepository(try! AppDatabase.inMemory()))
//}
