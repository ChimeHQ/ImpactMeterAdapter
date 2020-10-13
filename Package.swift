// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "ImpactMeterAdapter",
    platforms: [.macOS(.v10_13), .iOS(.v12), .tvOS(.v12)],
    products: [
        .library(name: "ImpactMeterAdapter", targets: ["ImpactMeterAdapter"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ChimeHQ/Meter", from: "0.2.0"),
        .package(url: "https://github.com/ChimeHQ/Impact.git", from: "0.3.1"),
    ],
    targets: [
        .target(name: "ImpactMeterAdapter", dependencies: ["Impact", "Meter"], path: "ImpactMeterAdapter/"),
        .testTarget(name: "ImpactMeterAdapterTests", dependencies: ["ImpactMeterAdapter"], path: "ImpactMeterAdapterTests/"),
    ]
)
