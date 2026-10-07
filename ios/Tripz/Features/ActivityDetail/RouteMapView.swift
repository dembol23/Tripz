import MapKit
import SwiftUI
import TripzKit

struct RouteMapView: View {
    let model: RouteMapModel
    let highlight: CLLocationCoordinate2D?
    
    var body: some View {
        Map(initialPosition: model.initialPosition) {
            MapPolyline(coordinates: model.coordinates)
                .stroke(.blue, lineWidth: 4)
            if let first = model.coordinates.first {
                Marker("Start", coordinate: first).tint(.green)
            }
            if let last = model.coordinates.last {
                Marker("End", coordinate: last).tint(.red)
            }
            if let highlight {
                Annotation("", coordinate: highlight) {
                    Circle()
                        .fill(.orange)
                        .frame(width: 16, height: 16)
                        .overlay(Circle().stroke(.white, lineWidth: 3))
                }
            }
        }
        .mapControls{
            MapCompass()
            MapScaleView()
            MapPitchToggle()
        }
        .mapControlVisibility(.visible)
        .safeAreaPadding(.top, 50)
    }
}

struct RouteMapModel {
    let coordinates: [CLLocationCoordinate2D]
    let initialPosition: MapCameraPosition
    
    init(points: [TrackPoint]) {
        let coordinates = points.map {
            CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
        }
        self.coordinates = coordinates
        self.initialPosition = .rect(Self.mapRect(fitting: coordinates))
    }
    
    private static func mapRect(fitting coordinates: [CLLocationCoordinate2D]) -> MKMapRect {
        let rect = coordinates.reduce(MKMapRect.null) { partial, coordinate in
            partial.union(MKMapRect(origin: MKMapPoint(coordinate), size: MKMapSize(width: 0, height: 0)))
        }
        return rect.insetBy(dx: -rect.width * 0.25, dy: -rect.height * 0.25)
    }
}
