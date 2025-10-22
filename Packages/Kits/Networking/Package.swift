// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Networking",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)
    ],
    products: [
        .library(
            name: "Networking",
            targets: ["Networking"]
        )
    ],
    dependencies: [
        // Apple OpenAPI runtime + URLSession transport + HTTP types
        .package(url: "https://github.com/apple/swift-openapi-runtime", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-openapi-urlsession", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-http-types", from: "1.0.0"),

        // Your internal modules
        .package(path: "../../Shared/AppFoundation")
    ],
    targets: [
        .target(
            name: "Networking",
            dependencies: [
                // OpenAPI runtime + transport + http header types
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "OpenAPIURLSession", package: "swift-openapi-urlsession"),
                .product(name: "HTTPTypes", package: "swift-http-types"),

                // Internal dependencies
                "AppFoundation"
            ],
            path: "Sources/Networking",
            swiftSettings: [
                // Define DEBUG for #if DEBUG blocks (previews, debug-only code)
                .define("DEBUG", .when(configuration: .debug)),
                // Define STAGING for debug builds (staging and development environments)
                .define("STAGING", .when(configuration: .debug)),
                .define("DEVELOPMENT", .when(configuration: .debug))
            ]
        ),
        .testTarget(
            name: "NetworkingTests",
            dependencies: ["Networking"],
            path: "Tests/NetworkingTests",
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug))
            ]
        )
    ]
)