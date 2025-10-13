import Foundation
import Supabase
import AuthenticationServices

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
        
        // Sign in with Supabase using the Apple ID token
        let session = try await supabaseClient.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: identityToken
            )
        )
        
        // Extract user information
        let user = session.user
        var nameComponents = PersonNameComponents()
        nameComponents.givenName = appleIDCredential.fullName?.givenName
        nameComponents.familyName = appleIDCredential.fullName?.familyName
        
        let authenticatedUser = AuthenticatedUser(
            id: user.id.uuidString,
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
            expiresAt: Date(timeIntervalSince1970: TimeInterval(session.expiresAt))
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
        if let session = try? await supabaseClient.auth.session {
            return session.accessToken
        }
        
        // Fall back to local cached session
        return await sessionStore.accessToken
    }

    public var isAuthenticated: Bool {
        get async {
            do {
                return try await supabaseClient.auth.session != nil
            } catch {
                return false
            }
        }
    }

    // MARK: - Supabase-Specific Methods

    /// Sign in with email and password (for development/testing)
    public func signInWithEmail(email: String, password: String) async throws -> AuthResult {
        let session = try await supabaseClient.auth.signIn(email: email, password: password)
        
        let user = session.user

        let authenticatedUser = AuthenticatedUser(
            id: user.id.uuidString,
            email: user.email,
            fullName: nil // Email auth doesn't provide name components
        )

        return AuthResult(
            user: authenticatedUser,
            accessToken: session.accessToken,
            refreshToken: session.refreshToken ?? "",
            expiresAt: Date(timeIntervalSince1970: session.expiresAt)
        )
    }

    /// Sign up with email and password (for development/testing)
    public func signUpWithEmail(email: String, password: String) async throws -> AuthResult {
        let response = try await supabaseClient.auth.signUp(email: email, password: password)
        
        let user = response.user
        
        guard let session = response.session else {
            throw AuthError.invalidCredentials
        }

        let authenticatedUser = AuthenticatedUser(
            id: user.id.uuidString,
            email: user.email,
            fullName: nil // Email auth doesn't provide name components
        )

        return AuthResult(
            user: authenticatedUser,
            accessToken: session.accessToken,
            refreshToken: session.refreshToken ?? "",
            expiresAt: Date(timeIntervalSince1970: session.expiresAt)
        )
    }

    /// Get current user session from Supabase
    public func getSupabaseSession() async throws -> Auth.Session {
        return try await supabaseClient.auth.session
    }
    
    // MARK: - Auth State Listener
    
    private func setupAuthStateListener() {
        Task {
            for await (event, session) in await supabaseClient.auth.authStateChanges {
                await handleAuthStateChange(event, session: session)
            }
        }
    }
    
    private func handleAuthStateChange(_ event: AuthChangeEvent, session: Auth.Session?) async {
        switch event {
        case .signedIn:
            Logger.auth.info("User signed in via Supabase Auth")
        case .signedOut:
            Logger.auth.info("User signed out via Supabase Auth")
        case .userUpdated:
            Logger.auth.info("User updated via Supabase Auth")
        case .tokenRefreshed:
            Logger.auth.debug("Token refreshed via Supabase Auth")
        default:
            break
        }
    }
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
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first(where: { $0.isKeyWindow }) ?? scene.windows.first else {
            fatalError("No window available for Sign in with Apple presentation")
        }
        return window
    }
}
