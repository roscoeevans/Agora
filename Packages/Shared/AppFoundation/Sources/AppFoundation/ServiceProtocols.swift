import Foundation
import AuthenticationServices

// MARK: - Authentication Service Protocol

/// Protocol for authentication services handling Sign in with Apple and session management
public protocol AuthServiceProtocol: AuthTokenProvider {
    /// Initiates Sign in with Apple flow
    /// - Returns: Authentication result containing user information and tokens
    /// - Throws: AuthError if authentication fails
    func signInWithApple() async throws -> AuthResult
    
    /// Signs out the current user
    /// - Throws: AuthError if sign out fails
    func signOut() async throws
    
    /// Refreshes the current authentication token
    /// - Returns: New access token
    /// - Throws: AuthError if refresh fails
    func refreshToken() async throws -> String
    
    /// Gets the current access token if available
    /// - Returns: Current access token or nil if not authenticated
    /// - Throws: AuthError if token retrieval fails
    func currentAccessToken() async throws -> String?
    
    /// Whether the user is currently authenticated
    var isAuthenticated: Bool { get async }
}

// MARK: - Phone Verification Service Protocol

/// Protocol for phone verification services
public protocol PhoneVerifierProtocol: Sendable {
    /// Sends a verification code to the specified phone number
    /// - Parameter phoneNumber: The phone number to verify (E.164 format)
    /// - Returns: Verification session ID for tracking the verification
    /// - Throws: PhoneVerificationError if sending fails
    func sendVerificationCode(to phoneNumber: String) async throws -> String
    
    /// Verifies the code entered by the user
    /// - Parameters:
    ///   - code: The verification code entered by the user
    ///   - sessionId: The session ID returned from sendVerificationCode
    /// - Returns: True if verification is successful
    /// - Throws: PhoneVerificationError if verification fails
    func verifyCode(_ code: String, sessionId: String) async throws -> Bool
    
    /// Checks the current verification status
    /// - Parameter sessionId: The session ID to check
    /// - Returns: Current verification status
    /// - Throws: PhoneVerificationError if status check fails
    func getVerificationStatus(sessionId: String) async throws -> VerificationStatus
}

// MARK: - Captcha Service Protocol

/// Protocol for captcha challenge services
public protocol CaptchaServiceProtocol: Sendable {
    /// Presents a captcha challenge to the user
    /// - Returns: Captcha token if challenge is completed successfully
    /// - Throws: CaptchaError if challenge fails or is cancelled
    func presentCaptcha() async throws -> String
    
    /// Verifies a captcha token with the service
    /// - Parameter token: The captcha token to verify
    /// - Returns: True if token is valid
    /// - Throws: CaptchaError if verification fails
    func verifyCaptcha(token: String) async throws -> Bool
    
    /// Checks if captcha is required for the current context
    /// - Returns: True if captcha challenge should be presented
    func isCaptchaRequired() async -> Bool
}

// MARK: - Supporting Types

/// Authentication result containing user information and tokens
public struct AuthResult: Sendable {
    public let user: AuthenticatedUser
    public let accessToken: String
    public let refreshToken: String?
    public let expiresAt: Date?
    
    public init(
        user: AuthenticatedUser,
        accessToken: String,
        refreshToken: String? = nil,
        expiresAt: Date? = nil
    ) {
        self.user = user
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
    }
}

/// Authenticated user information
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

/// Phone verification status
public enum VerificationStatus: String, Sendable, CaseIterable {
    case pending = "pending"
    case approved = "approved"
    case canceled = "canceled"
    case expired = "expired"
}

// MARK: - Error Types

/// Authentication errors
public enum AuthError: LocalizedError, Sendable {
    case notAuthenticated
    case invalidCredentials
    case signInCancelled
    case signInFailed(Error)
    case sessionExpired
    case refreshFailed
    case networkError
    
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
        case .refreshFailed:
            return "Failed to refresh authentication token"
        case .networkError:
            return "Network error occurred during authentication"
        }
    }
}

/// Phone verification errors
public enum PhoneVerificationError: LocalizedError, Sendable {
    case invalidPhoneNumber
    case sendFailed(Int)
    case verificationFailed(Int)
    case statusCheckFailed(Int)
    case networkError
    case invalidCode
    case sessionExpired
    case tooManyAttempts
    case serviceUnavailable
    
    public var errorDescription: String? {
        switch self {
        case .invalidPhoneNumber:
            return "Invalid phone number format"
        case .sendFailed(let code):
            return "Failed to send verification code (HTTP \(code))"
        case .verificationFailed(let code):
            return "Verification failed (HTTP \(code))"
        case .statusCheckFailed(let code):
            return "Status check failed (HTTP \(code))"
        case .networkError:
            return "Network error occurred"
        case .invalidCode:
            return "Invalid verification code"
        case .sessionExpired:
            return "Verification session has expired"
        case .tooManyAttempts:
            return "Too many verification attempts. Please try again later."
        case .serviceUnavailable:
            return "Phone verification service is currently unavailable"
        }
    }
}

/// Captcha errors
public enum CaptchaError: LocalizedError, Sendable {
    case challengeCancelled
    case challengeFailed
    case networkError
    case invalidToken
    case serviceUnavailable
    case configurationError
    
    public var errorDescription: String? {
        switch self {
        case .challengeCancelled:
            return "Captcha challenge was cancelled"
        case .challengeFailed:
            return "Captcha challenge failed"
        case .networkError:
            return "Network error occurred during captcha verification"
        case .invalidToken:
            return "Invalid captcha token"
        case .serviceUnavailable:
            return "Captcha service is currently unavailable"
        case .configurationError:
            return "Captcha service configuration error"
        }
    }
}