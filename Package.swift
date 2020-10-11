// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "ImpactMeterAdapter",
    platforms: [.macOS(.v10_13), .iOS(.v12), .tvOS(.v12)],
    products: [
        .library(name: "ImpactMeterAdapter", targets: ["ImpactMeterAdapter"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ChimeHQ/Meter", .branch("main")),
        .package(url: "https://github.com/ChimeHQ/Impact.git", .branch("main")),
    ],
    targets: [
        .target(name: "ImpactMeterAdapter", dependencies: ["Impact", "Meter"], path: "ImpactMeterAdapter/"),
        .testTarget(name: "ImpactMeterAdapterTests", dependencies: ["ImpactMeterAdapter"], path: "ImpactMeterAdapterTests/"),
    ]
)
