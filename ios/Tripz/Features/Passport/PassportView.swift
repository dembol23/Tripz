import MapKit
import SwiftUI
import TripzKit
import TripzStorage

struct PassportView: View {
    let dependencies: AppDependencies

    @State private var position = MapCameraPosition.camera(
        MapCamera(centerCoordinate: CLLocationCoordinate2D(latitude: 30, longitude: 10), distance: 25_000_000)
    )
    @State private var hasCentered = false

    private struct ActivityKey: Hashable {
        let id: UUID
        let hasRoute: Bool
    }

    private var passport: PassportModel { dependencies.passport }

    private var activityKeys: [ActivityKey]? {
        guard case .loaded(let summaries) = dependencies.activities.state else { return nil }
        return summaries.map { ActivityKey(id: $0.id, hasRoute: $0.hasRoute) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                globe
                    .frame(height: 340)
                visitedList
            }
            .navigationTitle("Passport")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task(id: activityKeys) {
            guard case .loaded(let summaries) = dependencies.activities.state else { return }
            await passport.refresh(summaries: summaries)
            if !hasCentered, let latest = passport.visits.first {
                hasCentered = true
                focus(on: latest.code, framing: .globe)
            }
        }
    }

    private var globe: some View {
        Map(position: $position) {
            ForEach(passport.highlights) { highlight in
                MapPolygon(highlight.polygon)
                    .foregroundStyle(Color.blue.opacity(0.35))
                    .stroke(.blue, lineWidth: 1)
            }
        }
        .mapStyle(.imagery(elevation: .realistic))
    }

    @ViewBuilder
    private var visitedList: some View {
        switch passport.state {
        case .loading:
            ProgressView().frame(maxHeight: .infinity)
        case .failed(let message):
            ContentUnavailableView(
                "Couldn't build your passport",
                systemImage: "exclamationmark.triangle",
                description: Text(message)
            )
        case .loaded(let visits) where visits.isEmpty:
            ContentUnavailableView(
                "No countries yet",
                systemImage: "globe.europe.africa",
                description: Text("Hikes with a recorded route will add their country here.")
            )
        case .loaded(let visits):
            List {
                Section("\(visits.count) \(visits.count == 1 ? "country" : "countries")") {
                    ForEach(visits) { visit in
                        Button { focus(on: visit.code, framing: .country) } label: {
                            CountryRow(visit: visit)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .listStyle(.plain)
        }
    }

    private enum Framing { case globe, country }

    private func focus(on code: String, framing: Framing) {
        guard let bounds = passport.focusBounds(for: code) else { return }
        let center = CLLocationCoordinate2D(latitude: bounds.centerLatitude, longitude: bounds.centerLongitude)
        let distance: Double = switch framing {
        case .globe: 18_000_000
        case .country: max(bounds.approximateDiagonalMeters, 200_000) * 2.2   // tuning knob
        }
        withAnimation(.easeInOut(duration: 1.2)) {
            position = .camera(MapCamera(centerCoordinate: center, distance: distance))
        }
    }
}

private struct CountryRow: View {
    let visit: CountryVisit

    var body: some View {
        HStack(spacing: 12) {
            Text(CountryDisplay.flag(for: visit.code))
                .font(.largeTitle)
            VStack(alignment: .leading, spacing: 2) {
                Text(CountryDisplay.name(for: visit.code))
                    .font(.headline)
                Text("\(visit.activityCount) \(visit.activityCount == 1 ? "hike" : "hikes") · last \(visit.lastVisit.formatted(date: .abbreviated, time: .omitted))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .contentShape(Rectangle())
    }
}
