// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Analytics",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)
    ],
    products: [
        .library(
            name: "Analytics",
            targets: ["Analytics"]
        ),
    ],
    dependencies: [
        .package(name: "AppFoundation", path: "../../Shared/AppFoundation"),
    ],
    targets: [
        .target(
            name: "Analytics",
            dependencies: [
                "AppFoundation",
            ],
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug)),
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "AnalyticsTests",
            dependencies: ["Analytics"],
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug))
            ]
        ),
    ]
)