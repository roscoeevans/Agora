// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "TestSupport",
    platforms: [
        .iOS(.v26),
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "TestSupport",
            targets: ["TestSupport"]
        ),
    ],
    dependencies: [
        .package(path: "../AppFoundation"),
        .package(url: "https://github.com/apple/swift-openapi-runtime", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "TestSupport",
            dependencies: [
                "AppFoundation",
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime")
            ]
        ),
        .testTarget(
            name: "TestSupportTests",
            dependencies: ["TestSupport"]
        ),
    ]
)