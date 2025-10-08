// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Verification",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "Verification",
            targets: ["Verification"]
        ),
    ],
    dependencies: [
        .package(path: "../Networking")
    ],
    targets: [
        .target(
            name: "Verification",
            dependencies: [
                "Networking"
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "VerificationTests",
            dependencies: ["Verification"]
        ),
    ]
)