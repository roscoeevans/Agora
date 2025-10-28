import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Error Recovery Manager

/// Manages error recovery workflows for avatar cropping operations
@MainActor
public final class CropErrorRecoveryManager: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current error being handled
    @Published public var currentError: CropValidationError?
    
    /// Whether a retry operation is in progress
    @Published public var isRetrying: Bool = false
    
    /// Number of retry attempts made for current operation
    @Published public var retryCount: Int = 0
    
    /// Whether to show detailed error information
    @Published public var showDetailedError: Bool = false
    
    /// Error recovery suggestions
    @Published public var recoverySuggestions: [RecoverySuggestion] = []
    
    // MARK: - Configuration
    
    /// Maximum number of retry attempts
    public let maxRetryAttempts: Int
    
    /// Delay between retry attempts
    public let retryDelay: TimeInterval
    
    /// Whether to show technical error details
    public let showTechnicalDetails: Bool
    
    // MARK: - Initialization
    
    public init(
        maxRetryAttempts: Int = 3,
        retryDelay: TimeInterval = 1.0,
        showTechnicalDetails: Bool = false
    ) {
        self.maxRetryAttempts = maxRetryAttempts
        self.retryDelay = retryDelay
        self.showTechnicalDetails = showTechnicalDetails
    }
    
    // MARK: - Error Handling
    
    /// Handle a crop validation error with appropriate recovery workflow
    /// - Parameter error: The error to handle
    public func handleError(_ error: CropValidationError) {
        currentError = error
        recoverySuggestions = generateRecoverySuggestions(for: error)
        
        // Log error for analytics (non-PII)
        logErrorForAnalytics(error)
        
        // Auto-retry for certain error types if within retry limit
        if error.isRetryable && retryCount < maxRetryAttempts {
            scheduleAutoRetry()
        }
    }
    
    /// Clear current error state
    public func clearError() {
        currentError = nil
        recoverySuggestions = []
        retryCount = 0
        isRetrying = false
        showDetailedError = false
    }
    
    /// Manually trigger a retry operation
    /// - Parameter operation: The operation to retry
    public func retry(operation: @escaping () async throws -> Void) async {
        guard let error = currentError, error.isRetryable else { return }
        guard retryCount < maxRetryAttempts else { return }
        
        isRetrying = true
        retryCount += 1
        
        do {
            // Add delay before retry
            if retryDelay > 0 {
                try await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
            }
            
            try await operation()
            
            // Success - clear error state
            clearError()
            
        } catch let newError as CropValidationError {
            // Handle new error
            handleError(newError)
        } catch {
            // Convert other errors to crop validation error
            handleError(.cropProcessingFailed)
        }
        
        isRetrying = false
    }
    
    /// Check if retry is available for current error
    public var canRetry: Bool {
        guard let error = currentError else { return false }
        return error.isRetryable && retryCount < maxRetryAttempts
    }
    
    /// Check if error requires user action (new image selection)
    public var requiresUserAction: Bool {
        guard let error = currentError else { return false }
        return !error.isRetryable
    }
    
    // MARK: - Private Methods
    
    private func generateRecoverySuggestions(for error: CropValidationError) -> [RecoverySuggestion] {
        var suggestions: [RecoverySuggestion] = []
        
        // Add primary recovery suggestion
        if let primarySuggestion = error.recoverySuggestion {
            suggestions.append(RecoverySuggestion(
                title: "Try This",
                description: primarySuggestion,
                action: .userAction,
                priority: .high
            ))
        }
        
        // Add category-specific suggestions
        switch error.category {
        case .imageValidation:
            suggestions.append(RecoverySuggestion(
                title: "Use Camera",
                description: "Take a new photo with your camera for best quality",
                action: .openCamera,
                priority: .medium
            ))
            suggestions.append(RecoverySuggestion(
                title: "Choose Different Photo",
                description: "Select a different photo from your library",
                action: .openPhotoLibrary,
                priority: .medium
            ))
            
        case .processing:
            if error.isRetryable {
                suggestions.append(RecoverySuggestion(
                    title: "Try Again",
                    description: "Retry the operation",
                    action: .retry,
                    priority: .high
                ))
            }
            suggestions.append(RecoverySuggestion(
                title: "Restart App",
                description: "Close and reopen the app to reset processing",
                action: .restartApp,
                priority: .low
            ))
            
        case .network:
            suggestions.append(RecoverySuggestion(
                title: "Check Connection",
                description: "Verify your internet connection and try again",
                action: .retry,
                priority: .high
            ))
            suggestions.append(RecoverySuggestion(
                title: "Try Later",
                description: "Save your crop and try uploading later",
                action: .saveForLater,
                priority: .medium
            ))
            
        case .system:
            suggestions.append(RecoverySuggestion(
                title: "Free Memory",
                description: "Close other apps to free up memory",
                action: .freeMemory,
                priority: .high
            ))
            suggestions.append(RecoverySuggestion(
                title: "Use Smaller Image",
                description: "Try with a smaller or lower resolution image",
                action: .openPhotoLibrary,
                priority: .medium
            ))
            
        case .userInput:
            suggestions.append(RecoverySuggestion(
                title: "Adjust Crop",
                description: "Zoom out or reposition the image",
                action: .adjustCrop,
                priority: .high
            ))
            suggestions.append(RecoverySuggestion(
                title: "Use Higher Resolution",
                description: "Try with a higher resolution photo",
                action: .openPhotoLibrary,
                priority: .medium
            ))
        }
        
        return suggestions.sorted { $0.priority.rawValue > $1.priority.rawValue }
    }
    
    private func scheduleAutoRetry() {
        Task {
            try await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
            
            // Only auto-retry if error is still current and retryable
            guard let error = currentError,
                  error.isRetryable,
                  retryCount < maxRetryAttempts else { return }
            
            // Auto-retry is handled by the calling code
            // This just updates the UI state
            retryCount += 1
        }
    }
    
    private func logErrorForAnalytics(_ error: CropValidationError) {
        // Log non-PII error information for analytics
        let errorData: [String: Any] = [
            "error_category": error.category.rawValue,
            "error_type": String(describing: error),
            "is_retryable": error.isRetryable,
            "retry_count": retryCount,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        // Send to analytics service (implementation depends on analytics provider)
        print("[CropErrorRecovery] Error logged: \(errorData)")
    }
}

