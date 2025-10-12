//
//  AgoraCard.swift
//  Agora
//
//  Created by Agora Team on 2024.
//

import SwiftUI

/// A standardized card component for the Agora design system.
///
/// AgoraCard provides consistent styling and layout for content containers
/// following Apple's Human Interface Guidelines.
///
/// Example usage:
/// ```swift
/// AgoraCard {
///     Text("Card content")
/// }
/// ```
@available(iOS 26.0, *)
public struct AgoraCard<Content: View>: View {
    /// Visual style variants for the card.
    public enum Style {
        /// Standard card with subtle background and shadow
        case standard
        /// Prominent card with stronger visual emphasis
        case prominent
        /// Compact card for tight layouts
        case compact
        /// Floating card with elevated appearance
        case floating
    }
    
    /// Interaction behavior for the card.
    public enum Interaction {
        /// Static card with no interaction
        case none
        /// Tappable card with press feedback
        case tappable(() -> Void)
    }
    
    let style: Style
    let interaction: Interaction
    let content: () -> Content
    
    @State private var isPressed = false
    
    /// Creates a new AgoraCard.
    ///
    /// - Parameters:
    ///   - style: The visual style of the card. Defaults to `.standard`
    ///   - interaction: The interaction behavior. Defaults to `.none`
    ///   - content: The content to display inside the card
    public init(
        style: Style = .standard,
        interaction: Interaction = .none,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.style = style
        self.interaction = interaction
        self.content = content
    }
    
    public var body: some View {
        Group {
            switch interaction {
            case .none:
                cardContent
            case .tappable(let action):
                Button(action: {
                    // Add haptic feedback
                    #if canImport(UIKit)
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    #endif
                    action()
                }) {
                    cardContent
                }
                .buttonStyle(PlainButtonStyle())
                .scaleEffect(isPressed ? 0.98 : 1.0)
                .animation(AnimationTokens.easeInOut, value: isPressed)
                .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                    isPressed = pressing
                }, perform: {})
            }
        }
    }
    
    private var cardContent: some View {
        content()
            .padding(padding)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .agoraShadow(shadow)
    }
    
    private var padding: EdgeInsets {
        switch style {
        case .standard: return EdgeInsets(
            top: SpacingTokens.md,
            leading: SpacingTokens.md,
            bottom: SpacingTokens.md,
            trailing: SpacingTokens.md
        )
        case .prominent: return EdgeInsets(
            top: SpacingTokens.lg,
            leading: SpacingTokens.lg,
            bottom: SpacingTokens.lg,
            trailing: SpacingTokens.lg
        )
        case .compact: return EdgeInsets(
            top: SpacingTokens.sm,
            leading: SpacingTokens.sm,
            bottom: SpacingTokens.sm,
            trailing: SpacingTokens.sm
        )
        case .floating: return EdgeInsets(
            top: SpacingTokens.lg,
            leading: SpacingTokens.lg,
            bottom: SpacingTokens.lg,
            trailing: SpacingTokens.lg
        )
        }
    }
    
    private var backgroundColor: Color {
        switch style {
        case .standard: return ColorTokens.secondaryBackground
        case .prominent: return ColorTokens.tertiaryBackground
        case .compact: return ColorTokens.secondaryBackground
        case .floating: return ColorTokens.background
        }
    }
    
    private var cornerRadius: CGFloat {
        switch style {
        case .standard: return BorderRadiusTokens.sm
        case .prominent: return BorderRadiusTokens.md
        case .compact: return BorderRadiusTokens.xs
        case .floating: return BorderRadiusTokens.lg
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .standard, .compact: return ColorTokens.separator.opacity(0.3)
        case .prominent: return ColorTokens.separator.opacity(0.5)
        case .floating: return Color.clear
        }
    }
    
    private var borderWidth: CGFloat {
        switch style {
        case .standard, .compact: return 0.5
        case .prominent: return 1
        case .floating: return 0
        }
    }
    
    private var shadow: Shadow {
        switch style {
        case .standard: return ShadowTokens.subtle
        case .prominent: return ShadowTokens.standard
        case .compact: return ShadowTokens.subtle
        case .floating: return ShadowTokens.prominent
        }
    }
}

