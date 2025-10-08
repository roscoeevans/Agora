import Foundation

/// Input validation utilities for the Agora app
public struct ValidationHelpers: Sendable {
    
    /// Validates an email address format
    public static func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    /// Validates a phone number format (basic validation)
    public static func isValidPhoneNumber(_ phoneNumber: String) -> Bool {
        let cleanedNumber = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return cleanedNumber.count >= 10 && cleanedNumber.count <= 15
    }
    
    /// Validates a username/handle format
    public static func isValidHandle(_ handle: String) -> Bool {
        // Handle must be 3-30 characters, alphanumeric plus underscore, no spaces
        let handleRegex = #"^[a-zA-Z0-9_]{3,30}$"#
        let handlePredicate = NSPredicate(format: "SELF MATCHES %@", handleRegex)
        return handlePredicate.evaluate(with: handle)
    }
    
    /// Validates post text content
    public static func isValidPostText(_ text: String) -> ValidationResult {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedText.isEmpty {
            return .invalid("Post cannot be empty")
        }
        
        if trimmedText.count > 280 {
            return .invalid("Post exceeds 280 character limit")
        }
        
        return .valid
    }
    
    /// Validates display name
    public static func isValidDisplayName(_ displayName: String) -> ValidationResult {
        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.isEmpty {
            return .invalid("Display name cannot be empty")
        }
        
        if trimmedName.count > 50 {
            return .invalid("Display name cannot exceed 50 characters")
        }
        
        return .valid
    }
    
    /// Validates bio text
    public static func isValidBio(_ bio: String) -> ValidationResult {
        if bio.count > 160 {
            return .invalid("Bio cannot exceed 160 characters")
        }
        
        return .valid
    }
}

/// Validation result type
public enum ValidationResult: Sendable {
    case valid
    case invalid(String)
    
    public var isValid: Bool {
        switch self {
        case .valid:
            return true
        case .invalid:
            return false
        }
    }
    
    public var errorMessage: String? {
        switch self {
        case .valid:
            return nil
        case .invalid(let message):
            return message
        }
    }
}