// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Moderation",
    platforms: [
        .iOS(.v26),
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "Moderation",
            targets: ["Moderation"]
        ),
    ],
    dependencies: [
        .package(path: "../DesignSystem"),
        .package(path: "../Networking")
    ],
    targets: [
        .target(
            name: "Moderation",
            dependencies: [
                "DesignSystem",
                "Networking"
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "ModerationTests",
            dependencies: ["Moderation"]
        ),
    ]
)