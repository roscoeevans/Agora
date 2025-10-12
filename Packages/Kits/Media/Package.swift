// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Media",
    platforms: [
        .iOS(.v26),
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "Media",
            targets: ["Media"]
        ),
    ],
    dependencies: [
        .package(path: "../Networking")
    ],
    targets: [
        .target(
            name: "Media",
            dependencies: [
                "Networking"
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "MediaTests",
            dependencies: ["Media"]
        ),
    ]
)