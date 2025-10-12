// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "AgoraAuth",
    platforms: [
        .iOS(.v26),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "AgoraAuth",
            targets: ["AgoraAuth"]
        ),
    ],
    dependencies: [
        .package(path: "../../Shared/AppFoundation"),
        .package(name: "TestSupport", path: "../../Shared/TestSupport"),
    ],
    targets: [
        .target(
            name: "AgoraAuth",
            dependencies: [
                "AppFoundation"
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "AuthTests",
            dependencies: [
                "AgoraAuth",
                .product(name: "TestSupport", package: "TestSupport")
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
    ]
)