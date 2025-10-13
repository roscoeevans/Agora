import Foundation

/// Manages the complete authentication session lifecycle
public actor SessionLifecycleManager {
    
    // MARK: - Private Properties
    
    private let sessionStore: SessionStore
    private let keychainHelper: KeychainHelper
    private var sessionTimer: Timer?
    
    // MARK: - Public Properties
    
    /// Callback for session expiration events
    public var onSessionExpired: (() -> Void)?
    
    /// Callback for session refresh events
    public var onSessionRefreshed: (() -> Void)?
    
    // MARK: - Initialization
    
    public init(
        sessionStore: SessionStore,
        keychainHelper: KeychainHelper = KeychainHelper()
    ) {
        self.sessionStore = sessionStore
        self.keychainHelper = keychainHelper
    }
    
    // MARK: - Public Methods
    
    /// Starts monitoring session lifecycle
    public func startMonitoring() async {
        await scheduleSessionCheck()
    }
    
    /// Stops monitoring session lifecycle
    public func stopMonitoring() async {
        sessionTimer?.invalidate()
        sessionTimer = nil
    }
    
    /// Validates current session and refreshes if needed
    public func validateSession() async throws -> Bool {
        guard await sessionStore.hasValidSession() else {
            await handleSessionExpired()
            return false
        }
        
        // Check if session is close to expiring (within 5 minutes)
        if let session = try await sessionStore.loadSession(),
           session.expiresAt.timeIntervalSinceNow < 300 {
            do {
                try await sessionStore.refreshToken()
                onSessionRefreshed?()
            } catch {
                await handleSessionExpired()
                return false
            }
        }
        
        return true
    }
    
    /// Forces session refresh
    public func refreshSession() async throws {
        try await sessionStore.refreshToken()
        onSessionRefreshed?()
    }
    
    /// Clears session and notifies of expiration
    public func expireSession() async {
        await sessionStore.clearSession()
        await handleSessionExpired()
    }
    
    // MARK: - Private Methods
    
    private func scheduleSessionCheck() async {
        // Schedule periodic session validation every 5 minutes
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
            Task {
                try? await self.validateSession()
            }
        }
    }
    
    private func handleSessionExpired() async {
        await stopMonitoring()
        onSessionExpired?()
    }
}

// MARK: - Session Validation Extensions

extension SessionStore {
    /// Validates session integrity and token freshness
    public func validateSessionIntegrity() async throws -> SessionValidationResult {
        guard let session = try await loadSession() else {
            return .invalid(.sessionNotFound)
        }
        
        // Check expiration
        guard session.isValid else {
            return .invalid(.expired)
        }
        
        // Check token format (basic validation)
        guard !session.accessToken.isEmpty else {
            return .invalid(.malformedToken)
        }
        
        // Check if refresh is needed (within 10 minutes of expiry)
        let timeUntilExpiry = session.expiresAt.timeIntervalSinceNow
        if timeUntilExpiry < 600 {
            return .needsRefresh
        }
        
        return .valid
    }
}

// MARK: - Supporting Types

public enum SessionValidationResult: Sendable {
    case valid
    case needsRefresh
    case invalid(SessionInvalidReason)
}

public enum SessionInvalidReason: Sendable {
    case sessionNotFound
    case expired
    case malformedToken
    case networkError
}

