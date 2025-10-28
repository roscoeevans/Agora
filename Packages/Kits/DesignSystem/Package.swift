// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "DesignSystem",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)  // High version to effectively disable macOS
    ],
    products: [
        .library(name: "DesignSystem", targets: ["DesignSystem"])
    ],
    dependencies: [
        .package(path: "../../Shared/AppFoundation"),
        .package(path: "../UIKitBridge"),
        .package(path: "../Engagement"),
        .package(path: "../Media")
    ],
    targets: [
        .target(
            name: "DesignSystem",
            dependencies: [
                "AppFoundation",
                "UIKitBridge",
                "Engagement",
                "Media"
            ],
            resources: [.process("Resources")],
            swiftSettings: [
                // Ensure DEBUG is defined for this package in Debug config (needed for #if DEBUG blocks).
                .define("DEBUG", .when(configuration: .debug))
            ]
        ),
        .testTarget(
            name: "DesignSystemTests",
            dependencies: ["DesignSystem"],
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug))
            ]
        )
    ]
)
