// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Moderation",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)
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
                .define("DEBUG", .when(configuration: .debug)),
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "ModerationTests",
            dependencies: ["Moderation"],
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug))
            ]
        ),
    ]
)