// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "Compose",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "Compose", targets: ["Compose"])
    ],
    dependencies: [
        .package(path: "../../Kits/DesignSystem"),
        .package(path: "../../Kits/Media"),
        .package(path: "../../Kits/Networking"),
        .package(path: "../../Kits/Verification"),
        .package(path: "../../Shared/AppFoundation")
    ],
    targets: [
        .target(
            name: "Compose",
            dependencies: [
                "DesignSystem",
                "Media",
                "Networking",
                "Verification",
                "AppFoundation"
            ]
        ),
        .testTarget(
            name: "ComposeTests",
            dependencies: ["Compose"]
        )
    ]
)