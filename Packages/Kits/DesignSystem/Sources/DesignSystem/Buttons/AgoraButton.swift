//
//  AgoraButton.swift
//  Agora
//
//  Created by Agora Team on 2024.
//

import SwiftUI

/// A standardized button component for the Agora design system.
///
/// AgoraButton provides consistent styling, accessibility support, and haptic feedback
/// across different button styles and sizes.
///
/// Example usage:
/// ```swift
/// AgoraButton("Sign In", style: .primary) {
///     // Handle sign in action
/// }
/// ```
@available(iOS 26.0, *)
public struct AgoraButton: View {
    /// Visual style variants for the button.
    public enum Style {
        /// Primary action button with brand color background.
        case primary
        /// Secondary action button with brand color border.
        case secondary
        /// Tertiary action button with subtle background.
        case tertiary
        /// Destructive action button with error color.
        case destructive
        /// Ghost button with transparent background.
        case ghost
    }
    
    /// Size variants for the button.
    public enum Size {
        /// Small button (32pt height) for compact layouts.
        case small
        /// Medium button (44pt height) - standard iOS touch target.
        case medium
        /// Large button (56pt height) for prominent actions.
        case large
        
        var height: CGFloat {
            switch self {
            case .small: return 32
            case .medium: return 44 // Standard iOS touch target
            case .large: return 56
            }
        }
        
        var font: Font {
            switch self {
            case .small: return TypographyScale.footnote.weight(.semibold)
            case .medium: return TypographyScale.calloutEmphasized
            case .large: return TypographyScale.bodyEmphasized
            }
        }
        
        var horizontalPadding: CGFloat {
            switch self {
            case .small: return SpacingTokens.sm
            case .medium: return SpacingTokens.md
            case .large: return SpacingTokens.lg
            }
        }
    }
    
    let title: String
    let style: Style
    let size: Size
    let isEnabled: Bool
    let action: () -> Void
    
    @State private var hapticTrigger = 0
    
    /// Creates a new AgoraButton.
    ///
    /// - Parameters:
    ///   - title: The text displayed on the button.
    ///   - style: The visual style of the button. Defaults to `.primary`.
    ///   - size: The size of the button. Defaults to `.medium`.
    ///   - isEnabled: Whether the button is enabled. Defaults to `true`.
    ///   - action: The action to perform when the button is tapped.
    public init(
        _ title: String,
        style: Style = .primary,
        size: Size = .medium,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.size = size
        self.isEnabled = isEnabled
        self.action = action
    }
    
    public var body: some View {
        Button(action: {
            hapticTrigger += 1
            action()
        }) {
            Text(title)
                .font(size.font)
                .foregroundColor(foregroundColor)
                .frame(maxWidth: .infinity)
                .frame(height: size.height)
                .padding(.horizontal, size.horizontalPadding)
                .background(backgroundColor)
                .cornerRadius(BorderRadiusTokens.sm) // 8pt corner radius
                .overlay(
                    RoundedRectangle(cornerRadius: BorderRadiusTokens.sm)
                        .stroke(borderColor, lineWidth: borderWidth)
                )
        }
        .buttonStyle(AgoraButtonStyle())
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.6)
        .sensoryFeedback(.impact(weight: .light), trigger: hapticTrigger)
        .accessibility(label: Text(title))
        .accessibility(hint: Text(isEnabled ? "Tap to \(title.lowercased())" : "Button is disabled"))
        .accessibility(addTraits: isEnabled ? [] : .isButton)
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary:
            return .white
        case .secondary:
            return ColorTokens.agoraBrand
        case .tertiary:
            return ColorTokens.primaryText
        case .destructive:
            return .white
        case .ghost:
            return ColorTokens.agoraBrand
        }
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary:
            return ColorTokens.agoraBrand
        case .secondary:
            return ColorTokens.agoraBrand.opacity(0.1)
        case .tertiary:
            return ColorTokens.tertiaryBackground
        case .destructive:
            return ColorTokens.error
        case .ghost:
            return Color.clear
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .primary, .destructive:
            return Color.clear
        case .secondary:
            return ColorTokens.agoraBrand.opacity(0.3)
        case .tertiary:
            return ColorTokens.separator
        case .ghost:
            return ColorTokens.agoraBrand.opacity(0.5)
        }
    }
    
    private var borderWidth: CGFloat {
        switch style {
        case .primary, .destructive:
            return 0
        case .secondary, .tertiary, .ghost:
            return 1
        }
    }
}

// MARK: - Custom Button Style
@available(iOS 26.0, macOS 10.15, *)
private struct AgoraButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

#if DEBUG
@available(iOS 26.0, macOS 11.0, *)
struct AgoraButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: SpacingTokens.md) {
            // Different styles
            AgoraButton("Primary Button") { }
            AgoraButton("Secondary Button", style: .secondary) { }
            AgoraButton("Tertiary Button", style: .tertiary) { }
            AgoraButton("Destructive Button", style: .destructive) { }
            AgoraButton("Ghost Button", style: .ghost) { }
            
            Divider()
            
            // Different sizes
            AgoraButton("Small Button", size: .small) { }
            AgoraButton("Medium Button", size: .medium) { }
            AgoraButton("Large Button", size: .large) { }
            
            Divider()
            
            // Disabled state
            AgoraButton("Disabled Button", isEnabled: false) { }
        }
        .padding(SpacingTokens.md)
        .background(ColorTokens.background)
        .previewDisplayName("Light Mode")
        
        VStack(spacing: SpacingTokens.md) {
            // Different styles
            AgoraButton("Primary Button") { }
            AgoraButton("Secondary Button", style: .secondary) { }
            AgoraButton("Tertiary Button", style: .tertiary) { }
            AgoraButton("Destructive Button", style: .destructive) { }
            AgoraButton("Ghost Button", style: .ghost) { }
            
            Divider()
            
            // Different sizes
            AgoraButton("Small Button", size: .small) { }
            AgoraButton("Medium Button", size: .medium) { }
            AgoraButton("Large Button", size: .large) { }
            
            Divider()
            
            // Disabled state
            AgoraButton("Disabled Button", isEnabled: false) { }
        }
        .padding(SpacingTokens.md)
        .background(ColorTokens.background)
        .preferredColorScheme(.dark)
        .previewDisplayName("Dark Mode")
    }
}
#endif
