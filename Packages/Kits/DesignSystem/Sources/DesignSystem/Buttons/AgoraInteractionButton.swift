//
//  AgoraInteractionButton.swift
//  Agora
//
//  Created by Agora Team on 2024.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// A standardized interaction button component for the Agora design system.
///
/// AgoraInteractionButton provides consistent styling for post interactions
/// like like, repost, and reply buttons following Apple's Human Interface Guidelines.
///
/// Example usage:
/// ```swift
/// AgoraInteractionButton(
///     icon: "heart",
///     count: 42,
///     action: { /* Handle like action */ }
/// )
/// ```
@available(iOS 26.0, *)
public struct AgoraInteractionButton: View {
    /// Visual style variants for the interaction button.
    public enum Style {
        /// Standard interaction button
        case standard
        /// Compact interaction button for tight layouts
        case compact
        /// Prominent interaction button with stronger emphasis
        case prominent
    }
    
    /// Interaction state for the button.
    public enum InteractionState {
        /// Default state - not interacted with
        case `default`
        /// Active state - user has interacted (liked, reposted, etc.)
        case active
        /// Disabled state - interaction not available
        case disabled
    }
    
    let icon: String
    let count: Int
    let style: Style
    let interactionState: InteractionState
    let action: () -> Void
    
    @State private var isPressed = false
    
    /// Creates a new AgoraInteractionButton.
    ///
    /// - Parameters:
    ///   - icon: SF Symbol name for the icon
    ///   - count: The count to display (0 or positive number)
    ///   - style: The visual style of the button. Defaults to `.standard`
    ///   - interactionState: The current interaction state. Defaults to `.default`
    ///   - action: The action to perform when the button is tapped
    public init(
        icon: String,
        count: Int = 0,
        style: Style = .standard,
        interactionState: InteractionState = .default,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.count = count
        self.style = style
        self.interactionState = interactionState
        self.action = action
    }
    
    public var body: some View {
        Button(action: {
            // Add haptic feedback
            #if canImport(UIKit)
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            #endif
            action()
        }) {
            HStack(spacing: spacing) {
                Image(systemName: icon)
                    .font(iconFont)
                    .symbolEffect(.bounce, value: isPressed)
                    .symbolVariant(interactionState == .active ? .fill : .none)
                
                if count > 0 {
                    Text("\(count)")
                        .font(countFont)
                }
            }
            .foregroundColor(foregroundColor)
            .frame(minWidth: minWidth, minHeight: minHeight)
            .contentShape(Rectangle()) // Make entire area tappable
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(AnimationTokens.easeInOut, value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .disabled(interactionState == .disabled)
        .opacity(interactionState == .disabled ? 0.6 : 1.0)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(accessibilityValue)
    }
    
    private var spacing: CGFloat {
        switch style {
        case .standard: return SpacingTokens.xxs
        case .compact: return SpacingTokens.xxxs
        case .prominent: return SpacingTokens.xs
        }
    }
    
    private var iconFont: Font {
        switch style {
        case .standard: return .system(size: IconSizeTokens.sm)
        case .compact: return .system(size: IconSizeTokens.xs)
        case .prominent: return .system(size: IconSizeTokens.md)
        }
    }
    
    private var countFont: Font {
        switch style {
        case .standard: return TypographyScale.caption1
        case .compact: return TypographyScale.caption2
        case .prominent: return TypographyScale.footnote
        }
    }
    
    private var minWidth: CGFloat {
        switch style {
        case .standard: return 44
        case .compact: return 36
        case .prominent: return 52
        }
    }
    
    private var minHeight: CGFloat {
        switch style {
        case .standard: return 44
        case .compact: return 36
        case .prominent: return 52
        }
    }
    
    private var foregroundColor: Color {
        switch interactionState {
        case .default: return ColorTokens.tertiaryText
        case .active: return activeColor
        case .disabled: return ColorTokens.quaternaryText
        }
    }
    
    private var activeColor: Color {
        switch icon {
        case "heart": return ColorTokens.error
        case "arrow.2.squarepath": return ColorTokens.success
        case "bubble.right": return ColorTokens.agoraBrand
        default: return ColorTokens.agoraBrand
        }
    }
    
    private var accessibilityLabel: String {
        switch icon {
        case "heart":
            return "Like post"
        case "arrow.2.squarepath":
            return "Repost"
        case "bubble.right":
            return "Reply to post"
        case "bookmark":
            return "Bookmark post"
        case "share":
            return "Share post"
        default:
            return "Interact with post"
        }
    }
    
    private var accessibilityValue: String {
        if count > 0 {
            return "\(count) \(icon == "heart" ? "likes" : icon == "arrow.2.squarepath" ? "reposts" : "replies")"
        } else {
            return ""
        }
    }
}

/// Convenience initializers for common interaction buttons
@available(iOS 26.0, *)
public extension AgoraInteractionButton {
    /// Creates a like button
    static func like(count: Int = 0, isLiked: Bool = false, action: @escaping () -> Void) -> AgoraInteractionButton {
        AgoraInteractionButton(
            icon: "heart",
            count: count,
            interactionState: isLiked ? .active : .default,
            action: action
        )
    }
    
    /// Creates a repost button
    static func repost(count: Int = 0, isReposted: Bool = false, action: @escaping () -> Void) -> AgoraInteractionButton {
        AgoraInteractionButton(
            icon: "arrow.2.squarepath",
            count: count,
            interactionState: isReposted ? .active : .default,
            action: action
        )
    }
    
    /// Creates a reply button
    static func reply(count: Int = 0, action: @escaping () -> Void) -> AgoraInteractionButton {
        AgoraInteractionButton(
            icon: "bubble.right",
            count: count,
            action: action
        )
    }
    
    /// Creates a bookmark button
    static func bookmark(isBookmarked: Bool = false, action: @escaping () -> Void) -> AgoraInteractionButton {
        AgoraInteractionButton(
            icon: "bookmark",
            interactionState: isBookmarked ? .active : .default,
            action: action
        )
    }
    
    /// Creates a share button
    static func share(action: @escaping () -> Void) -> AgoraInteractionButton {
        AgoraInteractionButton(
            icon: "square.and.arrow.up",
            action: action
        )
    }
}

#if DEBUG
@available(iOS 26.0, *)
struct AgoraInteractionButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: SpacingTokens.lg) {
            // Different styles
            HStack(spacing: SpacingTokens.lg) {
                AgoraInteractionButton(icon: "heart", count: 42, style: .standard) { }
                AgoraInteractionButton(icon: "heart", count: 42, style: .compact) { }
                AgoraInteractionButton(icon: "heart", count: 42, style: .prominent) { }
            }
            
