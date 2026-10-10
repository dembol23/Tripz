import SwiftUI
import TripzKit
import TripzStorage

struct HikesView: View {
    let dependencies: AppDependencies
    @State private var isShowingImport = false

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("My Hikes")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Import from Health", systemImage: "heart.text.square") {
                            isShowingImport = true
                        }
                    }
                    #if DEBUG
                    ToolbarItem(placement: .secondaryAction) {
                        Button("Add sample", systemImage: "plus") {
                            Task { await dependencies.activities.addSampleActivity() }
                        }
                    }
                    #endif
                }
                .sheet(isPresented: $isShowingImport) {
                    HealthImportView(importer: dependencies.importer)
                }
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
            ContentUnavailableView {
                Label("No hikes yet", systemImage: "figure.hiking")
            } description: {
                Text("Import your hikes from Apple Health.")
            } actions: {
                Button("Import from Health") { isShowingImport = true }
                    .buttonStyle(.borderedProminent)
            }
        case .loaded(let summaries):
            List(summaries) { summary in
                NavigationLink(value: ActivityRoute(activityId: summary.id)) {
                    HikeRow(activity: summary.activity)
                }
            }
        }
    }
}

private struct HikeRow: View {
    let activity: Activity

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(activity.title)
                .font(.headline)
            Text(activity.start.formatted(date: .abbreviated, time: .omitted))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack(spacing: 14) {
                Label(Formatting.distance(meters: activity.distanceMeters), systemImage: "arrow.left.and.right")
                Label(
                    Duration.seconds(activity.durationSeconds)
                        .formatted(.units(allowed: [.hours, .minutes], width: .narrow)),
                    systemImage: "clock"
                )
                if let gain = activity.elevationGainMeters {
                    Label(Formatting.elevation(meters: gain), systemImage: "arrow.up.right")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}