#if DEBUG
@available(iOS 26.0, *)
struct AgoraCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: SpacingTokens.lg) {
            // Different styles
            AgoraCard(style: .standard) {
                VStack(alignment: .leading, spacing: SpacingTokens.sm) {
                    Text("Standard Card")
                        .font(TypographyScale.headline)
                        .foregroundColor(ColorTokens.primaryText)
                    Text("This is a standard card with subtle styling.")
                        .font(TypographyScale.body)
                        .foregroundColor(ColorTokens.secondaryText)
                }
            }
            
            AgoraCard(style: .prominent) {
                VStack(alignment: .leading, spacing: SpacingTokens.sm) {
                    Text("Prominent Card")
                        .font(TypographyScale.headline)
                        .foregroundColor(ColorTokens.primaryText)
                    Text("This is a prominent card with stronger emphasis.")
                        .font(TypographyScale.body)
                        .foregroundColor(ColorTokens.secondaryText)
                }
            }
            
            AgoraCard(style: .compact) {
                HStack {
                    Text("Compact Card")
                        .font(TypographyScale.callout)
                        .foregroundColor(ColorTokens.primaryText)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: IconSizeTokens.sm))
                        .foregroundColor(ColorTokens.tertiaryText)
                }
            }
            
            AgoraCard(style: .floating) {
                VStack(alignment: .leading, spacing: SpacingTokens.sm) {
                    Text("Floating Card")
                        .font(TypographyScale.headline)
                        .foregroundColor(ColorTokens.primaryText)
                    Text("This card appears to float above the background.")
                        .font(TypographyScale.body)
                        .foregroundColor(ColorTokens.secondaryText)
                }
            }
            
            // Tappable card
            AgoraCard(style: .standard, interaction: .tappable {
                print("Card tapped!")
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: SpacingTokens.xs) {
                        Text("Tappable Card")
                            .font(TypographyScale.calloutEmphasized)
                            .foregroundColor(ColorTokens.primaryText)
                        Text("Tap me!")
                            .font(TypographyScale.caption1)
                            .foregroundColor(ColorTokens.secondaryText)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: IconSizeTokens.sm))
                        .foregroundColor(ColorTokens.tertiaryText)
                }
            }
        }
        .padding(SpacingTokens.md)
        .background(ColorTokens.background)
        .previewDisplayName("Light Mode")
        
        VStack(spacing: SpacingTokens.lg) {
            // Different styles
            AgoraCard(style: .standard) {
                VStack(alignment: .leading, spacing: SpacingTokens.sm) {
                    Text("Standard Card")
                        .font(TypographyScale.headline)
                        .foregroundColor(ColorTokens.primaryText)
                    Text("This is a standard card with subtle styling.")
                        .font(TypographyScale.body)
                        .foregroundColor(ColorTokens.secondaryText)
                }
            }
            
            AgoraCard(style: .prominent) {
                VStack(alignment: .leading, spacing: SpacingTokens.sm) {
                    Text("Prominent Card")
                        .font(TypographyScale.headline)
                        .foregroundColor(ColorTokens.primaryText)
                    Text("This is a prominent card with stronger emphasis.")
                        .font(TypographyScale.body)
                        .foregroundColor(ColorTokens.secondaryText)
                }
            }
            
            AgoraCard(style: .compact) {
                HStack {
                    Text("Compact Card")
                        .font(TypographyScale.callout)
                        .foregroundColor(ColorTokens.primaryText)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: IconSizeTokens.sm))
                        .foregroundColor(ColorTokens.tertiaryText)
                }
            }
            
            AgoraCard(style: .floating) {
                VStack(alignment: .leading, spacing: SpacingTokens.sm) {
                    Text("Floating Card")
                        .font(TypographyScale.headline)
                        .foregroundColor(ColorTokens.primaryText)
                    Text("This card appears to float above the background.")
                        .font(TypographyScale.body)
                        .foregroundColor(ColorTokens.secondaryText)
                }
            }
            
            // Tappable card
            AgoraCard(style: .standard, interaction: .tappable {
                print("Card tapped!")
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: SpacingTokens.xs) {
                        Text("Tappable Card")
                            .font(TypographyScale.calloutEmphasized)
                            .foregroundColor(ColorTokens.primaryText)
                        Text("Tap me!")
                            .font(TypographyScale.caption1)
                            .foregroundColor(ColorTokens.secondaryText)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: IconSizeTokens.sm))
                        .foregroundColor(ColorTokens.tertiaryText)
                }
            }
        }
        .padding(SpacingTokens.md)
        .background(ColorTokens.background)
        .preferredColorScheme(.dark)
        .previewDisplayName("Dark Mode")
    }
}
#endif


