// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Messaging",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)
    ],
    products: [
        .library(
            name: "Messaging",
            targets: ["Messaging"]
        ),
    ],
    dependencies: [
        .package(path: "../Networking"),
        .package(path: "../../Shared/AppFoundation"),
        .package(path: "../SupabaseKit"),
        .package(path: "../Media"),
        .package(url: "https://github.com/supabase/supabase-swift", from: "2.35.0")
    ],
    targets: [
        .target(
            name: "Messaging",
            dependencies: [
                "Networking",
                "AppFoundation",
                "SupabaseKit",
                "Media",
                .product(name: "Supabase", package: "supabase-swift")
            ],
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug)),
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "MessagingTests",
            dependencies: ["Messaging"],
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug))
            ]
        ),
    ]
)