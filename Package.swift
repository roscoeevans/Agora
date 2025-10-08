// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Agora",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        // App target will be defined in the main Xcode project
    ],
    dependencies: [
        // OpenAPI Code Generation
        .package(url: "https://github.com/apple/swift-openapi-generator", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-openapi-runtime", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-openapi-urlsession", from: "1.0.0"),
        
        // Analytics and Monitoring
        .package(url: "https://github.com/PostHog/posthog-ios", from: "3.0.0"),
        .package(url: "https://github.com/getsentry/sentry-cocoa", from: "8.0.0"),
        
        // Push Notifications
        .package(url: "https://github.com/OneSignal/OneSignal-iOS-SDK", from: "5.0.0"),
    ],
    targets: [
        // Feature packages
        .target(name: "Home", dependencies: []),
        .target(name: "HomeForYou", dependencies: []),
        .target(name: "HomeFollowing", dependencies: []),
        .target(name: "Compose", dependencies: []),
        .target(name: "PostDetail", dependencies: []),
        .target(name: "Threading", dependencies: []),
        .target(name: "Profile", dependencies: []),
        .target(name: "Search", dependencies: []),
        .target(name: "Notifications", dependencies: []),
        .target(name: "DMs", dependencies: []),
        
        // Kit packages
        .target(name: "DesignSystem", dependencies: []),
        .target(name: "Networking", dependencies: []),
        .target(name: "Persistence", dependencies: []),
        .target(name: "Auth", dependencies: []),
        .target(name: "Media", dependencies: []),
        .target(name: "Analytics", dependencies: []),
        .target(name: "Moderation", dependencies: []),
        .target(name: "Verification", dependencies: []),
        .target(name: "Recommender", dependencies: []),
        
        // Shared packages
        .target(name: "AppFoundation", dependencies: []),
        .target(name: "TestSupport", dependencies: []),
        
        // Test targets
        .testTarget(name: "HomeTests", dependencies: ["Home"]),
        .testTarget(name: "HomeForYouTests", dependencies: ["HomeForYou"]),
        .testTarget(name: "HomeFollowingTests", dependencies: ["HomeFollowing"]),
        .testTarget(name: "ComposeTests", dependencies: ["Compose"]),
        .testTarget(name: "PostDetailTests", dependencies: ["PostDetail"]),
        .testTarget(name: "ThreadingTests", dependencies: ["Threading"]),
        .testTarget(name: "ProfileTests", dependencies: ["Profile"]),
        .testTarget(name: "SearchTests", dependencies: ["Search"]),
        .testTarget(name: "NotificationsTests", dependencies: ["Notifications"]),
        .testTarget(name: "DMsTests", dependencies: ["DMs"]),
        
        .testTarget(name: "DesignSystemTests", dependencies: ["DesignSystem"]),
        .testTarget(name: "NetworkingTests", dependencies: ["Networking"]),
        .testTarget(name: "PersistenceTests", dependencies: ["Persistence"]),
        .testTarget(name: "AuthTests", dependencies: ["Auth"]),
        .testTarget(name: "MediaTests", dependencies: ["Media"]),
        .testTarget(name: "AnalyticsTests", dependencies: ["Analytics"]),
        .testTarget(name: "ModerationTests", dependencies: ["Moderation"]),
        .testTarget(name: "VerificationTests", dependencies: ["Verification"]),
        .testTarget(name: "RecommenderTests", dependencies: ["Recommender"]),
        
        .testTarget(name: "AppFoundationTests", dependencies: ["AppFoundation"]),
        .testTarget(name: "TestSupportTests", dependencies: ["TestSupport"]),
    ]
)
