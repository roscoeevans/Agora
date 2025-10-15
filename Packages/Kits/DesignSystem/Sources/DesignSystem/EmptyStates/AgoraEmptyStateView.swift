//
//  AgoraEmptyStateView.swift
//  Agora
//
//  Created by Agora Team on 2024.
//

import SwiftUI

/// A standardized empty state view component for the Agora design system.
///
/// AgoraEmptyStateView provides consistent empty states and messaging
/// following Apple's Human Interface Guidelines.
///
/// Example usage:
/// ```swift
/// AgoraEmptyStateView(
///     icon: "sparkles",
///     title: "Welcome to For You",
///     message: "Your personalized feed will appear here."
/// )
/// ```
@available(iOS 26.0, *)
public struct AgoraEmptyStateView: View {
    /// Visual style variants for the empty state view.
    public enum Style {
        /// Standard empty state with icon, title, and message
        case standard
        /// Compact empty state for smaller areas
        case compact
        /// Prominent empty state with larger visual elements
        case prominent
    }
    
    let icon: String
    let title: String
    let message: String?
    let actionTitle: String?
    let action: (() -> Void)?
    let style: Style
    
    /// Creates a new AgoraEmptyStateView.
    ///
    /// - Parameters:
    ///   - icon: SF Symbol name for the icon
    ///   - title: The main title text
    ///   - message: Optional descriptive message
    ///   - actionTitle: Optional action button title
    ///   - action: Optional action to perform when button is tapped
    ///   - style: The visual style of the empty state. Defaults to `.standard`
    public init(
        icon: String,
        title: String,
        message: String? = nil,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil,
        style: Style = .standard
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
        self.style = style
    }
    
    public var body: some View {
        VStack(spacing: spacing) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: iconSize))
                .foregroundColor(ColorTokens.agoraBrand)
                .symbolEffect(.pulse, isActive: true)
            
            // Title
            Text(title)
                .font(titleFont)
                .foregroundColor(ColorTokens.primaryText)
                .multilineTextAlignment(.center)
            
            // Message
            if let message = message {
                Text(message)
                    .font(messageFont)
                    .foregroundColor(ColorTokens.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
            
            // Action button
            if let actionTitle = actionTitle, let action = action {
                AgoraButton(actionTitle, style: .primary, action: action)
                    .padding(.top, SpacingTokens.sm)
            }
        }
        .padding(padding)
        .background(backgroundColor)
        .cornerRadius(cornerRadius)
        .agoraShadow(shadow)
    }
    
    private var spacing: CGFloat {
        switch style {
        case .standard: return SpacingTokens.lg
        case .compact: return SpacingTokens.md
        case .prominent: return SpacingTokens.xl
        }
    }
    
    private var iconSize: CGFloat {
        switch style {
        case .standard: return IconSizeTokens.huge
        case .compact: return IconSizeTokens.xl
        case .prominent: return IconSizeTokens.massive
        }
    }
    
    private var titleFont: Font {
        switch style {
        case .standard: return TypographyScale.title2
        case .compact: return TypographyScale.headline
        case .prominent: return TypographyScale.title1
        }
    }
    
    private var messageFont: Font {
        switch style {
        case .standard: return TypographyScale.body
        case .compact: return TypographyScale.callout
        case .prominent: return TypographyScale.body
        }
    }
    
    private var padding: EdgeInsets {
        switch style {
        case .standard: return EdgeInsets(
            top: SpacingTokens.xl,
            leading: SpacingTokens.lg,
            bottom: SpacingTokens.xl,
            trailing: SpacingTokens.lg
        )
        case .compact: return EdgeInsets(
            top: SpacingTokens.lg,
            leading: SpacingTokens.md,
            bottom: SpacingTokens.lg,
            trailing: SpacingTokens.md
        )
        case .prominent: return EdgeInsets(
            top: SpacingTokens.xxxl,
            leading: SpacingTokens.xl,
            bottom: SpacingTokens.xxxl,
            trailing: SpacingTokens.xl
        )
        }
    }
    
    private var backgroundColor: some ShapeStyle {
        switch style {
        case .standard: return .thinMaterial
        case .compact: return .regularMaterial
        case .prominent: return .thinMaterial
        }
    }
    
    private var cornerRadius: CGFloat {
        switch style {
        case .standard: return BorderRadiusTokens.lg
        case .compact: return BorderRadiusTokens.md
        case .prominent: return BorderRadiusTokens.xl
        }
    }
    
    private var shadow: Shadow {
        switch style {
        case .standard: return ShadowTokens.prominent
        case .compact: return ShadowTokens.standard
        case .prominent: return ShadowTokens.floating
        }
    }
}

