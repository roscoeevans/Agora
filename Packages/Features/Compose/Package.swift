// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "Compose",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)  // High version to effectively disable macOS
    ],
    products: [
        .library(name: "Compose", targets: ["Compose"])
    ],
    dependencies: [
        .package(path: "../../Kits/DesignSystem"),
        .package(path: "../../Kits/Media"),
        .package(path: "../../Kits/Networking"),
        .package(path: "../../Kits/UIKitBridge"),
        .package(path: "../../Kits/Verification"),
        .package(path: "../../Shared/AppFoundation"),
        .package(path: "../Authentication")
    ],
    targets: [
        .target(
            name: "Compose",
            dependencies: [
                "DesignSystem",
                "Media",
                "Networking",
                "UIKitBridge",
                "Verification",
                "AppFoundation",
                "Authentication"
            ],
            path: "Sources/Compose",
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug))
            ]
        ),
        .testTarget(
            name: "ComposeTests",
            dependencies: ["Compose"],
            path: "Tests/ComposeTests",
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug))
            ]
        )
    ]
)