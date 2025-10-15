// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "Home",
    platforms: [
        .iOS(.v26),
        .macOS(.v10_15)
    ],
    products: [
        .library(name: "Home", targets: ["Home"])
    ],
    dependencies: [
        .package(path: "../../Kits/DesignSystem"),
        .package(path: "../HomeForYou"),
        .package(path: "../HomeFollowing"),
        .package(path: "../Compose")
    ],
    targets: [
        .target(
            name: "Home",
            dependencies: ["DesignSystem", "HomeForYou", "HomeFollowing", "Compose"]
        ),
        .testTarget(
            name: "HomeTests",
            dependencies: ["Home"]
        )
    ]
)
