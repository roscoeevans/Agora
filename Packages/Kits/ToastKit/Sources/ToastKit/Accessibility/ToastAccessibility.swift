import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Accessibility utilities and helpers for toast notifications
@available(iOS 26.0, *)
public struct ToastAccessibility {
    
    // MARK: - VoiceOver Announcements
    
    /// Post VoiceOver announcement for toast presentation
    public static func announceToast(_ item: ToastItem) {
        #if canImport(UIKit) && !os(macOS)
        let notification: UIAccessibility.Notification = item.options.accessibilityPolite 
            ? .announcement 
            : .layoutChanged
        
        // Create comprehensive announcement text
        let announcementText = createAnnouncementText(for: item)
        
        DispatchQueue.main.async {
            UIAccessibility.post(notification: notification, argument: announcementText)
        }
        #endif
    }
    
    /// Create comprehensive announcement text for VoiceOver
    private static func createAnnouncementText(for item: ToastItem) -> String {
        var components: [String] = []
        
        // Add kind prefix for context
        switch item.kind {
        case .success:
            components.append("Success:")
        case .error:
            components.append("Error:")
        case .warning:
            components.append("Warning:")
        case .info:
            components.append("Information:")
        case .custom:
            components.append("Notification:")
        }
        
        // Add main message
        components.append(localizedString(from: item.message))
        
        // Add action hint if present
        if item.action != nil {
            components.append("Double tap to perform action.")
        } else {
            components.append("Double tap to dismiss.")
        }
        
        return components.joined(separator: " ")
    }
    
    /// Convert LocalizedStringKey to String for accessibility
    private static func localizedString(from key: LocalizedStringKey) -> String {
        // Use reflection to extract the key from LocalizedStringKey
        let mirror = Mirror(reflecting: key)
        if let keyValue = mirror.children.first(where: { $0.label == "key" })?.value as? String {
            return NSLocalizedString(keyValue, comment: "")
        }
        // Fallback: convert to string representation
        return "\(key)"
    }
    
    // MARK: - Dynamic Type Support
    
    /// Calculate appropriate font for current Dynamic Type size
    public static func adaptiveFont(
        for dynamicTypeSize: DynamicTypeSize,
        singleLine: Bool = true,
        hasAction: Bool = false
    ) -> Font {
        // Use larger font for single line when space allows
        if singleLine && dynamicTypeSize <= .large && !hasAction {
            return .title3.weight(.semibold)
        }
        
        // Use body font for multi-line or when space is constrained
        return .body.weight(.medium)
    }
    
    /// Calculate maximum lines for current Dynamic Type size
    public static func maxLines(for dynamicTypeSize: DynamicTypeSize) -> Int {
        // Allow more lines for larger text sizes
        switch dynamicTypeSize {
        case .xSmall, .small, .medium, .large:
            return 2
        case .xLarge, .xxLarge:
            return 3
        case .xxxLarge:
            return 4
        case .accessibility1, .accessibility2, .accessibility3, .accessibility4, .accessibility5:
            return 5
        @unknown default:
            return 4
        }
    }
    
    /// Determine if vertical layout should be used for accessibility
    public static func shouldUseVerticalLayout(
        dynamicTypeSize: DynamicTypeSize,
        hasAction: Bool
    ) -> Bool {
        // Use vertical layout for larger text sizes or when action is present
        return dynamicTypeSize >= .xxxLarge || (hasAction && dynamicTypeSize >= .xLarge)
    }
    
    // MARK: - Touch Target Sizing
    
    /// Minimum touch target size for accessibility compliance
    public static let minimumTouchTarget: CGSize = CGSize(width: 44, height: 44)
    
    /// Calculate appropriate button frame for accessibility
    public static func accessibleButtonFrame(
        content: CGSize,
        minimumSize: CGSize = minimumTouchTarget
    ) -> CGSize {
        return CGSize(
            width: max(content.width, minimumSize.width),
            height: max(content.height, minimumSize.height)
        )
    }
    
    // MARK: - Contrast and Transparency
    
