import Foundation
import Testing
@testable import TripzKit

struct ActivityTotalsTests {
    private func activity(distance: Double, duration: Double, gain: Double?) -> Activity {
        Activity(
            title: "Test",
            start: Date(timeIntervalSince1970: 0),
            durationSeconds: duration,
            distanceMeters: distance,
            elevationGainMeters: gain
        )
    }

    @Test func noActivitiesMeansZeroTotals() {
        let totals = ActivityTotals([])
        #expect(totals.count == 0)
        #expect(totals.distanceMeters == 0)
        #expect(totals.durationSeconds == 0)
        #expect(totals.elevationGainMeters == 0)
    }

    @Test func totalsAddUp() {
        let totals = ActivityTotals([
            activity(distance: 5_000, duration: 3_600, gain: 700),
            activity(distance: 10_000, duration: 7_200, gain: 300),
        ])
        #expect(totals.count == 2)
        #expect(totals.distanceMeters == 15_000)
        #expect(totals.durationSeconds == 10_800)
        #expect(totals.elevationGainMeters == 1_000)
    }

    @Test func unknownElevationCountsAsZero() {
        let totals = ActivityTotals([
            activity(distance: 1_000, duration: 600, gain: nil),
            activity(distance: 1_000, duration: 600, gain: 50),
        ])
        #expect(totals.elevationGainMeters == 50)
    }
}
