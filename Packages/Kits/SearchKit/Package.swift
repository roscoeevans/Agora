// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SearchKit",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)
    ],
    products: [
        .library(
            name: "SearchKit",
            targets: ["SearchKit"]
        ),
    ],
    dependencies: [
        .package(name: "AppFoundation", path: "../../Shared/AppFoundation"),
    ],
    targets: [
        .target(
            name: "SearchKit",
            dependencies: [
                "AppFoundation",
            ],
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug)),
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "SearchKitTests",
            dependencies: ["SearchKit"]
        ),
    ]
)



