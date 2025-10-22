// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "Threading",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)  // Required to satisfy SPM dependency resolution
    ],
    products: [
        .library(name: "Threading", targets: ["Threading"])
    ],
    dependencies: [
        .package(path: "../../Kits/DesignSystem"),
        .package(path: "../../Kits/Networking"),
        .package(path: "../../Shared/AppFoundation")
    ],
    targets: [
        .target(
            name: "Threading",
            dependencies: [
                "DesignSystem",
                "Networking",
                "AppFoundation"
            ],
            path: "Sources/Threading",
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug))
            ]
        ),
        .testTarget(
            name: "ThreadingTests",
            dependencies: ["Threading"],
            path: "Tests/ThreadingTests",
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug))
            ]
        )
    ]
)