// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "SupabaseKit",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)
    ],
    products: [
        .library(name: "SupabaseKit", targets: ["SupabaseKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/supabase/supabase-swift", from: "2.35.0")
    ],
    targets: [
        .target(
            name: "SupabaseKit",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift")
            ],
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug))
            ]
        ),
        .testTarget(
            name: "SupabaseKitTests",
            dependencies: ["SupabaseKit"],
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug))
            ]
        )
    ]
)