    /// Get appropriate material for Reduce Transparency setting
    public static func adaptiveMaterial(
        reduceTransparency: Bool,
        colorScheme: ColorScheme
    ) -> Material {
        if reduceTransparency {
            // Use more opaque material when transparency is reduced
            return colorScheme == .dark ? .thick : .regular
        } else {
            // Use standard Liquid Glass material
            return .ultraThin
        }
    }
    
    /// Calculate contrast-safe text color
    public static func contrastSafeTextColor(
        for background: Color,
        colorScheme: ColorScheme,
        reduceTransparency: Bool
    ) -> Color {
        if reduceTransparency {
            // Use higher contrast colors when transparency is reduced
            return colorScheme == .dark ? .white : .black
        } else {
            // Use standard primary color with vibrancy
            return .primary
        }
    }
    
    /// Get shadow configuration that respects accessibility settings
    public static func accessibleShadow(
        reduceTransparency: Bool,
        colorScheme: ColorScheme,
        lowPowerMode: Bool
    ) -> (color: Color, radius: CGFloat, offset: CGFloat) {
        // Disable shadows in Low Power Mode or when transparency is reduced
        if lowPowerMode || reduceTransparency {
            return (.clear, 0, 0)
        }
        
        let shadowColor = Color.black.opacity(colorScheme == .dark ? 0.4 : 0.15)
        return (shadowColor, 8, 4)
    }
    
    // MARK: - Accessibility Labels and Hints
    
    /// Generate accessibility label for toast
    public static func accessibilityLabel(for item: ToastItem) -> String {
        var components: [String] = []
        
        // Add kind context
        switch item.kind {
        case .success:
            components.append("Success notification:")
        case .error:
            components.append("Error notification:")
        case .warning:
            components.append("Warning notification:")
        case .info:
            components.append("Information notification:")
        case .custom:
            components.append("Notification:")
        }
        
        // Add message
        components.append(localizedString(from: item.message))
        
        return components.joined(separator: " ")
    }
    
    /// Generate accessibility hint for toast
    public static func accessibilityHint(for item: ToastItem) -> String {
        if item.action != nil {
            return "Double tap to perform action, or swipe to dismiss"
        } else if item.options.allowsUserDismiss {
            return "Double tap to dismiss"
        } else {
            return "Will dismiss automatically"
        }
    }
    
    /// Generate accessibility actions for toast
    public static func accessibilityActions(
        for item: ToastItem,
        onAction: @escaping @MainActor @Sendable () -> Void,
        onDismiss: @escaping @MainActor @Sendable () -> Void
    ) -> some View {
        Group {
            // Primary action if available
            if let action = item.action {
                Button(action.title) {
                    onAction()
                }
            }
            
            // Dismiss action (always available for VoiceOver users)
            Button("Dismiss") {
                onDismiss()
            }
        }
    }
}

// MARK: - Accessibility Environment Values

@available(iOS 26.0, *)
public extension EnvironmentValues {
    /// Whether the current environment should use high contrast
    var toastHighContrast: Bool {
        accessibilityDifferentiateWithoutColor || accessibilityReduceTransparency
    }
    
    /// Whether motion should be reduced for toasts
    var toastReduceMotion: Bool {
        accessibilityReduceMotion
    }
    
    /// Whether transparency should be reduced for toasts
    var toastReduceTransparency: Bool {
        accessibilityReduceTransparency
    }
}

// MARK: - Accessibility Modifiers

@available(iOS 26.0, *)
public extension View {
    /// Apply comprehensive accessibility configuration to a toast view
    func toastAccessibility(
        item: ToastItem,
        onAction: @escaping @MainActor @Sendable () -> Void,
        onDismiss: @escaping @MainActor @Sendable () -> Void
    ) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel(ToastAccessibility.accessibilityLabel(for: item))
            .accessibilityHint(ToastAccessibility.accessibilityHint(for: item))
            .accessibilityActions {
                ToastAccessibility.accessibilityActions(
                    for: item,
                    onAction: onAction,
                    onDismiss: onDismiss
                )
            }
    }
    
    /// Ensure minimum touch target size for accessibility
    func accessibleTouchTarget(
        minimumSize: CGSize = ToastAccessibility.minimumTouchTarget
    ) -> some View {
        self.frame(
            minWidth: minimumSize.width,
            minHeight: minimumSize.height
        )
    }
}