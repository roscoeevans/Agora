import Foundation
import AppFoundation

/// Manages authentication sessions and token storage
public actor SessionStore {
    
    // MARK: - Private Properties
    
    private let keychainHelper: KeychainHelperProtocol
    private var currentSession: Session?
    
    // MARK: - Initialization
    
    public init(keychainHelper: KeychainHelperProtocol = KeychainHelper()) {
        self.keychainHelper = keychainHelper
    }
    
    // MARK: - Public Properties
    
    /// Current access token if available
    public var accessToken: String? {
        currentSession?.accessToken
    }
    
    /// Current refresh token if available
    public var refreshToken: String? {
        currentSession?.refreshToken
    }
    
    // MARK: - Public Methods
    
    /// Stores a new authentication session
    public func storeSession(user: AuthenticatedUser, identityToken: String) async throws {
        // In a real implementation, you would exchange the identity token
        // with your backend for access/refresh tokens
        // For now, we'll create a mock session
        let session = Session(
            user: user,
            accessToken: "mock_access_token_\(UUID().uuidString)",
            refreshToken: "mock_refresh_token_\(UUID().uuidString)",
            expiresAt: Date().addingTimeInterval(3600) // 1 hour
        )
        
        currentSession = session
        
        // Store in keychain
        try await keychainHelper.storeSession(session)
    }
    
    /// Loads existing session from keychain
    public func loadSession() async throws -> Session? {
        if let session = currentSession {
            return session
        }
        
        let session = try await keychainHelper.loadSession()
        currentSession = session
        return session
    }
    
    /// Checks if there's a valid session
    public func hasValidSession() async -> Bool {
        do {
            guard let session = try await loadSession() else {
                return false
            }
            return session.isValid
        } catch {
            return false
        }
    }
    
    /// Checks if current token is valid
    public func isTokenValid() async -> Bool {
        guard let session = currentSession else {
            return false
        }
        return session.isValid
    }
    
    /// Gets current authenticated user
    public func getCurrentUser() async throws -> AuthenticatedUser {
        guard let session = try await loadSession() else {
            throw AuthTokenError.tokenNotFound
        }
        
        guard session.isValid else {
            throw AuthTokenError.tokenExpired
        }
        
        return session.user
    }
    
    /// Refreshes the current token
    public func refreshToken() async throws {
        guard let session = currentSession,
              let refreshToken = session.refreshToken else {
            throw AuthTokenError.tokenNotFound
        }
        
        // In a real implementation, you would call your backend to refresh the token
        // For now, we'll create a new mock session
        let newSession = Session(
            user: session.user,
            accessToken: "refreshed_access_token_\(UUID().uuidString)",
            refreshToken: refreshToken,
            expiresAt: Date().addingTimeInterval(3600) // 1 hour
        )
        
        currentSession = newSession
        
        // Update keychain
        try await keychainHelper.storeSession(newSession)
    }
    
    /// Clears the current session
    public func clearSession() async {
        currentSession = nil
        await keychainHelper.deleteCredentials()
    }
    
    /// Updates phone verification status for current session
    public func updatePhoneVerificationStatus(isVerified: Bool) async throws {
        guard let session = currentSession else {
            throw AuthTokenError.tokenNotFound
        }
        
        let updatedSession = Session(
            user: session.user,
            accessToken: session.accessToken,
            refreshToken: session.refreshToken,
            expiresAt: session.expiresAt,
            isPhoneVerified: isVerified
        )
        
        currentSession = updatedSession
        try await keychainHelper.storeSession(updatedSession)
    }
    
    /// Checks if phone is verified for current session
    public func isPhoneVerified() async throws -> Bool {
        guard let session = try await loadSession() else {
            return false
        }
        return session.isPhoneVerified
    }
}

// MARK: - Session Model

public struct Session: Codable, Sendable {
    public let user: AuthenticatedUser
    public let accessToken: String
    public let refreshToken: String?
    public let expiresAt: Date
    public let isPhoneVerified: Bool
    
    public var isValid: Bool {
        Date() < expiresAt
    }
    
    public init(user: AuthenticatedUser, accessToken: String, refreshToken: String?, expiresAt: Date, isPhoneVerified: Bool = false) {
        self.user = user
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
        self.isPhoneVerified = isPhoneVerified
    }
}