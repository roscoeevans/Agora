import Foundation

// MARK: - Analytics Protocol

/// Protocol for analytics tracking
/// 
/// This protocol is defined in the Analytics package to avoid circular dependencies.
/// AppFoundation and other modules can import Analytics to use this protocol.
public protocol AnalyticsClient: Sendable {
    func track(event: String, properties: [String: Any]) async
    func identify(userId: String, properties: [String: Any]) async
    func setUserProperties(_ properties: [String: Any]) async
    func reset() async
    func flush() async
}

/// No-op analytics client for when analytics is disabled or not yet initialized
public struct NoOpAnalyticsClient: AnalyticsClient {
    public init() {}
    
    public func track(event: String, properties: [String: Any]) async {}
    public func identify(userId: String, properties: [String: Any]) async {}
    public func setUserProperties(_ properties: [String: Any]) async {}
    public func reset() async {}
    public func flush() async {}
}

// MARK: - Type Aliases

/// Properties dictionary for analytics events
public typealias EventProperties = [String: Any]

// MARK: - Convenience Extensions

public extension AnalyticsClient {
    /// Track an event without properties
    public func track(event: String) async {
        await track(event: event, properties: [:])
    }
    
    /// Identify a user without properties
    public func identify(userId: String) async {
        await identify(userId: userId, properties: [:])
    }
}

