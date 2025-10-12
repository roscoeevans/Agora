import Foundation

/// Authentication state
public enum AuthState: Sendable, Equatable {
    /// Initial state while checking for existing session
    case initializing
    
    /// User is not authenticated
    case unauthenticated
    
    /// User is authenticated but hasn't created their profile yet
    case authenticatedNoProfile(userId: String)
    
    /// User is fully authenticated with complete profile
    case authenticated(profile: UserProfile)
    
    /// Whether the user is authenticated (has valid session)
    public var isAuthenticated: Bool {
        switch self {
        case .initializing, .unauthenticated:
            return false
        case .authenticatedNoProfile, .authenticated:
            return true
        }
    }
    
    /// Whether the user has a complete profile
    public var hasProfile: Bool {
        if case .authenticated = self {
            return true
        }
        return false
    }
    
    /// Get the current user profile if available
    public var currentUser: UserProfile? {
        if case .authenticated(let profile) = self {
            return profile
        }
        return nil
    }
}