// MARK: - Recovery Suggestion

/// Represents a suggested recovery action for an error
public struct RecoverySuggestion: Identifiable, Sendable {
    public let id = UUID()
    public let title: String
    public let description: String
    public let action: RecoveryAction
    public let priority: Priority
    
    public init(title: String, description: String, action: RecoveryAction, priority: Priority) {
        self.title = title
        self.description = description
        self.action = action
        self.priority = priority
    }
    
    public enum Priority: Int, Sendable {
        case low = 1
        case medium = 2
        case high = 3
    }
}

/// Types of recovery actions that can be suggested
public enum RecoveryAction: Sendable {
    case retry
    case openCamera
    case openPhotoLibrary
    case adjustCrop
    case freeMemory
    case restartApp
    case saveForLater
    case userAction
}

// MARK: - Error Recovery View

/// SwiftUI view for displaying error recovery options
public struct CropErrorRecoveryView: View {
    @ObservedObject private var recoveryManager: CropErrorRecoveryManager
    private let onAction: (RecoveryAction) -> Void
    
    public init(
        recoveryManager: CropErrorRecoveryManager,
        onAction: @escaping (RecoveryAction) -> Void
    ) {
        self.recoveryManager = recoveryManager
        self.onAction = onAction
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            if let error = recoveryManager.currentError {
                // Error message
                VStack(spacing: 8) {
                    Image(systemName: errorIcon(for: error))
                        .font(.system(size: 32))
                        .foregroundColor(.red)
                    
                    Text("Something went wrong")
                        .font(.headline)
                    
                    Text(error.localizedDescription)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
                .padding()
                
                // Recovery suggestions
                if !recoveryManager.recoverySuggestions.isEmpty {
                    VStack(spacing: 12) {
                        ForEach(recoveryManager.recoverySuggestions) { suggestion in
                            RecoverySuggestionRow(
                                suggestion: suggestion,
                                isRetrying: recoveryManager.isRetrying,
                                onTap: { onAction(suggestion.action) }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Technical details (if enabled)
                if recoveryManager.showTechnicalDetails {
                    DisclosureGroup("Technical Details") {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Error Category: \(error.category.rawValue)")
                            Text("Retry Count: \(recoveryManager.retryCount)")
                            Text("Is Retryable: \(error.isRetryable ? "Yes" : "No")")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding()
    }
    
    private func errorIcon(for error: CropValidationError) -> String {
        switch error.category {
        case .imageValidation:
            return "photo.badge.exclamationmark"
        case .processing:
            return "gearshape.fill"
        case .network:
            return "wifi.exclamationmark"
        case .system:
            return "memorychip"
        case .userInput:
            return "hand.tap"
        }
    }
}

/// Row view for a single recovery suggestion
private struct RecoverySuggestionRow: View {
    let suggestion: RecoverySuggestion
    let isRetrying: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(suggestion.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(suggestion.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if suggestion.action == .retry && isRetrying {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(white: 0.95))
            .cornerRadius(12)
        }
        .disabled(suggestion.action == .retry && isRetrying)
    }
}

// MARK: - View Extensions

extension View {
    /// Present error recovery options for crop validation errors
    /// - Parameters:
    ///   - recoveryManager: The error recovery manager
    ///   - onAction: Callback for handling recovery actions
    /// - Returns: View with error recovery presentation
    public func cropErrorRecovery(
        recoveryManager: CropErrorRecoveryManager,
        onAction: @escaping (RecoveryAction) -> Void
    ) -> some View {
        self.sheet(isPresented: .constant(recoveryManager.currentError != nil)) {
            CropErrorRecoveryView(
                recoveryManager: recoveryManager,
                onAction: onAction
            )
        }
    }
}