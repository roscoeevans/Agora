// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "HomeForYou",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)  // Required to satisfy SPM dependency resolution
    ],
    products: [
        .library(name: "HomeForYou", targets: ["HomeForYou"])
    ],
    dependencies: [
        .package(path: "../../Kits/DesignSystem"),
        .package(path: "../../Kits/Networking"),
        .package(path: "../../Kits/Analytics"),
        .package(path: "../../Shared/AppFoundation"),
        .package(path: "../../Shared/TestSupport"),
        .package(path: "../PostDetail")
    ],
    targets: [
        .target(
            name: "HomeForYou",
            dependencies: [
                "DesignSystem",
                "Networking", 
                "Analytics",
                "AppFoundation",
                "PostDetail"
            ],
            path: "Sources/HomeForYou",
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug))
            ]
        ),
        .testTarget(
            name: "HomeForYouTests",
            dependencies: [
                "HomeForYou",
                "TestSupport"
            ],
            path: "Tests/HomeForYouTests",
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug))
            ]
        )
    ]
)
