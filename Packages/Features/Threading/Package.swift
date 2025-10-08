// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Threading",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "Threading", targets: ["Threading"])
    ],
    dependencies: [
        .package(path: "../../Kits/DesignSystem"),
        .package(path: "../../Kits/Networking"),
        .package(path: "../../Shared/AppFoundation")
    ],
    targets: [
        .target(
            name: "Threading",
            dependencies: [
                "DesignSystem",
                "Networking",
                "AppFoundation"
            ]
        ),
        .testTarget(
            name: "ThreadingTests",
            dependencies: ["Threading"]
        )
    ]
)