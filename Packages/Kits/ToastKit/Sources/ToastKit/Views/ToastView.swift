import SwiftUI
import DesignSystem

/// SwiftUI toast notification view with iOS 26 Liquid Glass materials
@available(iOS 26.0, *)
public struct ToastView: View {
    let item: ToastItem
    let onDismiss: () -> Void
    let onAction: (() -> Void)?
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    @Environment(\.toastPerformanceManager) private var performanceManager
    
    public init(
        item: ToastItem,
        onDismiss: @escaping () -> Void,
        onAction: (() -> Void)? = nil
    ) {
        self.item = item
        self.onDismiss = onDismiss
        self.onAction = onAction
    }
    
    public var body: some View {
        liquidGlassContainer
            .frame(maxWidth: item.options.maxWidth ?? 600)
            .toastAccessibility(
                item: item,
                onAction: { onAction?() },
                onDismiss: onDismiss
            )
            .onTapGesture {
                if item.options.allowsUserDismiss {
                    onDismiss()
                }
            }
            .onAppear {
                // Post VoiceOver announcement when toast appears
                ToastAccessibility.announceToast(item)
            }
            .performanceOptimizedToast()
    }
}

// MARK: - Liquid Glass Container

@available(iOS 26.0, *)
private extension ToastView {
    var liquidGlassContainer: some View {
        ZStack {
            // Base Liquid Glass material
            liquidGlassMaterial
            
            // Content with vibrancy
            contentLayout
                .foregroundStyle(.primary)
                .blendMode(.overlay)
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .overlay(borderHighlight)
        .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowOffset)
    }
    
    var liquidGlassMaterial: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(baseMaterial)
            .overlay {
                // Subtle brand gradient for Liquid Glass effect
                LinearGradient(
                    colors: [
                        glassTintColor.opacity(0.1),
                        glassTintColor.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
    }
    
    var baseMaterial: Material {
        ToastAccessibility.adaptiveMaterial(
            reduceTransparency: reduceTransparency,
            colorScheme: colorScheme
        )
    }
    
    var glassTintColor: Color {
        switch item.kind {
        case .success:
            return ColorTokens.success
        case .error:
            return ColorTokens.error
        case .warning:
            return ColorTokens.warning
        case .info:
            return ColorTokens.info
        case .custom(_, let accent):
            return accent ?? ColorTokens.brandPrimary
        }
    }
    
    var borderHighlight: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .strokeBorder(
                .white.opacity(colorScheme == .dark ? 0.15 : 0.2),
                lineWidth: 0.5
            )
    }
}

// MARK: - Content Layout

@available(iOS 26.0, *)
private extension ToastView {
    var contentLayout: some View {
        Group {
            if shouldUseVerticalLayout {
                verticalLayout
            } else {
                horizontalLayout
            }
        }
        .padding(contentPadding)
    }
    
    var horizontalLayout: some View {
        HStack(spacing: SpacingTokens.sm) {
            iconView
            
            VStack(alignment: .leading, spacing: SpacingTokens.xxs) {
                messageText
            }
            
            Spacer(minLength: 0)
            
            actionButton
        }
    }
    
    var verticalLayout: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.xs) {
            HStack(spacing: SpacingTokens.sm) {
                iconView
                messageText
                Spacer(minLength: 0)
            }
            
            if item.action != nil {
                HStack {
                    Spacer()
                    actionButton
                }
            }
        }
    }
    
    var shouldUseVerticalLayout: Bool {
        ToastAccessibility.shouldUseVerticalLayout(
            dynamicTypeSize: dynamicTypeSize,
            hasAction: item.action != nil
        )
    }
}

// MARK: - Content Components

@available(iOS 26.0, *)
private extension ToastView {
    @ViewBuilder
    var iconView: some View {
        if let icon = item.kind.defaultIcon {
            icon
                .font(.system(size: IconSizeTokens.md, weight: .medium))
                .foregroundStyle(item.kind.defaultAccentColor)
                .frame(width: IconSizeTokens.md, height: IconSizeTokens.md)
                .accessibilityHidden(true)
        }
    }
    
    var messageText: some View {
        Text(item.message)
            .font(messageFont)
            .lineLimit(maxLines)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .foregroundStyle(accessibleTextColor)
            .accessibilityLabel(fullMessageForVoiceOver)
    }
    
    /// Full message text for VoiceOver when truncated
    private var fullMessageForVoiceOver: String {
        // Use reflection to extract string from LocalizedStringKey
        let mirror = Mirror(reflecting: item.message)
        if let keyValue = mirror.children.first(where: { $0.label == "key" })?.value as? String {
            return NSLocalizedString(keyValue, comment: "")
        }
        return "\(item.message)"
    }
    
    @ViewBuilder
    var actionButton: some View {
        if let action = item.action {
            Button(action: action.handler) {
                Text(action.title)
                    .font(actionFont)
                    .foregroundStyle(accessibleActionColor)
                    .padding(.horizontal, SpacingTokens.xs)
                    .padding(.vertical, SpacingTokens.xxs)
            }
            .buttonStyle(.plain)
            .accessibleTouchTarget()
            .accessibilityLabel(localizedString(from: action.title))
            .accessibilityHint("Performs the action for this notification")
        }
    }
}

// MARK: - Styling Properties

@available(iOS 26.0, *)
private extension ToastView {
    var cornerRadius: CGFloat {
        BorderRadiusTokens.lg // 16pt for modern iOS aesthetic
    }
    
    var contentPadding: EdgeInsets {
        EdgeInsets(
            top: SpacingTokens.sm,    // 12pt
            leading: SpacingTokens.md, // 16pt
            bottom: SpacingTokens.sm,  // 12pt
            trailing: SpacingTokens.md // 16pt
        )
    }
    
