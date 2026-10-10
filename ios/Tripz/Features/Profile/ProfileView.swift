import SwiftUI
import TripzKit
import TripzStorage

struct ProfileView: View {
    let dependencies: AppDependencies

    var body: some View {
        NavigationStack {
            List {
                if case .loaded(let summaries) = dependencies.activities.state {
                    totalsSection(ActivityTotals(summaries.map(\.activity)))
                }
                Section("About") {
                    LabeledContent("Version", value: appVersion)
                }
            }
            .navigationTitle("Profile")
        }
    }

    private func totalsSection(_ totals: ActivityTotals) -> some View {
        Section("Totals") {
            LabeledContent("Activities", value: "\(totals.count)")
            LabeledContent("Distance", value: Formatting.distance(meters: totals.distanceMeters))
            LabeledContent(
                "Time",
                value: Duration.seconds(totals.durationSeconds)
                    .formatted(.units(allowed: [.hours, .minutes], width: .abbreviated))
            )
            LabeledContent("Elevation gain", value: Formatting.elevation(meters: totals.elevationGainMeters))
        }
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "–"
    }
}
