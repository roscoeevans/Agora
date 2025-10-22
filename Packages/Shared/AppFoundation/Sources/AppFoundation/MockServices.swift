import Foundation
import AuthenticationServices

// MARK: - Mock Authentication Service

/// Mock implementation of AuthServiceProtocol for testing and development
@available(iOS 26.0, macOS 15.0, *)
public final class MockAuthService: AuthServiceProtocol, @unchecked Sendable {
    
    // MARK: - Configuration Properties
    
    /// Whether authentication operations should succeed
    public var shouldSucceed: Bool = true
    
    /// Delay to simulate network operations
    public var operationDelay: TimeInterval = 0.5
    
    /// Mock user data to return on successful authentication
    public var mockUser: AuthenticatedUser = AuthenticatedUser(
        id: "mock_user_123",
        email: "test@example.com",
        fullName: PersonNameComponents(givenName: "Test", familyName: "User")
    )
    
    /// Mock access token to return
    public var mockAccessToken: String = "mock_access_token_\(UUID().uuidString)"
    
    /// Whether the user is currently authenticated in the mock
    private var _isAuthenticated: Bool = false
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - AuthServiceProtocol Implementation
    
    public func signInWithApple() async throws -> AuthResult {
        // Simulate network delay
        if operationDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(operationDelay * 1_000_000_000))
        }
        
        guard shouldSucceed else {
            throw AuthError.signInFailed(MockAuthError.simulatedFailure)
        }
        
        _isAuthenticated = true
        
        return AuthResult(
            user: mockUser,
            accessToken: mockAccessToken,
            refreshToken: "mock_refresh_token_\(UUID().uuidString)",
            expiresAt: Date().addingTimeInterval(3600) // 1 hour from now
        )
    }
    
    public func signOut() async throws {
        // Simulate network delay
        if operationDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(operationDelay * 1_000_000_000))
        }
        
        guard shouldSucceed else {
            throw AuthError.networkError
        }
        
        _isAuthenticated = false
    }
    
    public func refreshToken() async throws -> String {
        // Simulate network delay
        if operationDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(operationDelay * 1_000_000_000))
        }
        
        guard shouldSucceed else {
            throw AuthError.refreshFailed
        }
        
        guard _isAuthenticated else {
            throw AuthError.notAuthenticated
        }
        
        // Generate new mock token
        mockAccessToken = "mock_access_token_\(UUID().uuidString)"
        return mockAccessToken
    }
    
    public func currentAccessToken() async throws -> String? {
        guard _isAuthenticated else {
            return nil
        }
        
        return mockAccessToken
    }
    
    public var isAuthenticated: Bool {
        get async {
            return _isAuthenticated
        }
    }
    
    // MARK: - Mock Control Methods
    
    /// Reset the mock service to initial state
    public func reset() {
        _isAuthenticated = false
        shouldSucceed = true
        operationDelay = 0.5
        mockAccessToken = "mock_access_token_\(UUID().uuidString)"
    }
    
    /// Configure the mock to simulate authentication failure
    public func simulateFailure() {
        shouldSucceed = false
    }
    
    /// Configure the mock to simulate successful operations
    public func simulateSuccess() {
        shouldSucceed = true
    }
}

// MARK: - Mock Phone Verifier Service

/// Mock implementation of PhoneVerifierProtocol for testing and development
@available(iOS 26.0, macOS 15.0, *)
public final class MockPhoneVerifier: PhoneVerifierProtocol, @unchecked Sendable {
    
    // MARK: - Configuration Properties
    
    /// Whether verification operations should succeed
    public var shouldSucceed: Bool = true
    
    /// Delay to simulate network operations
    public var operationDelay: TimeInterval = 0.5
    
    /// Valid verification codes that will pass verification
    public var validCodes: Set<String> = ["123456", "000000", "111111"]
    
    /// Mock verification sessions
    private var sessions: [String: MockVerificationSession] = [:]
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - PhoneVerifierProtocol Implementation
    
    public func sendVerificationCode(to phoneNumber: String) async throws -> String {
        // Simulate network delay
        if operationDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(operationDelay * 1_000_000_000))
        }
        
        guard shouldSucceed else {
            throw PhoneVerificationError.sendFailed(400)
        }
        
        // Validate phone number format
        guard isValidPhoneNumber(phoneNumber) else {
            throw PhoneVerificationError.invalidPhoneNumber
        }
        
        // Create mock session
        let sessionId = "mock_session_\(UUID().uuidString)"
        let session = MockVerificationSession(
            id: sessionId,
            phoneNumber: phoneNumber,
            createdAt: Date(),
            status: .pending
        )
        
        sessions[sessionId] = session
        
        return sessionId
    }
    
    public func verifyCode(_ code: String, sessionId: String) async throws -> Bool {
        // Simulate network delay
        if operationDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(operationDelay * 1_000_000_000))
        }
        
        guard shouldSucceed else {
            throw PhoneVerificationError.verificationFailed(400)
        }
        
        guard var session = sessions[sessionId] else {
            throw PhoneVerificationError.sessionExpired
        }
        
        // Check if code is valid
        let isValid = validCodes.contains(code)
        
        // Update session status
        session.status = isValid ? .approved : .canceled
        sessions[sessionId] = session
        
        return isValid
    }
    
    public func getVerificationStatus(sessionId: String) async throws -> VerificationStatus {
        guard shouldSucceed else {
            throw PhoneVerificationError.statusCheckFailed(400)
        }
        
        guard let session = sessions[sessionId] else {
            throw PhoneVerificationError.sessionExpired
        }
        
        return session.status
    }
    
    // MARK: - Mock Control Methods
    
    /// Reset the mock service to initial state
    public func reset() {
        sessions.removeAll()
        shouldSucceed = true
        operationDelay = 0.5
        validCodes = ["123456", "000000", "111111"]
    }
    
    /// Add a valid verification code
    public func addValidCode(_ code: String) {
        validCodes.insert(code)
    }
    
    /// Remove a valid verification code
    public func removeValidCode(_ code: String) {
        validCodes.remove(code)
    }
    
    /// Configure the mock to simulate verification failure
    public func simulateFailure() {
        shouldSucceed = false
    }
    
    /// Configure the mock to simulate successful operations
    public func simulateSuccess() {
        shouldSucceed = true
    }
    
    // MARK: - Private Methods
    
    private func isValidPhoneNumber(_ phoneNumber: String) -> Bool {
        // Basic validation for E.164 format
        let digits = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return digits.count >= 10 && digits.count <= 15 && phoneNumber.hasPrefix("+")
    }
}

