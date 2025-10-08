import Foundation
import AuthenticationServices
import AppFoundation

/// Main authentication manager handling Sign in with Apple and session management
@available(iOS 26.0, macOS 10.15, *)
public final class AuthManager: NSObject, AuthTokenProvider, @unchecked Sendable {
    
    // MARK: - Public Properties
    
    /// Current authentication state
    @MainActor
    public private(set) var authState: AuthState = .unauthenticated
    
    /// Current user information if authenticated
    @MainActor
    public private(set) var currentUser: AuthenticatedUser?
    
    // MARK: - Private Properties
    
    private let sessionStore: SessionStore
    private let keychainHelper: KeychainHelper
    private let phoneVerifier: PhoneVerifier
    
    /// Current phone verification session if in progress
    @MainActor
    public private(set) var phoneVerificationSession: PhoneVerificationSession?
    
    // MARK: - Initialization
    
    public init(
        sessionStore: SessionStore = SessionStore(),
        keychainHelper: KeychainHelper = KeychainHelper(),
        phoneVerifier: PhoneVerifier = MockPhoneVerifier()
    ) {
        self.sessionStore = sessionStore
        self.keychainHelper = keychainHelper
        self.phoneVerifier = phoneVerifier
        super.init()
        
        Task {
            await loadExistingSession()
        }
    }
    
    // MARK: - AuthTokenProvider Protocol
    
    public func currentAccessToken() async throws -> String? {
        let currentState = await getCurrentAuthState()
        switch currentState {
        case .authenticated(_):
            // Check if token is still valid
            if await sessionStore.isTokenValid() {
                return await sessionStore.accessToken
            } else {
                // Try to refresh token
                do {
                    try await refreshSession()
                    return await sessionStore.accessToken
                } catch {
                    throw AuthTokenError.refreshFailed
                }
            }
        case .unauthenticated, .authenticating:
            return nil
        }
    }
    
    public var isAuthenticated: Bool {
        get async {
            let currentState = await getCurrentAuthState()
            switch currentState {
            case .authenticated:
                return await sessionStore.isTokenValid()
            case .unauthenticated, .authenticating:
                return false
            }
        }
    }
    
    @MainActor
    private func getCurrentAuthState() -> AuthState {
        return authState
    }
    
    // MARK: - Public Methods
    
    /// Initiates Sign in with Apple flow
    @MainActor
    public func signInWithApple() async throws {
        authState = .authenticating
        
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        
        return try await withCheckedThrowingContinuation { continuation in
            let delegate = SignInDelegate { result in
                Task { @MainActor in
                    switch result {
                    case .success(let authorization):
                        do {
                            try await self.handleSuccessfulSignIn(authorization)
                            continuation.resume()
                        } catch {
                            self.authState = .unauthenticated
                            continuation.resume(throwing: error)
                        }
                    case .failure(let error):
                        self.authState = .unauthenticated
                        continuation.resume(throwing: error)
                    }
                }
            }
            
            authorizationController.delegate = delegate
            authorizationController.performRequests()
        }
    }
    
    /// Signs out the current user
    @MainActor
    public func signOut() async {
        await sessionStore.clearSession()
        await keychainHelper.deleteCredentials()
        
        authState = .unauthenticated
        currentUser = nil
    }
    
    /// Refreshes the current session
    public func refreshSession() async throws {
        let currentState = await getCurrentAuthState()
        guard case .authenticated = currentState else {
            throw AuthError.notAuthenticated
        }
        
        try await sessionStore.refreshToken()
    }
    
    // MARK: - Phone Verification
    
    /// Starts phone verification process
    /// - Parameter phoneNumber: Phone number in E.164 format (e.g., +1234567890)
    /// - Returns: Verification session for tracking progress
    public func startPhoneVerification(phoneNumber: String) async throws -> PhoneVerificationSession {
        let currentState = await getCurrentAuthState()
        guard case .authenticated = currentState else {
            throw AuthError.notAuthenticated
        }
        
        let sessionId = try await phoneVerifier.sendVerificationCode(to: phoneNumber)
        
        let session = PhoneVerificationSession(
            id: sessionId,
            phoneNumber: phoneNumber,
            createdAt: Date(),
            status: .pending
        )
        
        await setPhoneVerificationSession(session)
        return session
    }
    
    @MainActor
    private func setPhoneVerificationSession(_ session: PhoneVerificationSession?) {
        phoneVerificationSession = session
    }
    
