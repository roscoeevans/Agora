// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Persistence",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "Persistence",
            targets: ["Persistence"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Persistence",
            dependencies: [],
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug)),
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "PersistenceTests",
            dependencies: ["Persistence"],
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug))
            ]
        ),
    ]
)