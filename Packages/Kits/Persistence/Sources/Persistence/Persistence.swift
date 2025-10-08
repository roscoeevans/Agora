import Foundation

/// Main module for local data storage and caching functionality
public struct Persistence: Sendable {
    public static let shared = Persistence()
    
    private init() {}
}