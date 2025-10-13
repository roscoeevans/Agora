import Foundation
import AppFoundation

// Re-export AnalyticsClient protocol from AppFoundation
// This allows the Analytics module to use the protocol without circular dependencies

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

