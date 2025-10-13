// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "AuthFeature",
    platforms: [
        .iOS(.v26),
        .macOS(.v15)
    ],
    products: [
        .library(name: "AuthFeature", targets: ["AuthFeature"])
    ],
    dependencies: [
        .package(path: "../../Kits/DesignSystem"),
        .package(path: "../../Kits/Networking"),
        .package(path: "../../Kits/Media"),
        .package(path: "../../Shared/AppFoundation")
    ],
    targets: [
        .target(
            name: "AuthFeature",
            dependencies: [
                "DesignSystem",
                "Networking",
                "Media",
                "AppFoundation"
            ],
            path: "Sources/Auth",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "AuthTests",
            dependencies: ["AuthFeature"],
            path: "Tests/AuthTests",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        )
    ]
)

