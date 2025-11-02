import SwiftUI
import DesignSystem

/// Animation configuration for toast presentations and dismissals
@available(iOS 26.0, *)
public struct ToastAnimations {
    
    // MARK: - Animation Durations
    
    /// Standard animation duration for toast transitions (240ms)
    public static let standardDuration: Double = 0.24
    
    /// Quick animation duration for micro-interactions (120ms)
    public static let quickDuration: Double = 0.12
    
    /// Interactive animation duration for gesture-driven animations
    public static let interactiveDuration: Double = 0.3
    
    // MARK: - Spring Parameters
    
    /// Spring response for appearance animations
    public static let appearanceResponse: Double = 0.4
    
    /// Spring damping for appearance animations
    public static let appearanceDamping: Double = 0.8
    
    /// Spring response for dismissal animations
    public static let dismissalResponse: Double = 0.3
    
    /// Spring damping for dismissal animations
    public static let dismissalDamping: Double = 0.7
    
    /// Spring response for interactive gestures
    public static let interactiveResponse: Double = 0.25
    
    /// Spring damping for interactive gestures
    public static let interactiveDamping: Double = 0.9
    
    // MARK: - Animation Curves
    
    /// Spring animation for toast appearance
    public static var appearanceSpring: Animation {
        .spring(response: appearanceResponse, dampingFraction: appearanceDamping)
    }
    
    /// Spring animation for toast dismissal
    public static var dismissalSpring: Animation {
        .spring(response: dismissalResponse, dampingFraction: dismissalDamping)
    }
    
    /// Interactive spring for gesture-driven animations
    public static var interactiveSpring: Animation {
        .interactiveSpring(response: interactiveResponse, dampingFraction: interactiveDamping)
    }
    
    /// Ease-in-out animation for standard transitions
    public static var standardEaseInOut: Animation {
        .easeInOut(duration: standardDuration)
    }
    
    /// Quick ease-in-out for micro-interactions
    public static var quickEaseInOut: Animation {
        .easeInOut(duration: quickDuration)
    }
    
    // MARK: - Accessibility-Aware Animations
    
    /// Returns appropriate animation based on reduce motion setting
    public static func accessibleAnimation(
        reduceMotion: Bool,
        standard: Animation,
        reduced: Animation
    ) -> Animation {
        reduceMotion ? reduced : standard
    }
    
    /// Appearance animation that respects Reduce Motion
    public static func accessibleAppearance(reduceMotion: Bool) -> Animation {
        accessibleAnimation(
            reduceMotion: reduceMotion,
            standard: appearanceSpring,
            reduced: standardEaseInOut
        )
    }
    
    /// Dismissal animation that respects Reduce Motion
    public static func accessibleDismissal(reduceMotion: Bool) -> Animation {
        accessibleAnimation(
            reduceMotion: reduceMotion,
            standard: dismissalSpring,
            reduced: standardEaseInOut
        )
    }
    
    /// Interactive animation that respects Reduce Motion
    public static func accessibleInteractive(reduceMotion: Bool, isDragging: Bool) -> Animation {
        if reduceMotion {
            return isDragging ? .linear(duration: 0.1) : standardEaseInOut
        } else {
            return isDragging ? interactiveSpring : dismissalSpring
        }
    }
    
    // MARK: - Animation Values
    
    /// Scale values for appearance animation
    public struct ScaleValues {
        public static let initial: Double = 0.96
        public static let final: Double = 1.0
        public static let reduced: Double = 1.0 // No scale for reduce motion
    }
    
    /// Opacity values for all animations
    public struct OpacityValues {
        public static let hidden: Double = 0.0
        public static let visible: Double = 1.0
    }
    
    /// Translation values for directional animations
    public struct TranslationValues {
        public static let topDismissal: CGFloat = -20
        public static let bottomDismissal: CGFloat = 20
        public static let none: CGFloat = 0
    }
    
    // MARK: - Performance Optimization
    
    /// Whether to use high performance mode (120 FPS on ProMotion displays)
    public static var useHighPerformanceMode: Bool {
        // Enable high performance for smooth animations on capable devices
        return true
    }
    
    /// Whether animations should allow user interaction during execution
    public static var allowsUserInteractionDuringAnimation: Bool {
        return true
    }
}

// MARK: - Animation State Management

/// Tracks animation state for performance monitoring
@available(iOS 26.0, *)
public struct ToastAnimationState {
    public var isAnimating: Bool = false
    public var animationType: AnimationType = .none
    public var startTime: CFTimeInterval = 0
    public var frameCount: Int = 0
    
    public enum AnimationType {
        case none
        case appearance
        case dismissal
        case interactive
    }
    
    public mutating func startAnimation(_ type: AnimationType) {
        isAnimating = true
        animationType = type
        startTime = CACurrentMediaTime()
        frameCount = 0
    }
    
    public mutating func endAnimation() {
        isAnimating = false
        animationType = .none
        startTime = 0
        frameCount = 0
    }
    
    public var duration: CFTimeInterval {
        guard isAnimating else { return 0 }
        return CACurrentMediaTime() - startTime
    }
}

// MARK: - Gesture Configuration

/// Configuration for interactive dismissal gestures
@available(iOS 26.0, *)
public struct ToastGestureConfig {
    
    /// Minimum drag distance to trigger dismissal (30pt)
    public static let dismissalThreshold: CGFloat = 30
    
    /// Minimum velocity to trigger dismissal (200pt/s)
    public static let velocityThreshold: CGFloat = 200
    
    /// Maximum drag distance before clamping
    public static let maxDragDistance: CGFloat = 100
    
    /// Resistance factor for over-drag
    public static let dragResistance: CGFloat = 0.3
    
    /// Spring back animation when gesture is cancelled
    public static var springBackAnimation: Animation {
        .spring(response: 0.3, dampingFraction: 0.8)
    }
}