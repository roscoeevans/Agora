// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Media",
    platforms: [.iOS(.v26)],
    products: [
        .library(
            name: "Media",
            targets: ["Media"]
        ),
    ],
    dependencies: [
        .package(path: "../Networking"),
        .package(path: "../../Shared/AppFoundation"),
        .package(url: "https://github.com/supabase/supabase-swift", exact: "2.34.0")
    ],
    targets: [
        .target(
            name: "Media",
            dependencies: [
                "Networking",
                "AppFoundation",
                .product(name: "Supabase", package: "supabase-swift")
            ],
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug)),
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "MediaTests",
            dependencies: ["Media"],
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug))
            ]
        ),
    ]
)