// MARK: - Mock Captcha Service

/// Mock implementation of CaptchaServiceProtocol for testing and development
@available(iOS 26.0, macOS 15.0, *)
public final class MockCaptchaService: CaptchaServiceProtocol, @unchecked Sendable {
    
    // MARK: - Configuration Properties
    
    /// Whether captcha operations should succeed
    public var shouldSucceed: Bool = true
    
    /// Delay to simulate captcha challenge presentation
    public var challengeDelay: TimeInterval = 1.0
    
    /// Whether captcha should be required
    public var isCaptchaRequiredValue: Bool = false
    
    /// Valid captcha tokens that will pass verification
    public var validTokens: Set<String> = ["mock_captcha_token_valid"]
    
    /// Whether to simulate user cancellation
    public var shouldSimulateCancellation: Bool = false
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - CaptchaServiceProtocol Implementation
    
    public func presentCaptcha() async throws -> String {
        // Simulate captcha challenge presentation delay
        if challengeDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(challengeDelay * 1_000_000_000))
        }
        
        if shouldSimulateCancellation {
            throw CaptchaError.challengeCancelled
        }
        
        guard shouldSucceed else {
            throw CaptchaError.challengeFailed
        }
        
        // Return mock captcha token
        return "mock_captcha_token_\(UUID().uuidString)"
    }
    
    public func verifyCaptcha(token: String) async throws -> Bool {
        // Simulate network delay for verification
        if operationDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(operationDelay * 1_000_000_000))
        }
        
        guard shouldSucceed else {
            throw CaptchaError.networkError
        }
        
        // Check if token is in valid tokens set or follows mock pattern
        return validTokens.contains(token) || token.hasPrefix("mock_captcha_token_")
    }
    
    public func isCaptchaRequired() async -> Bool {
        return isCaptchaRequiredValue
    }
    
    // MARK: - Mock Control Methods
    
    /// Reset the mock service to initial state
    public func reset() {
        shouldSucceed = true
        challengeDelay = 1.0
        isCaptchaRequiredValue = false
        shouldSimulateCancellation = false
        validTokens = ["mock_captcha_token_valid"]
    }
    
    /// Configure captcha to be required
    public func requireCaptcha(_ required: Bool = true) {
        isCaptchaRequiredValue = required
    }
    
    /// Configure the mock to simulate challenge cancellation
    public func simulateCancellation() {
        shouldSimulateCancellation = true
    }
    
    /// Configure the mock to simulate challenge failure
    public func simulateFailure() {
        shouldSucceed = false
    }
    
    /// Configure the mock to simulate successful operations
    public func simulateSuccess() {
        shouldSucceed = true
        shouldSimulateCancellation = false
    }
    
    /// Add a valid captcha token
    public func addValidToken(_ token: String) {
        validTokens.insert(token)
    }
    
    // MARK: - Private Properties
    
    private var operationDelay: TimeInterval = 0.3
}

// MARK: - Supporting Types

/// Mock verification session for phone verification
private struct MockVerificationSession {
    let id: String
    let phoneNumber: String
    let createdAt: Date
    var status: VerificationStatus
}

/// Mock authentication errors
private enum MockAuthError: LocalizedError {
    case simulatedFailure
    
    var errorDescription: String? {
        switch self {
        case .simulatedFailure:
            return "Simulated authentication failure for testing"
        }
    }
}

// MARK: - No-Op Comment Composition Service

import SwiftUI

/// No-op implementation of CommentCompositionProtocol
/// Used when PostDetail module is not available or for testing
public struct NoOpCommentCompositionService: CommentCompositionProtocol {
    public init() {}
    
    public func createCommentSheet(
        for post: Post,
        replyToCommentId: String?,
        replyToUsername: String?
    ) -> AnyView {
        AnyView(
            Text("Comment composition not available")
                .foregroundColor(.secondary)
                .padding()
        )
    }
}

// MARK: - PersonNameComponents Extension

extension PersonNameComponents {
    init(givenName: String?, familyName: String?) {
        self.init()
        self.givenName = givenName
        self.familyName = familyName
    }
}