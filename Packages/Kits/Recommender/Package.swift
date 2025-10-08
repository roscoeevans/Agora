// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Recommender",
    platforms: [
        .iOS(.v26)
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
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "RecommenderTests",
            dependencies: ["Recommender"]
        ),
    ]
)