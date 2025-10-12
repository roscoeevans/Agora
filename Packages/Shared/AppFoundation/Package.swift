// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "AppFoundation",
    platforms: [
        .iOS(.v26),
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "AppFoundation",
            targets: ["AppFoundation"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/supabase/supabase-swift", exact: "2.34.0")
    ],
    targets: [
        .target(
            name: "AppFoundation",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift")
            ]
            // Note: Compilation conditions (DEV_ENVIRONMENT, STAGING_ENVIRONMENT, PROD_ENVIRONMENT)
            // are inherited from the app target's .xcconfig files
        ),
        .testTarget(
            name: "AppFoundationTests",
            dependencies: ["AppFoundation"]
        ),
    ]
)