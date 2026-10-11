// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "TripzKit",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "TripzKit", targets: ["TripzKit"])
    ],
    targets: [
        .target(name: "TripzKit", resources: [.process("Resources")]),
        .testTarget(name: "TripzKitTests", dependencies: ["TripzKit"]),
    ]
)
