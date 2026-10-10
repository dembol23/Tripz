import SwiftUI
import TripzKit
import TripzStorage

struct ActivityCardView: View {
    let summary: ActivitySummary
    let previews: RoutePreviewStore
    
    private var activity: Activity { summary.activity }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding([.horizontal, .top], 16)
                .padding(.bottom, 12)
            
            if summary.hasRoute {
                RoutePreview(activityId: activity.id, previews: previews)
            }
        }
        .background(Color(.darkGray))
        .cornerRadius(14)
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(activity.title)
                .font(.headline)
            HStack(spacing: 6) {
                Text(activity.start.formatted(date: .abbreviated, time: .shortened))
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }
    
    private var stats: some View {
        HStack(alignment: .top, spacing: 0) {
            stat("Distance", Formatting.distance(meters: activity.distanceMeters))
            stat("Time", Duration.seconds(activity.durationSeconds)
                            .formatted(.units(allowed: [.hours, .minutes], width: .narrow)))
            if let gain = activity.elevationGainMeters {
                stat("Elevation", Formatting.elevation(meters: gain))
            }
        }
    }
    
    private func stat(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.title3.weight(.semibold))
                .monospacedDigit()
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct RoutePreview: View {
    let activityId: UUID
    let previews: RoutePreviewStore
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var image: UIImage?
    @State private var didFail = false
    
    var body: some View {
        ZStack {
            Color(.tertiarySystemFill)
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if didFail {
                Image(systemName: "map")
                    .font(.title)
                    .foregroundStyle(.secondary)
            } else {
                ProgressView()
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(RoutePreviewStore.imageSize.width / RoutePreviewStore.imageSize.height, contentMode: .fit)
        .clipped()
        .task(id: colorScheme) {
            image = await previews.image(forActivity: activityId, colorScheme: colorScheme)
            didFail = image == nil
        }
    }
}
