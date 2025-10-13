import Foundation

/// Main module for event tracking and crash reporting functionality
/// 
/// This module provides clean DI patterns for analytics:
/// - `AnalyticsClient` protocol for dependency injection
/// - `AnalyticsClientLive` for production PostHog integration
/// - `AnalyticsClientFake` for testing
/// - `EventTracker` for type-safe event tracking
/// 
/// Usage:
/// ```swift
/// // In production (wired in AgoraApp):
/// let analytics = AnalyticsClientLive()
/// 
/// // In features (injected via Dependencies):
/// @Environment(\.deps) private var deps
/// let viewModel = ForYouViewModel(
///     networking: deps.networking,
///     analytics: deps.analytics
/// )
/// 
/// // Track events:
/// await analytics.track(event: "screen_viewed", properties: ["screen": "feed"])
/// ```
public struct Analytics: Sendable {
    public static let shared = Analytics()
    
    private init() {}
}

// MARK: - Re-exports

// The AnalyticsClient protocol is now defined in AppFoundation
// and re-exported via typealias in AnalyticsClient.swift