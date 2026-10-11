import Foundation

public struct CountryVisit: Identifiable, Equatable, Sendable {
    public let code: String
    public let activityCount: Int
    public let lastVisit: Date
    public var id: String { code }
}

public enum Passport {
    public struct Trip: Sendable {
        public let start: Date
        public let points: [TrackPoint]
        
        public init(start: Date, points: [TrackPoint]) {
            self.start = start
            self.points = points
        }
    }
    
    public static func visits(for trips: [Trip], in index: CountryIndex) -> [CountryVisit] {
        var counts: [String: Int] = [:]
        var lastVisits: [String: Date] = [:]
        for trip in trips {
            for code in index.countryCodes(visitedBy: trip.points) {
                counts[code, default: 0] += 1
                lastVisits[code] = max(lastVisits[code] ?? trip.start, trip.start)
            }
        }
        return counts
            .map { CountryVisit(code: $0.key, activityCount: $0.value, lastVisit: lastVisits[$0.key] ?? .distantPast) }
            .sorted { $0.lastVisit != $1.lastVisit ? $0.lastVisit > $1.lastVisit : $0.code < $1.code }
   }
}
