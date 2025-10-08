// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Auth",
    platforms: [
        .iOS(.v26),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "Auth",
            targets: ["Auth"]
        ),
    ],
    dependencies: [
        .package(path: "../../Shared/AppFoundation"),
        .package(name: "TestSupport", path: "../../Shared/TestSupport"),
    ],
    targets: [
        .target(
            name: "Auth",
            dependencies: [
                "AppFoundation"
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "AuthTests",
            dependencies: [
                "Auth",
                .product(name: "TestSupport", package: "TestSupport")
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
    ]
)