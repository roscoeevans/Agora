// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Authentication",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)
    ],
    products: [
        .library(name: "Authentication", targets: ["Authentication"])
    ],
    dependencies: [
        .package(path: "../../Kits/DesignSystem"),
        .package(path: "../../Kits/Networking"),
        .package(path: "../../Kits/UIKitBridge"),
        .package(path: "../../Kits/Media"),
        .package(path: "../../Shared/AppFoundation")
    ],
    targets: [
        .target(
            name: "Authentication",
            dependencies: [
                "DesignSystem",
                "Networking",
                "UIKitBridge",
                "Media",
                "AppFoundation"
            ],
            path: "Sources/Authentication",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "AuthenticationTests",
            dependencies: ["Authentication"],
            path: "Tests/AuthenticationTests",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        )
    ]
)

