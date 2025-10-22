// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Verification",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)
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
                .define("DEBUG", .when(configuration: .debug)),
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "VerificationTests",
            dependencies: ["Verification"],
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug))
            ]
        ),
    ]
)