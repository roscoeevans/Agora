import Foundation

/// Safety policy enforcement manager
public final class SafetyManager: Sendable {
    public static let shared = SafetyManager()
    
    private init() {}
    
    /// Validates content before posting
    public func validateContent(_ text: String) async -> ContentValidationResult {
        // Check content length
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .invalid(reason: .emptyContent)
        }
        
        if text.count > 280 {
            return .invalid(reason: .tooLong)
        }
        
        // Check for potential policy violations
        if containsSpam(text) {
            return .flagged(reason: .potentialSpam)
        }
        
        if containsHateSpeech(text) {
            return .flagged(reason: .potentialHateSpeech)
        }
        
        if containsPersonalInfo(text) {
            return .warning(reason: .personalInfoDetected)
        }
        
        return .valid
    }
    
    /// Checks if user can perform an action
    public func canPerformAction(_ action: UserAction, userId: String) async -> ActionPermissionResult {
        // TODO: Check user's current status, rate limits, etc.
        
        switch action {
        case .post:
            return await checkPostPermission(userId: userId)
        case .like:
            return await checkLikePermission(userId: userId)
        case .repost:
            return await checkRepostPermission(userId: userId)
        case .follow:
            return await checkFollowPermission(userId: userId)
        case .directMessage:
            return await checkDMPermission(userId: userId)
        }
    }
    
    /// Reports safety metrics
    public func reportSafetyMetrics() async {
        // TODO: Report safety-related metrics to analytics
        print("Safety metrics reported")
    }
    
    // MARK: - Private Methods
    
    private func containsSpam(_ text: String) -> Bool {
        let spamPatterns = [
            "click here",
            "free money",
            "limited time offer",
            "act now"
        ]
        
        let lowercaseText = text.lowercased()
        return spamPatterns.contains { lowercaseText.contains($0) }
    }
    
    private func containsHateSpeech(_ text: String) -> Bool {
        // TODO: Implement more sophisticated hate speech detection
        // This is a very basic placeholder
        let hateSpeechPatterns: [String] = [
            // Add patterns here - keeping minimal for placeholder
        ]
        
        let lowercaseText = text.lowercased()
        return hateSpeechPatterns.contains { lowercaseText.contains($0) }
    }
    
    private func containsPersonalInfo(_ text: String) -> Bool {
        // Check for email patterns
        let emailRegex = try? NSRegularExpression(pattern: #"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b"#)
        if let regex = emailRegex {
            let range = NSRange(location: 0, length: text.utf16.count)
            if regex.firstMatch(in: text, options: [], range: range) != nil {
                return true
            }
        }
        
        // Check for phone number patterns
        let phoneRegex = try? NSRegularExpression(pattern: #"\b\d{3}[-.]?\d{3}[-.]?\d{4}\b"#)
        if let regex = phoneRegex {
            let range = NSRange(location: 0, length: text.utf16.count)
            if regex.firstMatch(in: text, options: [], range: range) != nil {
                return true
            }
        }
        
        return false
    }
    
    private func checkPostPermission(userId: String) async -> ActionPermissionResult {
        // TODO: Check posting rate limits, user status, etc.
        return .allowed
    }
    
    private func checkLikePermission(userId: String) async -> ActionPermissionResult {
        // TODO: Check like rate limits
        return .allowed
    }
    
    private func checkRepostPermission(userId: String) async -> ActionPermissionResult {
        // TODO: Check repost rate limits
        return .allowed
    }
    
    private func checkFollowPermission(userId: String) async -> ActionPermissionResult {
        // TODO: Check follow rate limits
        return .allowed
    }
    
    private func checkDMPermission(userId: String) async -> ActionPermissionResult {
        // TODO: Check DM permissions and rate limits
        return .allowed
    }
}

/// Content validation result
public enum ContentValidationResult {
    case valid
    case warning(reason: ValidationWarning)
    case flagged(reason: ValidationFlag)
    case invalid(reason: ValidationError)
}

/// Content validation warnings
public enum ValidationWarning {
    case personalInfoDetected
    case potentiallyOffensive
    case longContent
}

/// Content validation flags
public enum ValidationFlag {
    case potentialSpam
    case potentialHateSpeech
    case potentialMisinformation
}

/// Content validation errors
public enum ValidationError {
    case emptyContent
    case tooLong
    case containsProhibitedContent
}

/// User actions that require permission checks
public enum UserAction {
    case post
    case like
    case repost
    case follow
    case directMessage
}

/// Action permission result
public enum ActionPermissionResult {
    case allowed
    case denied(reason: String)
    case rateLimited(retryAfter: TimeInterval)
}