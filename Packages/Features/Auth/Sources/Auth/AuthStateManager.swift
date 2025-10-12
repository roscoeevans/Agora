import Foundation
import SwiftUI
import AppFoundation
import Networking
import AuthenticationServices

/// Main authentication state manager
@Observable
@MainActor
public final class AuthStateManager: NSObject {
    
    // MARK: - Published State
    
    public private(set) var state: AuthState = .initializing
    public private(set) var isLoading = false
    public private(set) var error: Error?
    
    // MARK: - Dependencies
    
    private let authService: AuthServiceProtocol
    private let apiClient: any AgoraAPIClient
    private let validator: HandleValidator
    
    // MARK: - Private State
    
    private var currentAuthController: ASAuthorizationController?
    
    // MARK: - Initialization
    
    public init(
        authService: AuthServiceProtocol? = nil,
        apiClient: (any AgoraAPIClient)? = nil
    ) {
        // Use provided dependencies or create default ones
        self.authService = authService ?? ServiceProvider.shared.authService()
        // Service provider returns base protocol, cast to full protocol
        self.apiClient = apiClient ?? (ServiceProvider.shared.apiClient() as! any AgoraAPIClient)
        self.validator = HandleValidator(apiClient: self.apiClient)
        
        super.init()
    }
    
    // MARK: - State Management
    
    /// Check current authentication state on app launch
    public func checkAuthState() async {
        state = .initializing
        
        do {
            // Check if user is authenticated
            let isAuthenticated = await authService.isAuthenticated
            
            guard isAuthenticated else {
                state = .unauthenticated
                return
            }
            
            // Try to fetch user profile
            do {
                let userResponse = try await apiClient.getCurrentUserProfile()
                let profile = UserProfile(from: userResponse)
                state = .authenticated(profile: profile)
            } catch {
                // User is authenticated but has no profile
                // Get user ID from auth service
                if let token = try? await authService.currentAccessToken() {
                    // Parse JWT to get user ID (simplified - in production use proper JWT parsing)
                    state = .authenticatedNoProfile(userId: "current_user")
                } else {
                    state = .unauthenticated
                }
            }
        }
    }
    
    // MARK: - Sign In with Apple
    
    /// Initiate Sign in with Apple flow
    public func signInWithApple() async throws {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        do {
            // Use AuthenticationServices to present Sign in with Apple
            let authResult = try await performAppleSignIn()
            
            // Check if user has a profile
            do {
                let userResponse = try await apiClient.getCurrentUserProfile()
                let profile = UserProfile(from: userResponse)
                state = .authenticated(profile: profile)
            } catch {
                // No profile exists, need to create one
                state = .authenticatedNoProfile(userId: authResult.user.id)
            }
        } catch {
            self.error = error
            state = .unauthenticated
            throw error
        }
    }
    
    /// Perform Apple Sign In using ASAuthorizationController
    private func performAppleSignIn() async throws -> AuthResult {
        return try await withCheckedThrowingContinuation { continuation in
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()
            request.requestedScopes = [.fullName, .email]
            
            let authController = ASAuthorizationController(authorizationRequests: [request])
            authController.delegate = self
            authController.presentationContextProvider = self
            
            self.currentAuthController = authController
            
            // Store continuation to be called in delegate methods
            Task { @MainActor in
                authController.performRequests()
            }
            
            // Note: Continuation will be resumed in delegate methods
            // This is simplified - in production, properly handle the continuation
        }
    }
    
    // MARK: - Profile Creation
    
    /// Create user profile after authentication
    public func createProfile(
        handle: String,
        displayHandle: String,
        displayName: String
    ) async throws {
        guard case .authenticatedNoProfile = state else {
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
            
            // Create profile via API
            let request = Components.Schemas.CreateProfileRequest(
                handle: handle,
                displayHandle: displayHandle,
                displayName: displayName
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

// MARK: - ASAuthorizationControllerDelegate

extension AuthStateManager: ASAuthorizationControllerDelegate {
    public func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        // Handle successful authorization
        // This is simplified - in production, properly extract credentials and call API
    }
    
    public func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        // Handle authorization error
        Task { @MainActor in
            self.error = error
            self.state = .unauthenticated
        }
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AuthStateManager: ASAuthorizationControllerPresentationContextProviding {
    public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Return the key window
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            fatalError("No window available")
        }
        return window
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

