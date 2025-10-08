import Foundation

/// Protocol for providing authentication tokens to networking components.
/// This prevents circular dependencies between Auth and Networking modules.
public protocol AuthTokenProvider: Sendable {
    /// Returns the current access token if available.
    /// - Returns: The access token string, or nil if not authenticated
    /// - Throws: AuthError if token retrieval fails
    func currentAccessToken() async throws -> String?
    
    /// Returns whether the user is currently authenticated.
    var isAuthenticated: Bool { get async }
}

/// Errors that can occur during token operations
public enum AuthTokenError: LocalizedError, Sendable {
    case tokenExpired
    case tokenNotFound
    case refreshFailed
    case networkError
    
    public var errorDescription: String? {
        switch self {
        case .tokenExpired:
            return "Authentication token has expired"
        case .tokenNotFound:
            return "No authentication token found"
        case .refreshFailed:
            return "Failed to refresh authentication token"
        case .networkError:
            return "Network error during token operation"
        }
    }
}