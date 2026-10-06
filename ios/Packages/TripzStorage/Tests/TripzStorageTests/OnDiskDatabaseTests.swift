import Foundation
import Testing
import TripzKit
@testable import TripzStorage

struct OnDiskDatabaseTests {
    @Test func dataSurvivesReopeningTheFile() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("test.sqlite")

        let activity = Activity(
            title: "Pilatus",
            start: Date(timeIntervalSince1970: 1_000_000),
            durationSeconds: 3600,
            distanceMeters: 5000
        )

        try await ActivityRepository(AppDatabase.onDisk(at: url)).save(activity)

        let reopened = try await ActivityRepository(AppDatabase.onDisk(at: url))
            .activity(id: activity.id)
        #expect(reopened == activity)
    }
}
