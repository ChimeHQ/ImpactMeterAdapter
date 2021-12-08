// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "ImpactMeterAdapter",
    platforms: [.macOS(.v10_13), .iOS(.v12), .tvOS(.v12)],
    products: [
        .library(name: "ImpactMeterAdapter", targets: ["ImpactMeterAdapter"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ChimeHQ/Meter", .branch("main")),
        .package(url: "https://github.com/ChimeHQ/Impact.git", from: "0.3.1"),
    ],
    targets: [
        .target(name: "ImpactMeterAdapter", dependencies: ["Impact", "Meter"]),
        .testTarget(name: "ImpactMeterAdapterTests",
                    dependencies: ["ImpactMeterAdapter"],
                    resources: [
                        .copy("Resources"),
                    ]),
    ]
)
