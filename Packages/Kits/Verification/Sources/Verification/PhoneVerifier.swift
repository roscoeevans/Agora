import Foundation

/// Phone verification status
public enum PhoneVerificationStatus: Sendable {
    case notStarted
    case codeSent
    case verified
    case failed(Error)
}

/// Phone verification errors
public enum PhoneVerificationError: LocalizedError, Sendable {
    case invalidPhoneNumber
    case networkError(Error)
    case invalidCode
    case codeExpired
    case tooManyAttempts
    case serviceUnavailable
    
    public var errorDescription: String? {
        switch self {
        case .invalidPhoneNumber:
            return "Invalid phone number format"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidCode:
            return "Invalid verification code"
        case .codeExpired:
            return "Verification code has expired"
        case .tooManyAttempts:
            return "Too many verification attempts. Please try again later."
        case .serviceUnavailable:
            return "Phone verification service is currently unavailable"
        }
    }
}

/// Phone verification result
public struct PhoneVerificationResult: Sendable {
    public let isVerified: Bool
    public let phoneNumber: String
    public let verificationId: String?
    public let timestamp: Date
    
    public init(isVerified: Bool, phoneNumber: String, verificationId: String? = nil) {
        self.isVerified = isVerified
        self.phoneNumber = phoneNumber
        self.verificationId = verificationId
        self.timestamp = Date()
    }
}

/// Phone verifier for Twilio Verify integration
@MainActor
public final class PhoneVerifier: ObservableObject, @unchecked Sendable {
    @Published public var status: PhoneVerificationStatus = .notStarted
    @Published public var isLoading: Bool = false
    
    public nonisolated static let shared: PhoneVerifier = {
        // Create instance directly - safe because PhoneVerifier is @unchecked Sendable
        // The @MainActor annotation only affects method calls, not initialization
        return PhoneVerifier()
    }()
    
    private var currentVerificationId: String?
    private var currentPhoneNumber: String?
    
    nonisolated private init() {}
    
    /// Sends verification code to phone number
    public func sendVerificationCode(to phoneNumber: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Validate phone number format
        guard isValidPhoneNumber(phoneNumber) else {
            status = .failed(PhoneVerificationError.invalidPhoneNumber)
            throw PhoneVerificationError.invalidPhoneNumber
        }
        
        do {
            // TODO: Integrate with Twilio Verify API
            let verificationId = try await sendCodeViaTwilio(phoneNumber: phoneNumber)
            
            currentVerificationId = verificationId
            currentPhoneNumber = phoneNumber
            status = .codeSent
            
        } catch {
            status = .failed(error)
            throw error
        }
    }
    
    /// Verifies the code entered by user
    public func verifyCode(_ code: String) async throws -> PhoneVerificationResult {
        guard let phoneNumber = currentPhoneNumber,
              let verificationId = currentVerificationId else {
            throw PhoneVerificationError.invalidCode
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // TODO: Verify code with Twilio Verify API
            let isValid = try await verifyCodeWithTwilio(
                verificationId: verificationId,
                code: code
            )
            
            if isValid {
                status = .verified
                return PhoneVerificationResult(
                    isVerified: true,
                    phoneNumber: phoneNumber,
                    verificationId: verificationId
                )
            } else {
                status = .failed(PhoneVerificationError.invalidCode)
                throw PhoneVerificationError.invalidCode
            }
            
        } catch {
            status = .failed(error)
            throw error
        }
    }
    
    /// Resets verification state
    public func reset() {
        status = .notStarted
        currentVerificationId = nil
        currentPhoneNumber = nil
        isLoading = false
    }
    
    /// Checks if phone number is in valid format
    public func isValidPhoneNumber(_ phoneNumber: String) -> Bool {
        // Remove all non-digit characters
        let digits = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        // Check if it's a valid length (10-15 digits)
        return digits.count >= 10 && digits.count <= 15
    }
    
    /// Formats phone number for display
    public func formatPhoneNumber(_ phoneNumber: String) -> String {
        let digits = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        // Format US numbers as (XXX) XXX-XXXX
        if digits.count == 10 {
            let area = String(digits.prefix(3))
            let exchange = String(digits.dropFirst(3).prefix(3))
            let number = String(digits.suffix(4))
            return "(\(area)) \(exchange)-\(number)"
        }
        
        // For international numbers, just add spaces
        if digits.count > 10 {
            var formatted = ""
            for (index, digit) in digits.enumerated() {
                if index > 0 && index % 3 == 0 {
                    formatted += " "
                }
                formatted += String(digit)
            }
            return formatted
        }
        
        return phoneNumber
    }
    
    // MARK: - Private Methods
    
    private func sendCodeViaTwilio(phoneNumber: String) async throws -> String {
        // TODO: Replace with actual Twilio Verify API call
        // This is a placeholder implementation
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Simulate success/failure
        if phoneNumber.contains("invalid") {
            throw PhoneVerificationError.invalidPhoneNumber
        }
        
        // Return mock verification ID
        return "VE\(UUID().uuidString.prefix(32))"
    }
    
    private func verifyCodeWithTwilio(verificationId: String, code: String) async throws -> Bool {
        // TODO: Replace with actual Twilio Verify API call
        // This is a placeholder implementation
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Simulate verification logic
        // In real implementation, this would call Twilio API
        return code == "123456" || code.count == 6
    }
}