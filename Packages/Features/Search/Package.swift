// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Search",
    platforms: [.iOS(.v26)],
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