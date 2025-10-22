// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "DMs",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)  // Required to satisfy SPM dependency resolution
    ],
    products: [
        .library(name: "DMs", targets: ["DMs"])
    ],
    dependencies: [
        .package(path: "../../Kits/DesignSystem"),
        .package(path: "../../Kits/Networking"),
        .package(path: "../../Kits/Media"),
        .package(path: "../../Shared/AppFoundation")
    ],
    targets: [
        .target(
            name: "DMs",
            dependencies: [
                "DesignSystem",
                "Networking",
                "Media",
                "AppFoundation"
            ],
            path: "Sources/DMs",
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug))
            ]
        ),
        .testTarget(
            name: "DMsTests",
            dependencies: ["DMs"],
            path: "Tests/DMsTests",
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug))
            ]
        )
    ]
)