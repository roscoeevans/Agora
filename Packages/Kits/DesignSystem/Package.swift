// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "DesignSystem",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "DesignSystem", targets: ["DesignSystem"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "DesignSystem",
            dependencies: [],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "DesignSystemTests",
            dependencies: ["DesignSystem"]
        )
    ]
)
