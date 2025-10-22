// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "AppFoundation",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)
    ],
    products: [
        .library(
            name: "AppFoundation",
            targets: ["AppFoundation"]
        ),
    ],
    dependencies: [
        .package(path: "../../Kits/SupabaseKit")
    ],
    targets: [
        .target(
            name: "AppFoundation",
            dependencies: [
                "SupabaseKit"
            ],
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug))
            ]
            // Note: Environment detection uses runtime bundle ID checks (AppConfig.isStaging, etc.)
            // Swift packages do NOT inherit compilation conditions from the main app target.
        ),
        .testTarget(
            name: "AppFoundationTests",
            dependencies: ["AppFoundation"],
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug))
            ]
        ),
    ]
)