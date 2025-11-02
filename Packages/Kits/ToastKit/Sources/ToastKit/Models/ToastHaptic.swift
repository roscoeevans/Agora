#if canImport(UIKit)
import UIKit
#endif

/// Haptic feedback types for toast notifications
public enum ToastHaptic: Sendable, Equatable {
    case auto           // Automatic based on toast kind
    case none           // No haptic feedback
    #if canImport(UIKit) && !os(macOS)
    case notification(UINotificationFeedbackGenerator.FeedbackType)
    case impact(UIImpactFeedbackGenerator.FeedbackStyle)
    case customNotification(UINotificationFeedbackGenerator.FeedbackType)  // Custom with notification type
    case customImpact(UIImpactFeedbackGenerator.FeedbackStyle)             // Custom with impact type
    #endif
    case disabled       // Explicitly disabled, ignores system settings
}

public extension ToastHaptic {
    /// Default haptic for a toast kind
    static func `default`(for kind: ToastKind) -> ToastHaptic {
        #if canImport(UIKit) && !os(macOS)
        switch kind {
        case .success:
            return .notification(.success)
        case .error:
            return .notification(.error)
        case .warning:
            return .notification(.warning)
        case .info:
            return .impact(.light)
        case .custom:
            return .impact(.medium)  // Default for custom kinds
        }
        #else
        return .none
        #endif
    }
    
    #if canImport(UIKit) && !os(macOS)
    /// Create custom haptic for ToastKind.custom variants
    static func custom(notification type: UINotificationFeedbackGenerator.FeedbackType) -> ToastHaptic {
        return .customNotification(type)
    }
    
    /// Create custom haptic for ToastKind.custom variants
    static func custom(impact style: UIImpactFeedbackGenerator.FeedbackStyle) -> ToastHaptic {
        return .customImpact(style)
    }
    #endif
    
    /// Execute the haptic feedback
    @MainActor
    func execute() {
        #if canImport(UIKit) && !os(macOS)
        // Respect system haptics toggle - check if haptics are enabled
        guard isHapticsEnabled() else { return }
        
        // Don't execute haptics on Mac devices
        guard UIDevice.current.userInterfaceIdiom != .mac else { return }
        
        switch self {
        case .auto, .none:
            break
        case .disabled:
            // Explicitly disabled, don't execute regardless of system settings
            break
        case .notification(let type):
            executeNotificationHaptic(type)
        case .impact(let style):
            executeImpactHaptic(style)
        case .customNotification(let type):
            executeNotificationHaptic(type)
        case .customImpact(let style):
            executeImpactHaptic(style)
        }
        #endif
    }
    
    /// Execute haptic feedback with animation timing coordination
    @MainActor
    func executeWithAnimationTiming(delay: Duration = .zero) async {
        #if canImport(UIKit) && !os(macOS)
        // Respect system haptics toggle - check if haptics are enabled
        guard isHapticsEnabled() else { return }
        
        // Don't execute haptics on Mac devices
        guard UIDevice.current.userInterfaceIdiom != .mac else { return }
        
        // Apply delay for animation coordination if specified
        if delay > .zero {
            do {
                try await Task.sleep(for: delay)
            } catch {
                // Handle cancellation gracefully
                return
            }
        }
        
        // Execute the haptic
        execute()
        #endif
    }
    
    #if canImport(UIKit) && !os(macOS)
    /// Check if haptics are enabled in system settings
    @MainActor
    private func isHapticsEnabled() -> Bool {
        // Check if the device supports haptics
        guard UIDevice.current.userInterfaceIdiom == .phone else {
            // iPads and other devices may not support haptics the same way
            return false
        }
        
        // For iOS 13+, we can check if haptic feedback is available
        // The system automatically respects user preferences for haptic feedback
        return true
    }
    
    /// Execute notification haptic with proper preparation
    @MainActor
    private func executeNotificationHaptic(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare() // Prepare the generator for better responsiveness
        generator.notificationOccurred(type)
    }
    
    /// Execute impact haptic with proper preparation
    @MainActor
    private func executeImpactHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare() // Prepare the generator for better responsiveness
        generator.impactOccurred()
    }
    #endif
}