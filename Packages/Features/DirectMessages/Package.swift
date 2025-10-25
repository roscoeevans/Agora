// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "DirectMessages",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)
    ],
    products: [
        .library(
            name: "DirectMessages",
            targets: ["DirectMessages"]
        ),
    ],
    dependencies: [
        .package(path: "../../Kits/DesignSystem"),
        .package(path: "../../Shared/AppFoundation"),
        .package(path: "../../Kits/Media"),
        .package(path: "../../Kits/Analytics"),
        .package(path: "../../Kits/Moderation"),
        .package(path: "../../Kits/Persistence"),
        .package(path: "../../Shared/TestSupport")
    ],
    targets: [
        .target(
            name: "DirectMessages",
            dependencies: [
                "DesignSystem",
                "AppFoundation",
                "Media",
                "Analytics",
                "Moderation",
                "Persistence"
            ]
        ),
        .testTarget(
            name: "DirectMessagesTests",
            dependencies: [
                "DirectMessages",
                "TestSupport"
            ]
        ),
    ]
)