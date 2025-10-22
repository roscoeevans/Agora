// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "agctl",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "agctl", targets: ["agctl"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0")
    ],
    targets: [
        .executableTarget(
            name: "agctl",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            path: "Sources/agctl"
        ),
        .testTarget(
            name: "agctlTests",
            dependencies: ["agctl"],
            path: "Tests/agctlTests"
        )
    ]
)

