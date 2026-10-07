import Charts
import SwiftUI
import TripzKit

struct ElevationChartView: View {
    let samples: [ElevationSample]
    @Binding var selectedDistance: Double?
    
    var body: some View {
        Chart{
            ForEach(Array(samples.enumerated()), id: \.offset) { _, sample in
                AreaMark(
                    x: .value("Distance", sample.distanceMeters),
                    y: .value("Elevation", sample.elevationMeters)
                )
                .foregroundStyle(.blue.opacity(0.2))
                LineMark(
                    x: .value("Distance", sample.distanceMeters),
                    y: .value("Elevation", sample.elevationMeters)
                )
                .foregroundStyle(.blue)
            }
            if let selectedDistance {
                RuleMark(x: .value("Selected", selectedDistance))
                    .foregroundStyle(.orange)
            }
        }
        .chartXSelection(value: $selectedDistance)
        .chartYScale(domain: .automatic(includesZero: false))
        .chartXAxis{
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel {
                    if let meters = value.as(Double.self) {
                        Text(Measurement(value: meters, unit: UnitLength.meters)
                            .formatted(.measurement(width: .abbreviated, usage: .road)))
                    }
                }
            }
        }
        .frame(height: 160)
    }
}
