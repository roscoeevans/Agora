// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "UIKitBridge",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "UIKitBridge",
            targets: ["UIKitBridge"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "UIKitBridge",
            dependencies: [],
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug))
            ]
        ),
        .testTarget(
            name: "UIKitBridgeTests",
            dependencies: ["UIKitBridge"],
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug))
            ]
        ),
    ]
)