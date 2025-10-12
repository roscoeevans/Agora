import Foundation

// MARK: - Public Exports

// Service protocols are automatically available when importing AppFoundation

/// AppFoundation module provides core utilities and protocols for the Agora app.
/// This module contains shared functionality that doesn't depend on other modules,
/// preventing circular dependencies in the modular architecture.
public struct AppFoundation {
    /// The current version of the AppFoundation module
    public static let version = "1.0.0"
    
    /// Initialize the AppFoundation module
    public static func initialize() {
        Logger.networking.info("AppFoundation module initialized")
    }
}