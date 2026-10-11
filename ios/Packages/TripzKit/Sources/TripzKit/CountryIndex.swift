import Foundation

public struct CountryIndex: Sendable {
    public static let coastalToleranceMeters = 10_000.0

    public let countries: [Country]
    private let byCode: [String: Country]

    public init(countries: [Country]) {
        self.countries = countries
        self.byCode = Dictionary(countries.map { ($0.code, $0) }, uniquingKeysWith: { first, _ in first })
    }

    public func country(code: String) -> Country? { byCode[code] }

    public func countryCode(latitude: Double, longitude: Double) -> String? {
        for country in countries {
            for polygon in country.polygons
            where polygon.contains(latitude: latitude, longitude: longitude) {
                return country.code
            }
        }

        var best: (code: String, meters: Double)?
        for country in countries {
            for polygon in country.polygons
            where polygon.isNear(latitude: latitude, longitude: longitude, meters: Self.coastalToleranceMeters) {
                let meters = polygon.distanceMeters(latitude: latitude, longitude: longitude)
                if meters <= Self.coastalToleranceMeters, meters < (best?.meters ?? .infinity) {
                    best = (country.code, meters)
                }
            }
        }
        return best?.code
    }

    public func countryCodes(visitedBy points: [TrackPoint]) -> Set<String> {
        var codes: Set<String> = []
        for point in points {
            if let code = countryCode(latitude: point.latitude, longitude: point.longitude) {
                codes.insert(code)
            }
        }
        return codes
    }
}

extension CountryIndex {
    public enum LoadError: Error, Equatable {
        case missingResource
        case unsupportedVersion(Int)
        case malformedRing
    }

    public static func bundled() throws -> CountryIndex {
        guard let url = Bundle.module.url(forResource: "countries", withExtension: "json") else {
            throw LoadError.missingResource
        }
        return try CountryIndex(jsonData: Data(contentsOf: url))
    }

    public init(jsonData: Data) throws {
        let file = try JSONDecoder().decode(CountryFile.self, from: jsonData)
        guard file.version == 1 else { throw LoadError.unsupportedVersion(file.version) }

        var countries: [Country] = []
        for entry in file.countries {
            var polygons: [CountryPolygon] = []
            for rings in entry.polygons {
                let converted = try rings.map { try Self.ring($0, scale: file.scale) }
                if let outer = converted.first,
                   let polygon = CountryPolygon(outer: outer, holes: Array(converted.dropFirst())) {
                    polygons.append(polygon)
                }
            }
            if let country = Country(code: entry.code, polygons: polygons) {
                countries.append(country)
            }
        }
        self.init(countries: countries)
    }

    private static func ring(_ flat: [Int], scale: Double) throws -> [GeoPoint] {
        guard flat.count % 2 == 0 else { throw LoadError.malformedRing }
        return stride(from: 0, to: flat.count, by: 2).map {
            GeoPoint(latitude: Double(flat[$0 + 1]) / scale, longitude: Double(flat[$0]) / scale)
        }
    }
}

private struct CountryFile: Decodable {
    struct Entry: Decodable {
        let code: String
        let polygons: [[[Int]]]
    }
    let version: Int
    let scale: Double
    let countries: [Entry]
}