    /// Verifies the phone verification code
    /// - Parameter code: The verification code entered by the user
    /// - Returns: True if verification is successful
    public func verifyPhoneCode(_ code: String) async throws -> Bool {
        let session = await getPhoneVerificationSession()
        guard let session = session else {
            throw PhoneVerificationError.sessionExpired
        }
        
        let isValid = try await phoneVerifier.verifyCode(code, sessionId: session.id)
        
        if isValid {
            // Update session status
            let updatedSession = PhoneVerificationSession(
                id: session.id,
                phoneNumber: session.phoneNumber,
                createdAt: session.createdAt,
                status: .approved
            )
            await setPhoneVerificationSession(updatedSession)
            
            // Store phone verification status in session
            try await sessionStore.updatePhoneVerificationStatus(isVerified: true)
        }
        
        return isValid
    }
    
    @MainActor
    private func getPhoneVerificationSession() -> PhoneVerificationSession? {
        return phoneVerificationSession
    }
    
    /// Checks if current user has verified their phone number
    public var isPhoneVerified: Bool {
        get async {
            do {
                return try await sessionStore.isPhoneVerified()
            } catch {
                return false
            }
        }
    }
    
    // MARK: - Private Methods
    
    @MainActor
    private func loadExistingSession() async {
        do {
            if await sessionStore.hasValidSession() {
                let user = try await sessionStore.getCurrentUser()
                currentUser = user
                authState = .authenticated(user)
            }
        } catch {
            // If loading fails, remain unauthenticated
            authState = .unauthenticated
        }
    }
    
    @MainActor
    private func handleSuccessfulSignIn(_ authorization: ASAuthorization) async throws {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            throw AuthError.invalidCredentials
        }
        
        // Extract user information
        let userID = appleIDCredential.user
        let email = appleIDCredential.email
        let fullName = appleIDCredential.fullName
        
        // Get identity token
        guard let identityTokenData = appleIDCredential.identityToken,
              let identityToken = String(data: identityTokenData, encoding: .utf8) else {
            throw AuthError.invalidCredentials
        }
        
        // Create user object
        var nameComponents = PersonNameComponents()
        nameComponents.givenName = fullName?.givenName
        nameComponents.familyName = fullName?.familyName
        
        let user = AuthenticatedUser(
            id: userID,
            email: email,
            fullName: nameComponents
        )
        
        // Store session
        try await sessionStore.storeSession(
            user: user,
            identityToken: identityToken
        )
        
        // Update state
        currentUser = user
        authState = .authenticated(user)
    }
}

// MARK: - Supporting Types

public enum AuthState: Sendable {
    case unauthenticated
    case authenticating
    case authenticated(AuthenticatedUser)
}

public struct AuthenticatedUser: Sendable, Codable {
    public let id: String
    public let email: String?
    public let fullName: PersonNameComponents?
    
    public init(id: String, email: String?, fullName: PersonNameComponents?) {
        self.id = id
        self.email = email
        self.fullName = fullName
    }
}

public enum AuthError: LocalizedError, Sendable {
    case notAuthenticated
    case invalidCredentials
    case signInCancelled
    case signInFailed(Error)
    case sessionExpired
    
    public var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User is not authenticated"
        case .invalidCredentials:
            return "Invalid authentication credentials"
        case .signInCancelled:
            return "Sign in was cancelled"
        case .signInFailed(let error):
            return "Sign in failed: \(error.localizedDescription)"
        case .sessionExpired:
            return "Authentication session has expired"
        }
    }
}

public struct PhoneVerificationSession: Sendable {
    public let id: String
    public let phoneNumber: String
    public let createdAt: Date
    public let status: VerificationStatus
    
    public init(id: String, phoneNumber: String, createdAt: Date, status: VerificationStatus) {
        self.id = id
        self.phoneNumber = phoneNumber
        self.createdAt = createdAt
        self.status = status
    }
}

// MARK: - Sign In Delegate

@available(iOS 26.0, macOS 10.15, *)
@MainActor
private class SignInDelegate: NSObject, ASAuthorizationControllerDelegate {
    private let completion: (Result<ASAuthorization, Error>) -> Void
    
    init(completion: @escaping (Result<ASAuthorization, Error>) -> Void) {
        self.completion = completion
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        completion(.success(authorization))
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        if let authError = error as? ASAuthorizationError {
            switch authError.code {
            case .canceled:
                completion(.failure(AuthError.signInCancelled))
            default:
                completion(.failure(AuthError.signInFailed(authError)))
            }
        } else {
            completion(.failure(AuthError.signInFailed(error)))
        }
    }
}