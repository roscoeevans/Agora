import Foundation

/// Auth module providing authentication and session management functionality.
/// 
/// This module handles:
/// - Sign in with Apple integration
/// - Secure session storage using Keychain
/// - Token management and refresh
/// - Phone verification integration structure
///
/// ## Usage
/// 
/// ```swift
/// import Auth
/// 
/// let authManager = AuthManager()
/// 
/// // Sign in with Apple
/// try await authManager.signInWithApple()
/// 
/// // Check authentication status
/// let isAuthenticated = await authManager.isAuthenticated
/// 
/// // Get current access token
/// let token = try await authManager.currentAccessToken()
/// ```
public struct Auth {
    /// Current version of the Auth module
    public static let version = "1.0.0"
}