/// Convenience initializers for common empty states
@available(iOS 26.0, *)
public extension AgoraEmptyStateView {
    /// Creates an empty state for an empty feed
    static func emptyFeed(action: @escaping () -> Void) -> AgoraEmptyStateView {
        AgoraEmptyStateView(
            icon: "checkmark.circle",
            title: "You're All Caught Up",
            message: "You've seen all the latest posts. Why not share something with the community?",
            actionTitle: "Create a Post",
            action: action
        )
    }
    
    /// Creates an empty state for an empty profile
    static func emptyProfile() -> AgoraEmptyStateView {
        AgoraEmptyStateView(
            icon: "person.circle",
            title: "Profile Not Found",
            message: "This profile may not exist or is no longer available.",
            style: .standard
        )
    }
    
    /// Creates an empty state for no search results
    static func noSearchResults() -> AgoraEmptyStateView {
        AgoraEmptyStateView(
            icon: "magnifyingglass",
            title: "No Results Found",
            message: "Try searching with different keywords or check your spelling.",
            style: .standard
        )
    }
    
    /// Creates an empty state for no notifications
    static func noNotifications() -> AgoraEmptyStateView {
        AgoraEmptyStateView(
            icon: "bell.slash",
            title: "No Notifications",
            message: "You're all caught up! New notifications will appear here.",
            style: .standard
        )
    }
    
    /// Creates an empty state for no DMs
    static func noDMs() -> AgoraEmptyStateView {
        AgoraEmptyStateView(
            icon: "message",
            title: "No Messages Yet",
            message: "Start a conversation by messaging someone!",
            actionTitle: "Find People to Message",
            action: {
                // TODO: Navigate to search or suggestions
            }
        )
    }
    
    /// Creates an empty state for network errors
    static func networkError(retryAction: @escaping () -> Void) -> AgoraEmptyStateView {
        AgoraEmptyStateView(
            icon: "wifi.slash",
            title: "Connection Problem",
            message: "Check your internet connection and try again.",
            actionTitle: "Try Again",
            action: retryAction
        )
    }
}

#if DEBUG
@available(iOS 26.0, *)
struct AgoraEmptyStateView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: SpacingTokens.lg) {
            // Different styles
            AgoraEmptyStateView(
                icon: "sparkles",
                title: "Standard Empty State",
                message: "This is a standard empty state with icon, title, and message.",
                actionTitle: "Take Action",
                action: { print("Action tapped!") }
            )
            
            AgoraEmptyStateView(
                icon: "person.circle",
                title: "Compact Empty State",
                message: "This is a compact empty state.",
                style: .compact
            )
            
            AgoraEmptyStateView(
                icon: "star",
                title: "Prominent Empty State",
                message: "This is a prominent empty state with larger visual elements.",
                actionTitle: "Get Started",
                action: { print("Get started tapped!") },
                style: .prominent
            )
            
            // Convenience initializers
            AgoraEmptyStateView.emptyFeed(action: { print("Create post tapped!") })
            AgoraEmptyStateView.noSearchResults()
        }
        .padding(SpacingTokens.md)
        .background(ColorTokens.background)
        .previewDisplayName("Light Mode")
        
        VStack(spacing: SpacingTokens.lg) {
            // Different styles
            AgoraEmptyStateView(
                icon: "sparkles",
                title: "Standard Empty State",
                message: "This is a standard empty state with icon, title, and message.",
                actionTitle: "Take Action",
                action: { print("Action tapped!") }
            )
            
            AgoraEmptyStateView(
                icon: "person.circle",
                title: "Compact Empty State",
                message: "This is a compact empty state.",
                style: .compact
            )
            
            AgoraEmptyStateView(
                icon: "star",
                title: "Prominent Empty State",
                message: "This is a prominent empty state with larger visual elements.",
                actionTitle: "Get Started",
                action: { print("Get started tapped!") },
                style: .prominent
            )
            
            // Convenience initializers
            AgoraEmptyStateView.emptyFeed(action: { print("Create post tapped!") })
            AgoraEmptyStateView.noSearchResults()
        }
        .padding(SpacingTokens.md)
        .background(ColorTokens.background)
        .preferredColorScheme(.dark)
        .previewDisplayName("Dark Mode")
    }
}
#endif
