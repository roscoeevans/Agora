// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "Notifications",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)  // Required to satisfy SPM dependency resolution
    ],
    products: [
        .library(name: "Notifications", targets: ["Notifications"])
    ],
    dependencies: [
        .package(path: "../../Kits/DesignSystem"),
        .package(path: "../../Kits/Networking"),
        .package(path: "../../Kits/UIKitBridge"),
        .package(path: "../../Shared/AppFoundation")
    ],
    targets: [
        .target(
            name: "Notifications",
            dependencies: [
                "DesignSystem",
                "Networking",
                "UIKitBridge",
                "AppFoundation"
            ],
            path: "Sources/Notifications",
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug))
            ]
        ),
        .testTarget(
            name: "NotificationsTests",
            dependencies: ["Notifications"],
            path: "Tests/NotificationsTests",
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug))
            ]
        )
    ]
)