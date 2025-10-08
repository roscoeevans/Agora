// swift-tools-version: 6.2
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
        .package(path: "../HomeFollowing")
    ],
    targets: [
        .target(
            name: "Home",
            dependencies: ["DesignSystem", "HomeForYou", "HomeFollowing"]
        ),
        .testTarget(
            name: "HomeTests",
            dependencies: ["Home"]
        )
    ]
)
