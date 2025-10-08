// swift-tools-version: 6.2

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