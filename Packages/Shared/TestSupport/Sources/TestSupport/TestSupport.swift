import Foundation

/// TestSupport module provides testing utilities and mocks for the Agora app.
/// This module contains shared testing functionality that can be used across
/// all other modules for consistent and reliable testing.
public struct TestSupport {
    /// The current version of the TestSupport module
    public static let version = "1.0.0"
    
    /// Initialize the TestSupport module
    public static func initialize() {
        print("TestSupport module initialized")
    }
}