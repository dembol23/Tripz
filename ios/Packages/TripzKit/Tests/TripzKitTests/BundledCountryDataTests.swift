import Testing
@testable import TripzKit

struct BundledCountryDataTests {
    struct Place: Sendable, CustomTestStringConvertible {
        let name: String
        let latitude: Double
        let longitude: Double
        let code: String
        var testDescription: String { name }
    }

    // try! is fine in tests: a missing resource should fail loudly.
    private static let index: CountryIndex = { try! CountryIndex.bundled() }()

    static let places: [Place] = [
        Place(name: "Zurich", latitude: 47.3769, longitude: 8.5417, code: "CH"),
        Place(name: "Alpnachstad", latitude: 46.9578, longitude: 8.2744, code: "CH"),
        Place(name: "Wroclaw", latitude: 51.1079, longitude: 17.0385, code: "PL"),
        Place(name: "Zakopane", latitude: 49.2992, longitude: 19.9496, code: "PL"),
        Place(name: "Paris", latitude: 48.8566, longitude: 2.3522, code: "FR"),
        Place(name: "Oslo", latitude: 59.9139, longitude: 10.7522, code: "NO"),
        Place(name: "Longyearbyen", latitude: 78.2232, longitude: 15.6267, code: "NO"),
        Place(name: "Tokyo", latitude: 35.6762, longitude: 139.6503, code: "JP"),
        Place(name: "Maseru, an enclave in South Africa", latitude: -29.3167, longitude: 27.4833, code: "LS"),
        Place(name: "Johannesburg", latitude: -26.2041, longitude: 28.0473, code: "ZA"),
        Place(name: "Reykjavik", latitude: 64.1466, longitude: -21.9426, code: "IS"),
        Place(name: "Honolulu", latitude: 21.3069, longitude: -157.8583, code: "US"),
        Place(name: "Vladivostok", latitude: 43.1155, longitude: 131.8855, code: "RU"),
        Place(name: "San Marino", latitude: 43.9424, longitude: 12.4578, code: "SM"),
        Place(name: "Singapore", latitude: 1.3521, longitude: 103.8198, code: "SG"),
        Place(name: "Kathmandu", latitude: 27.7172, longitude: 85.3240, code: "NP"),
        // Coastal cities that only resolve through the offshore fallback:
        Place(name: "Suva", latitude: -18.1416, longitude: 178.4415, code: "FJ"),
        Place(name: "Nuuk", latitude: 64.1835, longitude: -51.7216, code: "GL"),
        Place(name: "New York", latitude: 40.7128, longitude: -74.0060, code: "US"),
        Place(name: "Anadyr, east of the date line", latitude: 64.7337, longitude: 177.5159, code: "RU"),
        Place(name: "Uelen, west of the date line", latitude: 66.16, longitude: -169.8, code: "RU"),
    ]

    @Test(arguments: places)
    func knownPlaceResolvesToItsCountry(place: Place) {
        #expect(Self.index.countryCode(latitude: place.latitude, longitude: place.longitude) == place.code)
    }

    @Test func theMiddleOfTheAtlanticIsInNoCountry() {
        #expect(Self.index.countryCode(latitude: 0, longitude: -30) == nil)
    }

    @Test func countriesWithBrokenPlainIsoCodesArePresent() {
        // The plain ISO field is -99 for these in Natural Earth.
        #expect(Self.index.country(code: "FR") != nil)
        #expect(Self.index.country(code: "NO") != nil)
        #expect(Self.index.country(code: "XK") != nil)
        #expect(Self.index.countries.count > 230)
    }

    @Test func aRouteAcrossTheSwissItalianBorderReportsBoth() {
        let route = [
            TrackPoint(latitude: 47.3769, longitude: 8.5417),   // Zurich
            TrackPoint(latitude: 45.4642, longitude: 9.1900),   // Milan
        ]
        #expect(Self.index.countryCodes(visitedBy: route) == ["CH", "IT"])
    }
}
