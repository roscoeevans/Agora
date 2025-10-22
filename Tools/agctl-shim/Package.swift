// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "agctl-shim",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "agctl-shim", targets: ["agctl-shim"])
    ],
    targets: [
        .executableTarget(
            name: "agctl-shim",
            dependencies: [],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        )
    ]
)

