import MapKit
import SwiftUI
import TripzKit

struct RouteMapView: View {
    private let coordinates: [CLLocationCoordinate2D]
    private let initialPosition: MapCameraPosition

    init(route: Route) {
        let coordinates = route.points.map {
            CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
        }
        self.coordinates = coordinates
        self.initialPosition = .rect(Self.mapRect(fitting: coordinates))
    }
    
    var body: some View {
        Map(initialPosition: initialPosition) {
            MapPolyline(coordinates: coordinates)
                .stroke(.blue, lineWidth: 4)
            if let first = coordinates.first {
                Marker("Start", coordinate: first).tint(.green)
            }
            if let last = coordinates.last {
                Marker("End", coordinate: last).tint(.red)
            }
        }
        .mapControls{
            MapCompass()
            MapScaleView()
        }
    }
    
    private static func mapRect(fitting coordinates: [CLLocationCoordinate2D]) -> MKMapRect {
        let rect = coordinates.reduce(MKMapRect.null) { partial, coordinate in
            partial.union(MKMapRect(origin: MKMapPoint(coordinate), size: MKMapSize(width: 0, height: 0)))
        }
        return rect.insetBy(dx: -rect.width * 0.25, dy: -rect.height * 0.25)
    }
}
