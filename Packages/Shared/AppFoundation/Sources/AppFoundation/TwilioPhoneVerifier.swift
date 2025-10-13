import Foundation

/// Twilio Verify implementation of PhoneVerifierProtocol
public final class TwilioPhoneVerifier: PhoneVerifierProtocol {
    
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
    
    // MARK: - PhoneVerifierProtocol Implementation
    
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

