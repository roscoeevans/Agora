// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.
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
        // Analytics and Monitoring
        .package(url: "https://github.com/PostHog/posthog-ios", from: "3.0.0"),
        .package(url: "https://github.com/getsentry/sentry-cocoa", from: "8.0.0"),

        // Supabase
        .package(url: "https://github.com/supabase/supabase-swift", exact: "2.34.0"),
        
        // Push Notifications
        .package(url: "https://github.com/OneSignal/OneSignal-iOS-SDK", from: "5.0.0"),
        
        // OpenAPI
        .package(url: "https://github.com/apple/swift-openapi-runtime", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-openapi-urlsession", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-http-types", from: "1.0.0"),
        
        // Local Feature Packages
        .package(path: "Packages/Features/Auth"),
        .package(path: "Packages/Features/Home"),
        .package(path: "Packages/Features/HomeForYou"),
        .package(path: "Packages/Features/HomeFollowing"),
        .package(path: "Packages/Features/Compose"),
        .package(path: "Packages/Features/PostDetail"),
        .package(path: "Packages/Features/Threading"),
        .package(path: "Packages/Features/Profile"),
        .package(path: "Packages/Features/Search"),
        .package(path: "Packages/Features/Notifications"),
        .package(path: "Packages/Features/DMs"),
        
        // Local Kit Packages
        .package(path: "Packages/Kits/DesignSystem"),
        .package(path: "Packages/Kits/Networking"),
        .package(path: "Packages/Kits/Persistence"),
        .package(path: "Packages/Kits/AgoraAuth"),
        .package(path: "Packages/Kits/Media"),
        .package(path: "Packages/Kits/Analytics"),
        .package(path: "Packages/Kits/Moderation"),
        .package(path: "Packages/Kits/Verification"),
        .package(path: "Packages/Kits/Recommender"),
        
        // Local Shared Packages
        .package(path: "Packages/Shared/AppFoundation"),
        .package(path: "Packages/Shared/TestSupport"),
    ],
    targets: [
        // No targets defined here - all packages are standalone with their own Package.swift
    ]
)
