#if DEBUG
import Foundation
import TripzKit

enum SampleData {
    /// Synthetic hike roughly between Alpnachstad and Pilatus Kulm.
    /// Not a real trail: it only exists to develop the map screen.
    static func pilatusHike(now: Date = .now) -> Activity {
        let from = (lat: 46.9578, lon: 8.2744, elevation: 440.0)
        let to = (lat: 46.9786, lon: 8.2527, elevation: 2073.0)
        let count = 60
        let start = now.addingTimeInterval(-6 * 3600)

        let points = (0..<count).map { index -> TrackPoint in
            let t = Double(index) / Double(count - 1)
            let wobble = sin(t * 14) * 0.0006   // makes the line bend like a trail
            return TrackPoint(
                latitude: from.lat + (to.lat - from.lat) * t + wobble,
                longitude: from.lon + (to.lon - from.lon) * t - wobble,
                elevationMeters: from.elevation + (to.elevation - from.elevation) * t,
                timestamp: start.addingTimeInterval(t * 3 * 3600)
            )
        }

        return Activity(
            title: "Pilatus (sample)",
            start: start,
            durationSeconds: 3 * 3600,
            distanceMeters: 5200,
            elevationGainMeters: 1633,
            notes: "Synthetic data for development",
            route: Route(points: points)
        )
    }
}
#endif
