// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "TripzStorage",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "TripzStorage", targets: ["TripzStorage"])
    ],
    dependencies: [
        .package(path: "../TripzKit"),
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "7.0.0"),
    ],
    targets: [
        .target(
            name: "TripzStorage",
            dependencies: [
                .product(name: "TripzKit", package: "TripzKit"),
                .product(name: "GRDB", package: "GRDB.swift"),
            ]
        ),
        .testTarget(name: "TripzStorageTests", dependencies: ["TripzStorage"]),
    ]
)
