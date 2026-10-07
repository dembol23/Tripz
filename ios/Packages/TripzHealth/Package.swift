// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "TripzHealth",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "TripzHealth", targets: ["TripzHealth"])
    ],
    dependencies: [
        .package(path: "../TripzKit"),
        .package(path: "../TripzStorage"),
    ],
    targets: [
        .target(
            name: "TripzHealth",
            dependencies: [
                .product(name: "TripzKit", package: "TripzKit"),
                .product(name: "TripzStorage", package: "TripzStorage"),
            ]
        ),
        .testTarget(
            name: "TripzHealthTests",
            dependencies: [
                "TripzHealth",
                .product(name: "TripzKit", package: "TripzKit"),
                .product(name: "TripzStorage", package: "TripzStorage"),
            ]
        ),
    ]
)
