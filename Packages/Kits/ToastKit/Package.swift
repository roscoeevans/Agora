// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "ToastKit",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)  // High version to effectively disable macOS
    ],
    products: [
        .library(name: "ToastKit", targets: ["ToastKit"])
    ],
    dependencies: [
        .package(path: "../../Shared/AppFoundation"),
        .package(path: "../DesignSystem"),
        .package(path: "../Analytics")
    ],
    targets: [
        .target(
            name: "ToastKit",
            dependencies: [
                "AppFoundation",
                "DesignSystem",
                "Analytics"
            ],
            swiftSettings: [
                // Ensure DEBUG is defined for this package in Debug config (needed for #if DEBUG blocks).
                .define("DEBUG", .when(configuration: .debug))
            ]
        ),
        .testTarget(
            name: "ToastKitTests",
            dependencies: ["ToastKit"],
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug))
            ]
        )
    ]
)