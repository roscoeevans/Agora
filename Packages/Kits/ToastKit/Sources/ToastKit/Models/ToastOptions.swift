import SwiftUI
import Foundation

/// Behavioral options for toast presentation and interaction
public struct ToastOptions: Sendable {
    public var duration: Duration
    public var allowsUserDismiss: Bool
    public var presentationEdge: Edge
    public var haptics: ToastHaptic
    public var accessibilityPolite: Bool
    public var dedupeKey: String?
    public var maxWidth: CGFloat?
    public var safeAreaBehavior: SafeAreaBehavior
    public var reduceMotion: MotionBehavior
    public var priority: ToastPriority
    
    public init(
        duration: Duration = .seconds(3),
        allowsUserDismiss: Bool = true,
        presentationEdge: Edge = .top,
        haptics: ToastHaptic = .auto,
        accessibilityPolite: Bool = true,
        dedupeKey: String? = nil,
        maxWidth: CGFloat? = 600,
        safeAreaBehavior: SafeAreaBehavior = .avoid,
        reduceMotion: MotionBehavior = .respect,
        priority: ToastPriority = .normal
    ) {
        self.duration = duration
        self.allowsUserDismiss = allowsUserDismiss
        self.presentationEdge = presentationEdge
        self.haptics = haptics
        self.accessibilityPolite = accessibilityPolite
        self.dedupeKey = dedupeKey
        self.maxWidth = maxWidth
        self.safeAreaBehavior = safeAreaBehavior
        self.reduceMotion = reduceMotion
        self.priority = priority
    }
}

/// How toasts should behave with safe areas
public enum SafeAreaBehavior: Sendable {
    case avoid      // Respect safe areas
    case ignore     // Ignore safe areas
    case custom(EdgeInsets)  // Custom insets
}

/// How toasts should adapt to Reduce Motion settings
public enum MotionBehavior: Sendable {
    case respect    // Adapt animations for accessibility
    case ignore     // Use full animations regardless
    case custom     // Custom animation handling
}

public extension ToastOptions {
    /// Default options for different toast kinds
    static func `default`(for kind: ToastKind) -> ToastOptions {
        var options = ToastOptions()
        options.priority = .default(for: kind)
        options.haptics = .default(for: kind)
        
        // Error toasts stay longer and are more prominent
        if case .error = kind {
            options.duration = .seconds(5)
            options.accessibilityPolite = false // More assertive for errors
        }
        
        return options
    }
    
    /// Create options with haptics disabled for this specific toast
    static func withoutHaptics(
        duration: Duration = .seconds(3),
        allowsUserDismiss: Bool = true,
        presentationEdge: Edge = .top,
        accessibilityPolite: Bool = true,
        dedupeKey: String? = nil,
        maxWidth: CGFloat? = 600,
        safeAreaBehavior: SafeAreaBehavior = .avoid,
        reduceMotion: MotionBehavior = .respect,
        priority: ToastPriority = .normal
    ) -> ToastOptions {
        return ToastOptions(
            duration: duration,
            allowsUserDismiss: allowsUserDismiss,
            presentationEdge: presentationEdge,
            haptics: .disabled, // Explicitly disable haptics
            accessibilityPolite: accessibilityPolite,
            dedupeKey: dedupeKey,
            maxWidth: maxWidth,
            safeAreaBehavior: safeAreaBehavior,
            reduceMotion: reduceMotion,
            priority: priority
        )
    }
    
    /// Create a copy of these options with haptics disabled
    func withoutHaptics() -> ToastOptions {
        var options = self
        options.haptics = .disabled
        return options
    }
    
    /// Create a copy of these options with custom haptics
    func withHaptics(_ haptics: ToastHaptic) -> ToastOptions {
        var options = self
        options.haptics = haptics
        return options
    }
}