    var messageFont: Font {
        ToastAccessibility.adaptiveFont(
            for: dynamicTypeSize,
            singleLine: shouldUseSingleLineFont,
            hasAction: item.action != nil
        )
    }
    
    var actionFont: Font {
        TypographyScale.callout.weight(.semibold) // 16pt semibold
    }
    
    var shouldUseSingleLineFont: Bool {
        // Use title3 for single line messages, body for multi-line
        dynamicTypeSize <= .large && item.action == nil
    }
    
    var maxLines: Int {
        ToastAccessibility.maxLines(for: dynamicTypeSize)
    }
    
    var shadowColor: Color {
        let shadowConfig = performanceManager.adaptiveShadowConfig()
        #if canImport(UIKit) && !os(macOS)
        return Color(shadowConfig.color)
        #else
        return shadowConfig.color
        #endif
    }
    
    var shadowRadius: CGFloat {
        let shadowConfig = performanceManager.adaptiveShadowConfig()
        return shadowConfig.radius
    }
    
    var shadowOffset: CGFloat {
        let shadowConfig = performanceManager.adaptiveShadowConfig()
        return shadowConfig.offset.height
    }
    
    var respectsLowPowerMode: Bool {
        true // Always respect Low Power Mode for battery efficiency
    }
    
    /// Accessible text color that maintains contrast
    var accessibleTextColor: Color {
        ToastAccessibility.contrastSafeTextColor(
            for: glassTintColor,
            colorScheme: colorScheme,
            reduceTransparency: reduceTransparency
        )
    }
    
    /// Accessible action button color with proper contrast
    var accessibleActionColor: Color {
        if differentiateWithoutColor || reduceTransparency {
            // Use higher contrast color when accessibility settings are enabled
            return colorScheme == .dark ? .white : .black
        } else {
            // Use semantic color for the toast kind
            return item.kind.defaultAccentColor
        }
    }
    
    /// Convert LocalizedStringKey to String for accessibility
    private func localizedString(from key: LocalizedStringKey) -> String {
        let mirror = Mirror(reflecting: key)
        if let keyValue = mirror.children.first(where: { $0.label == "key" })?.value as? String {
            return NSLocalizedString(keyValue, comment: "")
        }
        return "\(key)"
    }
}



// MARK: - Preview Support

@available(iOS 26.0, *)
struct ToastView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: SpacingTokens.lg) {
            // Success toast
            ToastView(
                item: .success("Profile updated successfully"),
                onDismiss: {}
            )
            
            // Error toast with action
            ToastView(
                item: .error(
                    "Failed to upload image",
                    action: .retry {}
                ),
                onDismiss: {}
            )
            
            // Info toast
            ToastView(
                item: .info("New messages available"),
                onDismiss: {}
            )
            
            // Warning toast
            ToastView(
                item: .warning("Storage almost full"),
                onDismiss: {}
            )
            
            // Custom toast
            ToastView(
                item: ToastItem(
                    message: "Custom notification",
                    kind: .custom(
                        icon: Image(systemName: "star.fill"),
                        accent: ColorTokens.BrandPalette.goldenYellow
                    )
                ),
                onDismiss: {}
            )
        }
        .padding()
        .background(ColorTokens.background)
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Toast Variants")
    }
}

// MARK: - Accessibility Previews

@available(iOS 26.0, *)
struct ToastViewAccessibility_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Extra Large Dynamic Type
            VStack(spacing: SpacingTokens.lg) {
                ToastView(
                    item: .success("Profile updated successfully with a longer message that might wrap to multiple lines"),
                    onDismiss: {}
                )
                
                ToastView(
                    item: .error(
                        "Network connection failed with detailed error message",
                        action: .retry {}
                    ),
                    onDismiss: {}
                )
                
                ToastView(
                    item: .warning("Storage space is running low and needs attention"),
                    onDismiss: {}
                )
            }
            .padding()
            .background(ColorTokens.background)
            .environment(\.dynamicTypeSize, .xxxLarge)
            .previewDisplayName("xxxLarge Dynamic Type")
            
            // Reduce Transparency (simulated with different styling)
            VStack(spacing: SpacingTokens.lg) {
                ToastView(
                    item: .success("Profile updated"),
                    onDismiss: {}
                )
                
                ToastView(
                    item: .error(
                        "Upload failed",
                        action: .retry {}
                    ),
                    onDismiss: {}
                )
                
                ToastView(
                    item: .info("New messages available"),
                    onDismiss: {}
                )
            }
            .padding()
            .background(ColorTokens.background)
            .previewDisplayName("Reduce Transparency")
            
            // High Contrast (simulated styling)
            VStack(spacing: SpacingTokens.lg) {
                ToastView(
                    item: .warning("Battery low"),
                    onDismiss: {}
                )
                
                ToastView(
                    item: .error(
                        "Connection error",
                        action: .retry {}
                    ),
                    onDismiss: {}
                )
            }
            .padding()
            .background(ColorTokens.background)
            .previewDisplayName("High Contrast")
            
            // Dark Mode with Accessibility
            VStack(spacing: SpacingTokens.lg) {
                ToastView(
                    item: .success("Operation completed"),
                    onDismiss: {}
                )
                
                ToastView(
                    item: .info(
                        "Update available with new features and improvements",
                        action: ToastAction(title: "Update Now") {}
                    ),
                    onDismiss: {}
                )
            }
            .padding()
            .background(ColorTokens.background)
            .environment(\.colorScheme, .dark)
            .environment(\.dynamicTypeSize, .xxLarge)
            .previewDisplayName("Dark Mode + Accessibility")
        }
    }
}