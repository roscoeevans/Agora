import Foundation
import Supabase
import AuthenticationServices

/// Production authentication service using Supabase Auth
public final class SupabaseAuthService: AuthServiceProtocol, @unchecked Sendable {

    private let supabaseClient: AgoraSupabaseClient

    public init(supabaseClient: AgoraSupabaseClient = .shared) {
        self.supabaseClient = supabaseClient
    }

    // MARK: - AuthServiceProtocol Implementation

    public func signInWithApple() async throws -> AuthResult {
        // Use Supabase's built-in Sign in with Apple flow
        let session = try await supabaseClient.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: "" // We'll handle this differently - see implementation below
            )
        )

        // For Sign in with Apple, we need to use a different approach
        // Supabase Auth doesn't directly support Sign in with Apple in the Swift SDK yet
        // We'll implement this using custom Edge Functions later
        throw AuthError.signInFailed(NSError(domain: "SupabaseAuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Sign in with Apple not yet implemented via Supabase. Use Edge Function approach."]))
    }

    public func signOut() async throws {
        try await supabaseClient.auth.signOut()
    }

    public func refreshToken() async throws -> String {
        let session = try await supabaseClient.auth.refreshSession()
        return session.accessToken
    }

    public func currentAccessToken() async throws -> String? {
        guard let session = try? await supabaseClient.auth.session else {
            return nil
        }
        return session.accessToken
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

    /// Get current user session
    public func getCurrentSession() async throws -> Session {
        return try await supabaseClient.auth.session
    }
}
