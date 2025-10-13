// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "Search",
    platforms: [.iOS(.v26), .macOS(.v15)],
    products: [
        .library(name: "Search", targets: ["Search"])
    ],
    dependencies: [
        .package(path: "../../Kits/DesignSystem"),
        .package(path: "../../Kits/Networking"),
        .package(path: "../../Shared/AppFoundation")
    ],
    targets: [
        .target(
            name: "Search",
            dependencies: [
                "DesignSystem",
                "Networking",
                "AppFoundation"
            ]
        ),
        .testTarget(
            name: "SearchTests",
            dependencies: ["Search"]
        )
    ]
)