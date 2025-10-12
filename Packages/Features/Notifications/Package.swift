// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "Notifications",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "Notifications", targets: ["Notifications"])
    ],
    dependencies: [
        .package(path: "../../Kits/DesignSystem"),
        .package(path: "../../Kits/Networking"),
        .package(path: "../../Shared/AppFoundation")
    ],
    targets: [
        .target(
            name: "Notifications",
            dependencies: [
                "DesignSystem",
                "Networking",
                "AppFoundation"
            ]
        ),
        .testTarget(
            name: "NotificationsTests",
            dependencies: ["Notifications"]
        )
    ]
)