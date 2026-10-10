import SwiftUI
import TripzHealth

struct HealthImportView: View {
    @State private var viewModel: HealthImportViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(importer: HealthImporter) {
        _viewModel = State(initialValue: HealthImportViewModel(importer: importer))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "figure.hiking")
                    .font(.system(size: 56))
                    .foregroundStyle(.tint)
                Text("Import hikes from Apple Health")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                
                content
            }
            .padding(24)
            .frame(maxHeight: .infinity)
            .toolbar{
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            Text("Tripz only reads your hiking workouts. It never changes your Health data.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("Import hikes") { Task { await viewModel.start() } }
                .buttonStyle(.borderedProminent)
        case .importing:
            ProgressView("Importing…")
        case .finished(let summary):
            Text(Self.message(for: summary))
                .multilineTextAlignment(.center)
            Button("Done") { dismiss() }
                .buttonStyle(.borderedProminent)
        case .failed(let message):
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("Try again") { Task { await viewModel.start() } }
                .buttonStyle(.bordered)
        }
    }
    
    private static func message(for summary: ImportSummary) -> String {
        guard summary.found > 0 else {
            // iOS hides whether read access was denied, so an empty result is ambiguous.
            return "No hikes found. If you expected some, check Tripz's access in the Health app (profile picture → Apps → Tripz)."
        }
        var lines: [String] = []
        if summary.imported > 0 {lines.append("Imported \(summary.imported) hike(s).")}
        if summary.routesAdded > 0 { lines.append("Added routes to \(summary.routesAdded) hike(s).") }
        if summary.skippedWithoutDistance > 0 {
            lines.append("\(summary.skippedWithoutDistance) skipped: no distance recorded.")
        }
        if lines.isEmpty { lines.append("Everything is already up to date.") }
        return lines.joined(separator: "\n")
    }
}
