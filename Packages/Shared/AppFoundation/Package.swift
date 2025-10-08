// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "AppFoundation",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "AppFoundation",
            targets: ["AppFoundation"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "AppFoundation",
            dependencies: []
        ),
        .testTarget(
            name: "AppFoundationTests",
            dependencies: ["AppFoundation"]
        ),
    ]
)