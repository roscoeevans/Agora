// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "PostDetail",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)  // Required to satisfy SPM dependency resolution
    ],
    products: [
        .library(name: "PostDetail", targets: ["PostDetail"])
    ],
    dependencies: [
        .package(path: "../../Kits/DesignSystem"),
        .package(path: "../../Kits/Networking"),
        .package(path: "../../Kits/UIKitBridge"),
        .package(path: "../../Kits/Verification"),
        .package(path: "../../Kits/Engagement"),
        .package(path: "../../Shared/AppFoundation")
    ],
    targets: [
        .target(
            name: "PostDetail",
            dependencies: [
                "DesignSystem",
                "Networking",
                "UIKitBridge",
                "Verification",
                "Engagement",
                "AppFoundation"
            ],
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug))
            ]
        ),
        .testTarget(
            name: "PostDetailTests",
            dependencies: ["PostDetail"],
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug))
            ]
        )
    ]
)