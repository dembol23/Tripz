import Foundation
import Testing
@testable import TripzKit

struct ActivityTests {
    private func makeActivity() -> Activity {
        Activity(
            title: "Pilatus",
            start: Date(timeIntervalSince1970: 0),
            durationSeconds: 3600,
            distanceMeters: 5000
        )
    }
    
    @Test func manualActivityDefaults() {
        let activity = makeActivity()
        #expect(activity.type == .hiking)
        #expect(activity.source == .manual)
        #expect(activity.route == nil)
        #expect(activity.elevationGainMeters == nil)
        #expect(activity.notes.isEmpty)
    }
    
    @Test func eachActivityGetsUniqueId() {
        #expect(makeActivity().id != makeActivity().id)
    }
}
