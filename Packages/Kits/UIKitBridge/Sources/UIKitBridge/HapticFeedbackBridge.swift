import Foundation

#if os(iOS)
import UIKit
#endif

/// HapticFeedbackBridge provides cross-platform haptic feedback functionality
@available(iOS 26.0, macOS 26.0, *)
public struct HapticFeedbackBridge {
    
    /// Haptic feedback styles available on iOS
    public enum Style {
        case light
        case medium
        case heavy
        case rigid
        case soft
    }
    
    /// Triggers haptic feedback with the specified style
    /// On non-iOS platforms, this is a no-op
    public static func impact(_ style: Style) {
        #if os(iOS)
        let impactFeedback = UIImpactFeedbackGenerator(style: uiStyle(for: style))
        impactFeedback.impactOccurred()
        #endif
    }
    
    /// Triggers selection haptic feedback
    /// On non-iOS platforms, this is a no-op
    public static func selection() {
        #if os(iOS)
        let selectionFeedback = UISelectionFeedbackGenerator()
        selectionFeedback.selectionChanged()
        #endif
    }
    
    /// Triggers notification haptic feedback
    /// On non-iOS platforms, this is a no-op
    public static func notification(_ type: NotificationFeedbackType) {
        #if os(iOS)
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(type.uiType)
        #endif
    }
    
    #if os(iOS)
    private static func uiStyle(for style: Style) -> UIImpactFeedbackGenerator.FeedbackStyle {
        switch style {
        case .light:
            return .light
        case .medium:
            return .medium
        case .heavy:
            return .heavy
        case .rigid:
            return .rigid
        case .soft:
            return .soft
        }
    }
    #endif
}

/// Notification feedback types for cross-platform usage
@available(iOS 26.0, macOS 26.0, *)
public enum NotificationFeedbackType {
    case success
    case warning
    case error
}

#if os(iOS)
extension NotificationFeedbackType {
    var uiType: UINotificationFeedbackGenerator.FeedbackType {
        switch self {
        case .success:
            return .success
        case .warning:
            return .warning
        case .error:
            return .error
        }
    }
}
#endif
