// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Analytics",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "Analytics",
            targets: ["Analytics"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Analytics",
            dependencies: [],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "AnalyticsTests",
            dependencies: ["Analytics"]
        ),
    ]
)