import MapKit
import SwiftUI
import TripzKit
import TripzStorage
import UIKit

actor RoutePreviewStore {
    static let imageSize = CGSize(width: 360, height: 200)

    private let repository: ActivityRepository
    private let cache = NSCache<NSString, UIImage>()

    init(repository: ActivityRepository) {
        self.repository = repository
        cache.countLimit = 60
    }

    func image(forActivity id: UUID, colorScheme: ColorScheme) async -> UIImage? {
        let key = "\(id.uuidString)-\(colorScheme == .dark ? "dark" : "light")" as NSString
        if let cached = cache.object(forKey: key) { return cached }

        guard let route = try? await repository.route(forActivity: id),
              let image = await Self.render(route, colorScheme: colorScheme) else { return nil }
        cache.setObject(image, forKey: key)
        return image
    }

    private static func render(_ route: Route, colorScheme: ColorScheme) async -> UIImage? {
        guard route.points.count >= 2, let bounds = GeoBounds(points: route.points) else { return nil }

        let tolerance = max(bounds.approximateDiagonalMeters / 300, 3)
        let points = RouteSimplifier.simplify(route.points, toleranceMeters: tolerance)

        let options = MKMapSnapshotter.Options()
        options.region = region(fitting: bounds)
        options.size = imageSize
        options.traitCollection = UITraitCollection(userInterfaceStyle: colorScheme == .dark ? .dark : .light)
        let configuration = MKStandardMapConfiguration(elevationStyle: .flat, emphasisStyle: .muted)
        configuration.pointOfInterestFilter = .excludingAll
        options.preferredConfiguration = configuration

        let snapshotter = MKMapSnapshotter(options: options)
        guard let snapshot = try? await snapshotter.start() else { return nil }

        let format = UIGraphicsImageRendererFormat()
        format.scale = snapshot.image.scale
        return UIGraphicsImageRenderer(size: imageSize, format: format).image { _ in
            snapshot.image.draw(at: .zero)

            let positions = points.map {
                snapshot.point(for: CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude))
            }
            let path = UIBezierPath()
            for (index, position) in positions.enumerated() {
                if index == 0 { path.move(to: position) } else { path.addLine(to: position) }
            }
            path.lineCapStyle = .round
            path.lineJoinStyle = .round
            path.lineWidth = 6
            UIColor.white.withAlphaComponent(0.85).setStroke()
            path.stroke()
            path.lineWidth = 3.5
            UIColor.systemBlue.setStroke()
            path.stroke()

            if let first = positions.first { dot(at: first, color: .systemGreen) }
            if let last = positions.last { dot(at: last, color: .systemRed) }
        }
    }

    private static func region(fitting bounds: GeoBounds) -> MKCoordinateRegion {
        let minimumSpan = 0.005
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: bounds.centerLatitude, longitude: bounds.centerLongitude),
            span: MKCoordinateSpan(
                latitudeDelta: max(bounds.latitudeSpan * 1.4, minimumSpan),
                longitudeDelta: max(bounds.longitudeSpan * 1.4, minimumSpan)
            )
        )
    }

    private static func dot(at point: CGPoint, color: UIColor) {
        let rect = CGRect(x: point.x - 5, y: point.y - 5, width: 10, height: 10)
        UIColor.white.setFill()
        UIBezierPath(ovalIn: rect.insetBy(dx: -2, dy: -2)).fill()
        color.setFill()
        UIBezierPath(ovalIn: rect).fill()
    }
}
