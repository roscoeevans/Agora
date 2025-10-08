// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "HomeForYou",
    platforms: [
        .iOS(.v26),
        .macOS(.v10_15)
    ],
    products: [
        .library(name: "HomeForYou", targets: ["HomeForYou"])
    ],
    dependencies: [
        .package(path: "../../Kits/DesignSystem"),
        .package(path: "../../Kits/Networking"),
        .package(path: "../../Kits/Analytics"),
        .package(path: "../../Shared/AppFoundation")
    ],
    targets: [
        .target(
            name: "HomeForYou",
            dependencies: [
                "DesignSystem",
                "Networking", 
                "Analytics",
                "AppFoundation"
            ]
        ),
        .testTarget(
            name: "HomeForYouTests",
            dependencies: ["HomeForYou"]
        )
    ]
)
