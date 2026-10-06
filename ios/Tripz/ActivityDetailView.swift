import SwiftUI
import TripzKit
import TripzStorage

struct ActivityDetailView: View {
    @State private var viewModel: ActivityDetailViewModel
    
    init(activityId: UUID, repository: ActivityRepository) {
        _viewModel = State(initialValue: ActivityDetailViewModel(id: activityId, repository: repository))
    }
    
    var body: some View {
        content
            .navigationBarTitleDisplayMode(.inline)
            .task { await viewModel.load() }
    }
    
    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
        case .notFound:
            ContentUnavailableView("Activity not found", systemImage: "questionmark.folder")
        case .failed(let message):
            ContentUnavailableView(
                "Couldn't load activity",
                systemImage: "exclamationmark.triangle",
                description: Text(message)
            )
        case .loaded(let activity):
            ActivityDetailContent(activity: activity)
        }
    }
}

private struct ActivityDetailContent: View {
    let activity: Activity
    
    var body: some View {
        VStack(spacing: 0) {
            mapSection
                .frame(height: 320)
            List {
                LabeledContent("Date",
                    value: activity.start.formatted(date: .abbreviated, time: .shortened))
                LabeledContent("Distance",
                    value: Measurement(value: activity.distanceMeters, unit: UnitLength.meters)
                        .formatted(.measurement(width: .abbreviated, usage: .road)))
                LabeledContent("Duration",
                    value: Duration.seconds(activity.durationSeconds)
                        .formatted(.units(allowed: [.hours, .minutes], width: .abbreviated)))
                if let gain = activity.elevationGainMeters {
                    LabeledContent("Elevation gain",
                        value: Measurement(value: gain, unit: UnitLength.meters)
                            .formatted(.measurement(width: .abbreviated, usage: .asProvided)))
                }
                if !activity.notes.isEmpty {
                    Text(activity.notes)
                }
            }
        }
        .navigationTitle(activity.title)
    }

    @ViewBuilder
    private var mapSection: some View {
        if let route = activity.route, route.points.count >= 2 {
            RouteMapView(route: route)
        } else {
            ContentUnavailableView(
                "No route",
                systemImage: "map",
                description: Text("This activity has no recorded route.")
            )
        }
    }
}

