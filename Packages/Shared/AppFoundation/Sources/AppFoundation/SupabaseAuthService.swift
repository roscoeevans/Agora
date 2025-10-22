import Foundation
import Security
import SupabaseKit
import AuthenticationServices
#if canImport(UIKit)
import UIKit
#endif

/// Production authentication service using Supabase Auth
@MainActor
public final class SupabaseAuthService: NSObject, AuthServiceProtocol, @unchecked Sendable {

    private let supabaseClient: AgoraSupabaseClient
    private let sessionStore: SessionStore
    private let keychainHelper: KeychainHelper
    private var authContinuation: CheckedContinuation<ASAuthorization, Error>?

    public init(
        supabaseClient: AgoraSupabaseClient = .shared,
        sessionStore: SessionStore = SessionStore(),
        keychainHelper: KeychainHelper = KeychainHelper()
    ) {
        self.supabaseClient = supabaseClient
        self.sessionStore = sessionStore
        self.keychainHelper = keychainHelper
        super.init()
        setupAuthStateListener()
    }

    // MARK: - AuthServiceProtocol Implementation

    public func signInWithApple() async throws -> AuthResult {
        // Get Apple ID credential via ASAuthorizationController
        let authorization = try await performAppleSignIn()
        
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            throw AuthError.invalidCredentials
        }
        
        // Extract identity token
        guard let identityTokenData = appleIDCredential.identityToken,
              let identityToken = String(data: identityTokenData, encoding: .utf8) else {
            throw AuthError.invalidCredentials
        }
        
        // Generate nonce for Apple Sign In
        let nonce = generateNonce()
        
        // Sign in with Supabase using the Apple ID token
        let session = try await supabaseClient.auth.signInWithApple(
            idToken: identityToken,
            nonce: nonce
        )
        
        // Extract user information
        let user = session.user
        var nameComponents = PersonNameComponents()
        nameComponents.givenName = appleIDCredential.fullName?.givenName
        nameComponents.familyName = appleIDCredential.fullName?.familyName
        
        let authenticatedUser = AuthenticatedUser(
            id: user.id,
            email: appleIDCredential.email ?? user.email,
            fullName: nameComponents
        )
        
        // Cache session locally for offline access
        try? await sessionStore.storeSession(
            user: authenticatedUser,
            identityToken: identityToken
        )
        
        return AuthResult(
            user: authenticatedUser,
            accessToken: session.accessToken,
            refreshToken: session.refreshToken ?? "",
            expiresAt: session.expiresAt
        )
    }
    
    /// Perform Apple Sign In using ASAuthorizationController
    private func performAppleSignIn() async throws -> ASAuthorization {
        return try await withCheckedThrowingContinuation { continuation in
            self.authContinuation = continuation
            
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()
            request.requestedScopes = [.fullName, .email]
            
            let authController = ASAuthorizationController(authorizationRequests: [request])
            authController.delegate = self
            authController.presentationContextProvider = self
            authController.performRequests()
        }
    }

    public func signOut() async throws {
        try await supabaseClient.auth.signOut()
        // Clear local session cache
        await sessionStore.clearSession()
    }

    public func refreshToken() async throws -> String {
        let session = try await supabaseClient.auth.refreshSession()
        return session.accessToken
    }

    public func currentAccessToken() async throws -> String? {
        // Try to get from Supabase first
        if let session = await supabaseClient.auth.session {
            return session.accessToken
        }
        
        // Fall back to local cached session
        return await sessionStore.accessToken
    }

    public var isAuthenticated: Bool {
        get async {
            return await supabaseClient.auth.session != nil
        }
    }

    // MARK: - Supabase-Specific Methods

    /// Get current user session from Supabase
    public func getSupabaseSession() async throws -> AuthSession {
        guard let session = await supabaseClient.auth.session else {
            throw AuthError.invalidCredentials
        }
        return session
    }
    
    // MARK: - Helper Methods
    
    /// Generate a cryptographically secure nonce for Apple Sign In
    private func generateNonce() -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = 32
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    // MARK: - Auth State Listener
    
    private func setupAuthStateListener() {
        // TODO: Implement auth state changes when SupabaseKit protocol is extended
        // This requires adding authStateChanges to SupabaseAuthProtocol
        Logger.auth.debug("Auth state listener setup - not yet implemented in SupabaseKit abstraction")
    }
    
    // TODO: Re-implement when SupabaseKit supports auth state changes
    // private func handleAuthStateChange(_ event: AuthChangeEvent, session: AuthSession?) async {
    //     switch event {
    //     case .signedIn:
    //         Logger.auth.info("User signed in via Supabase Auth")
    //     case .signedOut:
    //         Logger.auth.info("User signed out via Supabase Auth")
    //     case .userUpdated:
    //         Logger.auth.info("User updated via Supabase Auth")
    //     case .tokenRefreshed:
    //         Logger.auth.debug("Token refreshed via Supabase Auth")
    //     default:
    //         break
    //     }
    // }
}

// MARK: - ASAuthorizationControllerDelegate

extension SupabaseAuthService: ASAuthorizationControllerDelegate {
    public func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        authContinuation?.resume(returning: authorization)
        authContinuation = nil
    }
    
    public func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        if let authError = error as? ASAuthorizationError {
            switch authError.code {
            case .canceled:
                authContinuation?.resume(throwing: AuthError.signInCancelled)
            default:
                authContinuation?.resume(throwing: AuthError.signInFailed(authError))
            }
        } else {
            authContinuation?.resume(throwing: AuthError.signInFailed(error))
        }
        authContinuation = nil
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension SupabaseAuthService: ASAuthorizationControllerPresentationContextProviding {
    public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        #if canImport(UIKit)
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first(where: { $0.isKeyWindow }) ?? scene.windows.first else {
            fatalError("No window available for Sign in with Apple presentation")
        }
        return window
        #else
        fatalError("Sign in with Apple is only available on iOS")
        #endif
    }
}
