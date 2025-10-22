// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Recommender",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)
    ],
    products: [
        .library(
            name: "Recommender",
            targets: ["Recommender"]
        ),
    ],
    dependencies: [
        .package(path: "../Analytics"),
        .package(path: "../Networking")
    ],
    targets: [
        .target(
            name: "Recommender",
            dependencies: [
                "Analytics",
                "Networking"
            ],
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug)),
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "RecommenderTests",
            dependencies: ["Recommender"],
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug))
            ]
        ),
    ]
)