            // Different interaction states
            HStack(spacing: SpacingTokens.lg) {
                AgoraInteractionButton(icon: "heart", count: 42, interactionState: .default) { }
                AgoraInteractionButton(icon: "heart", count: 42, interactionState: .active) { }
                AgoraInteractionButton(icon: "heart", count: 42, interactionState: .disabled) { }
            }
            
            // Common interaction buttons
            HStack(spacing: SpacingTokens.lg) {
                AgoraInteractionButton.like(count: 42, isLiked: false) { }
                AgoraInteractionButton.repost(count: 12, isReposted: true) { }
                AgoraInteractionButton.reply(count: 8) { }
                AgoraInteractionButton.bookmark(isBookmarked: false) { }
                AgoraInteractionButton.share { }
            }
            
            // Zero count buttons
            HStack(spacing: SpacingTokens.lg) {
                AgoraInteractionButton.like(count: 0) { }
                AgoraInteractionButton.repost(count: 0) { }
                AgoraInteractionButton.reply(count: 0) { }
            }
        }
        .padding(SpacingTokens.md)
        .background(ColorTokens.background)
        .previewDisplayName("Light Mode")
        
        VStack(spacing: SpacingTokens.lg) {
            // Different styles
            HStack(spacing: SpacingTokens.lg) {
                AgoraInteractionButton(icon: "heart", count: 42, style: .standard) { }
                AgoraInteractionButton(icon: "heart", count: 42, style: .compact) { }
                AgoraInteractionButton(icon: "heart", count: 42, style: .prominent) { }
            }
            
            // Different interaction states
            HStack(spacing: SpacingTokens.lg) {
                AgoraInteractionButton(icon: "heart", count: 42, interactionState: .default) { }
                AgoraInteractionButton(icon: "heart", count: 42, interactionState: .active) { }
                AgoraInteractionButton(icon: "heart", count: 42, interactionState: .disabled) { }
            }
            
            // Common interaction buttons
            HStack(spacing: SpacingTokens.lg) {
                AgoraInteractionButton.like(count: 42, isLiked: false) { }
                AgoraInteractionButton.repost(count: 12, isReposted: true) { }
                AgoraInteractionButton.reply(count: 8) { }
                AgoraInteractionButton.bookmark(isBookmarked: false) { }
                AgoraInteractionButton.share { }
            }
            
            // Zero count buttons
            HStack(spacing: SpacingTokens.lg) {
                AgoraInteractionButton.like(count: 0) { }
                AgoraInteractionButton.repost(count: 0) { }
                AgoraInteractionButton.reply(count: 0) { }
            }
        }
        .padding(SpacingTokens.md)
        .background(ColorTokens.background)
        .preferredColorScheme(.dark)
        .previewDisplayName("Dark Mode")
    }
}
#endif


