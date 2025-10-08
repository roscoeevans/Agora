import Foundation

/// Protocol for phone verification services
public protocol PhoneVerifier: Sendable {
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

/// Twilio Verify implementation of PhoneVerifier
public final class TwilioPhoneVerifier: PhoneVerifier {
    
    // MARK: - Private Properties
    
    private let accountSid: String
    private let authToken: String
    private let serviceSid: String
    private let session: URLSession
    
    // MARK: - Initialization
    
    public init(
        accountSid: String,
        authToken: String,
        serviceSid: String,
        session: URLSession = .shared
    ) {
        self.accountSid = accountSid
        self.authToken = authToken
        self.serviceSid = serviceSid
        self.session = session
    }
    
    // MARK: - PhoneVerifier Implementation
    
    public func sendVerificationCode(to phoneNumber: String) async throws -> String {
        let url = URL(string: "https://verify.twilio.com/v2/Services/\(serviceSid)/Verifications")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // Add basic auth
        let credentials = "\(accountSid):\(authToken)"
        let credentialsData = credentials.data(using: .utf8)!
        let base64Credentials = credentialsData.base64EncodedString()
        request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
        
        // Request body
        let bodyString = "To=\(phoneNumber)&Channel=sms"
        request.httpBody = bodyString.data(using: .utf8)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PhoneVerificationError.networkError
        }
        
        guard httpResponse.statusCode == 201 else {
            throw PhoneVerificationError.sendFailed(httpResponse.statusCode)
        }
        
        let verificationResponse = try JSONDecoder().decode(TwilioVerificationResponse.self, from: data)
        return verificationResponse.sid
    }
    
    public func verifyCode(_ code: String, sessionId: String) async throws -> Bool {
        let url = URL(string: "https://verify.twilio.com/v2/Services/\(serviceSid)/VerificationCheck")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // Add basic auth
        let credentials = "\(accountSid):\(authToken)"
        let credentialsData = credentials.data(using: .utf8)!
        let base64Credentials = credentialsData.base64EncodedString()
        request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
        
        // Request body
        let bodyString = "VerificationSid=\(sessionId)&Code=\(code)"
        request.httpBody = bodyString.data(using: .utf8)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PhoneVerificationError.networkError
        }
        
        guard httpResponse.statusCode == 200 else {
            throw PhoneVerificationError.verificationFailed(httpResponse.statusCode)
        }
        
        let checkResponse = try JSONDecoder().decode(TwilioVerificationCheckResponse.self, from: data)
        return checkResponse.status == "approved"
    }
    
    public func getVerificationStatus(sessionId: String) async throws -> VerificationStatus {
        let url = URL(string: "https://verify.twilio.com/v2/Services/\(serviceSid)/Verifications/\(sessionId)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Add basic auth
        let credentials = "\(accountSid):\(authToken)"
        let credentialsData = credentials.data(using: .utf8)!
        let base64Credentials = credentialsData.base64EncodedString()
        request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PhoneVerificationError.networkError
        }
        
        guard httpResponse.statusCode == 200 else {
            throw PhoneVerificationError.statusCheckFailed(httpResponse.statusCode)
        }
        
        let statusResponse = try JSONDecoder().decode(TwilioVerificationResponse.self, from: data)
        return VerificationStatus(rawValue: statusResponse.status) ?? .pending
    }
}

// MARK: - Supporting Types

public enum VerificationStatus: String, Sendable, CaseIterable {
    case pending = "pending"
    case approved = "approved"
    case canceled = "canceled"
    case expired = "expired"
}

public enum PhoneVerificationError: LocalizedError, Sendable {
    case invalidPhoneNumber
    case sendFailed(Int)
    case verificationFailed(Int)
    case statusCheckFailed(Int)
    case networkError
    case invalidCode
    case sessionExpired
    
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
        }
    }
}

// MARK: - Twilio API Models

private struct TwilioVerificationResponse: Codable {
    let sid: String
    let status: String
    let to: String
    let channel: String
}

private struct TwilioVerificationCheckResponse: Codable {
    let sid: String
    let status: String
    let to: String
}

// MARK: - Mock Implementation

/// Mock implementation of PhoneVerifier for testing and development
public actor MockPhoneVerifier: PhoneVerifier {
    
    public var shouldSucceed: Bool = true
    public var verificationDelay: TimeInterval = 0
    
    public init() {}
    
    public func sendVerificationCode(to phoneNumber: String) async throws -> String {
        if verificationDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(verificationDelay * 1_000_000_000))
        }
        
        guard shouldSucceed else {
            throw PhoneVerificationError.sendFailed(400)
        }
        
        return "mock_session_\(UUID().uuidString)"
    }
    
    public func verifyCode(_ code: String, sessionId: String) async throws -> Bool {
        if verificationDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(verificationDelay * 1_000_000_000))
        }
        
        guard shouldSucceed else {
            throw PhoneVerificationError.verificationFailed(400)
        }
        
        // Accept "123456" as valid code for testing
        return code == "123456"
    }
    
    public func getVerificationStatus(sessionId: String) async throws -> VerificationStatus {
        guard shouldSucceed else {
            throw PhoneVerificationError.statusCheckFailed(400)
        }
        
        return .pending
    }
}