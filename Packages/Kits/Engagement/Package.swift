// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Engagement",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "Engagement", targets: ["Engagement"]),
    ],
    dependencies: [
        .package(path: "../Networking"),
        .package(path: "../Analytics"),
        .package(path: "../../Shared/AppFoundation"),
    ],
    targets: [
        .target(
            name: "Engagement",
            dependencies: [
                "Networking",
                "Analytics",
                "AppFoundation"
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "EngagementTests",
            dependencies: ["Engagement"]
        ),
    ]
)

