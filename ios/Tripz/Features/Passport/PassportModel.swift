import MapKit
import Observation
import TripzKit
import TripzStorage

struct HighlightedPolygon: Identifiable {
    let id: String
    let polygon: MKPolygon
}

@MainActor
@Observable
final class PassportModel {
    enum State {
        case loading
        case loaded([CountryVisit])
        case failed(String)
    }

    private(set) var state: State = .loading
    private(set) var highlights: [HighlightedPolygon] = []

    private let repository: ActivityRepository
    private var index: CountryIndex?

    init(repository: ActivityRepository) {
        self.repository = repository
    }

    var visits: [CountryVisit] {
        if case .loaded(let visits) = state { visits } else { [] }
    }

    func focusBounds(for code: String) -> GeoBounds? {
        index?.country(code: code)?.focusBounds
    }

    func refresh(summaries: [ActivitySummary]) async {
        do {
            let index = try await loadIndex()
            let sampled = try await repository.sampledRoutes(everyNth: 100)
            let trips = summaries.compactMap { summary -> Passport.Trip? in
                guard let points = sampled[summary.id] else { return nil }
                return Passport.Trip(start: summary.activity.start, points: points)
            }
            // The lookups take a moment: keep them off the main actor.
            let visits = await Task.detached(priority: .userInitiated) {
                Passport.visits(for: trips, in: index)
            }.value

            highlights = Self.polygons(for: visits, in: index)
            state = .loaded(visits)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    private func loadIndex() async throws -> CountryIndex {
        if let index { return index }
        let loaded = try await Task.detached(priority: .userInitiated) {
            try CountryIndex.bundled()
        }.value
        index = loaded
        return loaded
    }

    private static func polygons(for visits: [CountryVisit], in index: CountryIndex) -> [HighlightedPolygon] {
        visits.flatMap { visit -> [HighlightedPolygon] in
            guard let country = index.country(code: visit.code) else { return [] }
            return country.polygons.enumerated().map { offset, shape in
                HighlightedPolygon(id: "\(visit.code)-\(offset)", polygon: makePolygon(shape))
            }
        }
    }

    private static func makePolygon(_ shape: CountryPolygon) -> MKPolygon {
        func coordinates(_ ring: [GeoPoint]) -> [CLLocationCoordinate2D] {
            ring.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
        }
        let holes = shape.holes.map { hole -> MKPolygon in
            let ring = coordinates(hole)
            return MKPolygon(coordinates: ring, count: ring.count)
        }
        let outer = coordinates(shape.outer)
        return MKPolygon(coordinates: outer, count: outer.count, interiorPolygons: holes)
    }
}
