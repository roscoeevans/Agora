// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Onboarding",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)  // High version to effectively disable macOS
    ],
    products: [
        .library(
            name: "Onboarding",
            targets: ["Onboarding"]
        )
    ],
    dependencies: [
        .package(path: "../../Kits/DesignSystem"),
        .package(path: "../../Shared/AppFoundation")
    ],
    targets: [
        .target(
            name: "Onboarding",
            dependencies: [
                "DesignSystem",
                "AppFoundation"
            ],
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug))
            ]
        ),
        .testTarget(
            name: "OnboardingTests",
            dependencies: ["Onboarding"],
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug))
            ]
        )
    ]
)

