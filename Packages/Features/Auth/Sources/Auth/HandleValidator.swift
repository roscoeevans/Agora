import Foundation
import Networking

/// Validation result for handle format
public enum HandleFormatValidation: Sendable, Equatable {
    case valid
    case tooShort
    case tooLong
    case invalidCharacters
    case startsWithUnderscore
    case allNumbers
    case reserved
    
    public var errorMessage: String? {
        switch self {
        case .valid:
            return nil
        case .tooShort:
            return "Handle must be at least 3 characters"
        case .tooLong:
            return "Handle must be 15 characters or less"
        case .invalidCharacters:
            return "Use only lowercase letters, numbers, and underscores"
        case .startsWithUnderscore:
            return "Handle cannot start with an underscore"
        case .allNumbers:
            return "Handle cannot be all numbers"
        case .reserved:
            return "This handle is reserved"
        }
    }
}

/// Availability check result
public struct HandleAvailability: Sendable, Equatable {
    public let available: Bool
    public let suggestions: [String]
    
    public init(available: Bool, suggestions: [String] = []) {
        self.available = available
        self.suggestions = suggestions
    }
}

/// Actor for validating handles with debouncing
public actor HandleValidator {
    private let apiClient: any AgoraAPIClient
    private var lastCheckTask: Task<HandleAvailability, Error>?
    private let reservedHandles: Set<String> = [
        "admin", "root", "system", "agora", "support", "help",
        "moderator", "mod", "official", "team", "staff"
    ]
    
    public init(apiClient: any AgoraAPIClient) {
        self.apiClient = apiClient
    }
    
    // MARK: - Format Validation
    
    /// Validate handle format (instant, no API call)
    public func validateFormat(_ handle: String) -> HandleFormatValidation {
        // Check length
        if handle.count < 3 {
            return .tooShort
        }
        if handle.count > 15 {
            return .tooLong
        }
        
        // Check for reserved handles
        if reservedHandles.contains(handle.lowercased()) {
            return .reserved
        }
        
        // Check if starts with underscore
        if handle.hasPrefix("_") {
            return .startsWithUnderscore
        }
        
        // Check if all numbers
        if handle.allSatisfy({ $0.isNumber }) {
            return .allNumbers
        }
        
        // Check for valid characters (lowercase letters, numbers, underscores)
        let validCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789_")
        let handleCharacters = CharacterSet(charactersIn: handle.lowercased())
        
        if !handleCharacters.isSubset(of: validCharacters) {
            return .invalidCharacters
        }
        
        return .valid
    }
    
    // MARK: - Availability Check
    
    /// Check if handle is available (debounced, calls API)
    /// - Parameter handle: Lowercase handle to check
    /// - Returns: Availability result with suggestions if unavailable
    public func checkAvailability(_ handle: String) async throws -> HandleAvailability {
        // Cancel previous check if still running
        lastCheckTask?.cancel()
        
        // Create new check task with debounce delay
        let task = Task<HandleAvailability, Error> {
            // Wait 300ms for debouncing
            try await Task.sleep(nanoseconds: 300_000_000)
            
            // Check if cancelled
            try Task.checkCancellation()
            
            // Make API call
            let response = try await apiClient.checkHandle(handle: handle)
            
            return HandleAvailability(
                available: response.available,
                suggestions: response.suggestions ?? []
            )
        }
        
        lastCheckTask = task
        
        return try await task.value
    }
    
    /// Generate suggestions for unavailable handle
    public func suggestAlternatives(_ handle: String) -> [String] {
        var suggestions: [String] = []
        
        // Add numbers
        for i in 1...5 {
            suggestions.append("\(handle)\(i)")
        }
        
        // Add underscore variations
        suggestions.append("\(handle)_")
        suggestions.append("_\(handle)")
        
        // Add year
        let year = Calendar.current.component(.year, from: Date())
        suggestions.append("\(handle)\(year)")
        
        return Array(suggestions.prefix(5))
    }
}

// MARK: - Extensions

extension HandleValidator {
    /// Convenience method to validate format and return error message
    public func validateFormatMessage(_ handle: String) -> String? {
        return validateFormat(handle).errorMessage
    }
    
    /// Check if format is valid
    public func isFormatValid(_ handle: String) -> Bool {
        return validateFormat(handle) == .valid
    }
}

