import Foundation
import SwiftUI
import AppFoundation
import Networking
import Media

/// Main authentication state manager
@Observable
@MainActor
public final class AuthStateManager {
    
    // MARK: - Published State
    
    public private(set) var state: AuthState = .initializing
    public private(set) var isLoading = false
    public private(set) var error: Error?
    
    // MARK: - Dependencies
    
    private let authService: AuthServiceProtocol
    private let apiClient: any AgoraAPIClient
    private let validator: HandleValidator
    private let storageService: StorageService
    
    // MARK: - Initialization
    
    public init(
        authService: AuthServiceProtocol? = nil,
        apiClient: (any AgoraAPIClient)? = nil,
        storageService: StorageService? = nil
    ) {
        // Use provided dependencies or create default ones
        self.authService = authService ?? ServiceProvider.shared.authService()
        // Service provider returns base protocol, cast to full protocol
        self.apiClient = apiClient ?? (ServiceProvider.shared.apiClient() as! any AgoraAPIClient)
        self.storageService = storageService ?? StorageService()
        self.validator = HandleValidator(apiClient: self.apiClient)
    }
    
    // MARK: - State Management
    
    /// Check current authentication state on app launch
    public func checkAuthState() async {
        state = .initializing
        isLoading = true
        defer { isLoading = false }
        
        // Check if user is authenticated via Supabase
        let isAuthenticated = await authService.isAuthenticated
        
        guard isAuthenticated else {
            state = .unauthenticated
            return
        }
        
        // User has valid Supabase session, try to fetch profile
        do {
            let userResponse = try await apiClient.getCurrentUserProfile()
            let profile = UserProfile(from: userResponse)
            state = .authenticated(profile: profile)
            Logger.auth.info("User authenticated with profile: \(profile.handle)")
        } catch {
            // Authenticated with Supabase but no user profile in database
            // This means they need to complete onboarding
            do {
                if let token = try await authService.currentAccessToken() {
                    let userId = try parseUserIdFromJWT(token)
                    state = .authenticatedNoProfile(userId: userId)
                    Logger.auth.info("User authenticated but no profile found, needs onboarding")
                } else {
                    state = .unauthenticated
                    Logger.auth.warning("No access token available, setting unauthenticated")
                }
            } catch {
                Logger.auth.error("Failed to parse user ID from token: \(error)")
                state = .unauthenticated
            }
        }
    }
    
    /// Parse user ID from JWT token
    private func parseUserIdFromJWT(_ token: String) throws -> String {
        let segments = token.components(separatedBy: ".")
        guard segments.count > 1 else {
            throw AuthError.invalidState
        }
        
        // Decode JWT payload (base64url)
        var base64 = segments[1]
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        // Pad to multiple of 4
        while base64.count % 4 != 0 {
            base64.append("=")
        }
        
        guard let data = Data(base64Encoded: base64),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let sub = json["sub"] as? String else {
            throw AuthError.invalidState
        }
        
        return sub
    }
    
    // MARK: - Sign In with Apple
    
    /// Initiate Sign in with Apple flow
    public func signInWithApple() async throws {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        do {
            // Use auth service to sign in with Apple (handles Supabase integration)
            let authResult = try await authService.signInWithApple()
            Logger.auth.info("Sign in with Apple successful, user ID: \(authResult.user.id)")
            
            // Check if user has a profile in our database
            do {
                let userResponse = try await apiClient.getCurrentUserProfile()
                let profile = UserProfile(from: userResponse)
                state = .authenticated(profile: profile)
                Logger.auth.info("User profile found: \(profile.handle)")
            } catch {
                // No profile exists, need to create one via onboarding
                state = .authenticatedNoProfile(userId: authResult.user.id)
                Logger.auth.info("No profile found, proceeding to onboarding")
            }
        } catch {
            self.error = error
            state = .unauthenticated
            Logger.auth.error("Sign in with Apple failed: \(error)")
            throw error
        }
    }
    
    // MARK: - Profile Creation
    
    /// Create user profile after authentication
    public func createProfile(
        handle: String,
        displayHandle: String,
        displayName: String,
        avatarImage: UIImage? = nil
    ) async throws {
        guard case .authenticatedNoProfile(let userId) = state else {
            throw AuthError.invalidState
        }
        
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        do {
            // Validate handle format
            let formatValidation = await validator.validateFormat(handle)
            guard formatValidation == .valid else {
                throw AuthError.invalidHandle(formatValidation.errorMessage ?? "Invalid handle")
            }
            
            // Upload avatar if provided
            var avatarUrl: String? = nil
            if let avatarImage = avatarImage {
                avatarUrl = try await storageService.uploadAvatar(image: avatarImage, userId: userId)
                Logger.auth.info("Avatar uploaded successfully: \(avatarUrl ?? "")")
            }
            
            // Create profile via API
            let request = Components.Schemas.CreateProfileRequest(
                handle: handle,
                displayHandle: displayHandle,
                displayName: displayName,
                avatarUrl: avatarUrl
            )
            
            let userResponse = try await apiClient.createProfile(request: request)
            let profile = UserProfile(from: userResponse)
            
            state = .authenticated(profile: profile)
        } catch {
            self.error = error
            throw error
        }
    }
    
    // MARK: - Sign Out
    
    /// Sign out current user
    public func signOut() async throws {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        do {
            try await authService.signOut()
            state = .unauthenticated
        } catch {
            self.error = error
            throw error
        }
    }
    
    // MARK: - Validation
    
    /// Get handle validator for UI
    public func getValidator() -> HandleValidator {
        return validator
    }
}


// MARK: - Auth Errors

public enum AuthError: LocalizedError, Sendable {
    case invalidState
    case invalidHandle(String)
    case profileCreationFailed
    case signInCancelled
    
    public var errorDescription: String? {
        switch self {
        case .invalidState:
            return "Invalid authentication state"
        case .invalidHandle(let message):
            return message
        case .profileCreationFailed:
            return "Failed to create profile"
        case .signInCancelled:
            return "Sign in was cancelled"
        }
    }
}

