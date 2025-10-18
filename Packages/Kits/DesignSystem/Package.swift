// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "DesignSystem",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "DesignSystem", targets: ["DesignSystem"])
    ],
    dependencies: [
        .package(path: "../../Shared/AppFoundation")
    ],
    targets: [
        .target(
            name: "DesignSystem",
            dependencies: ["AppFoundation"],
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
