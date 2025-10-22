// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Engagement",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)
    ],
    products: [
        .library(
            name: "Engagement",
            targets: ["Engagement"]
        ),
    ],
    dependencies: [
        .package(name: "AppFoundation", path: "../../Shared/AppFoundation"),
        .package(url: "https://github.com/supabase/supabase-swift", from: "2.35.0"),
    ],
    targets: [
        .target(
            name: "Engagement",
            dependencies: [
                "AppFoundation",
                .product(name: "Supabase", package: "supabase-swift"),
            ],
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug)),
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
    ]
)
