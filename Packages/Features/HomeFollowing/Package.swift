// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "HomeFollowing",
    platforms: [
        .iOS(.v26),
        .macOS(.v10_15)
    ],
    products: [
        .library(name: "HomeFollowing", targets: ["HomeFollowing"])
    ],
    dependencies: [
        .package(path: "../../Kits/DesignSystem"),
        .package(path: "../../Kits/Networking"),
        .package(path: "../../Kits/Analytics"),
        .package(path: "../../Shared/AppFoundation")
    ],
    targets: [
        .target(
            name: "HomeFollowing",
            dependencies: [
                "DesignSystem",
                "Networking", 
                "Analytics",
                "AppFoundation"
            ],
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug))
            ]
        ),
        .testTarget(
            name: "HomeFollowingTests",
            dependencies: ["HomeFollowing"],
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug))
            ]
        )
    ]
)