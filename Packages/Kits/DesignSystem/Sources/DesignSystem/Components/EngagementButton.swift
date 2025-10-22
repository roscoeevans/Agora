//
//  EngagementButton.swift
//  DesignSystem
//
//  Individual engagement button with count, state, and animations
//

import SwiftUI

#if os(iOS)
import UIKit
#endif

/// Individual engagement button with count, state, and animations
/// Uses optimistic UI updates - state changes immediately with haptic feedback
/// Provides instant visual feedback following Apple's design principles
public struct EngagementButton: View {
    let icon: String
    let iconFilled: String?  // e.g. "heart.fill" for active state
    let count: Int
    let isActive: Bool
    let isLoading: Bool  // Kept for API compatibility but no longer shown
    let tintColor: Color?
    let action: () -> Void
    
    @State private var isPressed = false
    @State private var animationTrigger = false
    
    public init(
        icon: String,
        iconFilled: String? = nil,
        count: Int,
        isActive: Bool = false,
        isLoading: Bool = false,  // Deprecated - optimistic UI doesn't show loading
        tintColor: Color? = nil,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.iconFilled = iconFilled
        self.count = count
        self.isActive = isActive
        self.isLoading = isLoading
        self.tintColor = tintColor
        self.action = action
    }
    
    public var body: some View {
        Button(action: {
            #if os(iOS)
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            #endif
            animationTrigger.toggle()
            action()
        }) {
            HStack(alignment: .center, spacing: SpacingTokens.xxs) {
                // Always show icon with animation - no loading spinner for optimistic UI
                // The state updates immediately, and if there's an error, it rolls back
                Image(systemName: isActive ? (iconFilled ?? icon) : icon)
                    .font(.system(size: 16, weight: .regular))
                    .symbolEffect(.bounce, value: animationTrigger)  // iOS 26 animation
                    .contentTransition(.symbolEffect(.replace))
                
                if count > 0 {
                    Text("\(count)")
                        .font(TypographyScale.caption1)
                        .contentTransition(.numericText())  // Smooth count changes
                }
            }
            .foregroundColor(foregroundColor)
        }
        .frame(minWidth: 44, alignment: .leading) // Natural height, 44pt min width for iOS touch target
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isActive)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(count > 0 ? "\(count)" : "")
        .accessibilityHint(accessibilityHint)
    }
    
    private var foregroundColor: Color {
        if isActive, let tintColor {
            return tintColor
        } else if isActive {
            return ColorTokens.accentPrimary
        } else {
            return ColorTokens.tertiaryText
        }
    }
    
    private var accessibilityLabel: String {
        switch icon {
        case "heart", "heart.fill":
            return isActive ? "Unlike" : "Like"
        case "arrow.2.squarepath":
            return isActive ? "Unrepost" : "Repost"
        case "bubble.left":
            return "Comment"
        case "arrow.turn.up.right":
            return "Share"
        default:
            return "Action"
        }
    }
    
    private var accessibilityHint: String {
        switch icon {
        case "heart", "heart.fill":
            return "Double tap to \(isActive ? "unlike" : "like") this post"
        case "arrow.2.squarepath":
            return "Double tap to \(isActive ? "unrepost" : "repost") this post"
        case "bubble.left":
            return "Double tap to open comments"
        case "arrow.turn.up.right":
            return "Double tap to share this post"
        default:
            return ""
        }
    }
}

// MARK: - Previews

#Preview("Engagement Buttons - States") {
    VStack(spacing: SpacingTokens.xl) {
        // Like button - active
        EngagementButton(
            icon: "heart",
            iconFilled: "heart.fill",
            count: 42,
            isActive: true,
            tintColor: .red
        ) {
            print("Like tapped")
        }
        
        // Like button - inactive
        EngagementButton(
            icon: "heart",
            iconFilled: "heart.fill",
            count: 41,
            isActive: false,
            tintColor: .red
        ) {
            print("Like tapped")
        }
        
        // Repost button - active
        EngagementButton(
            icon: "arrow.2.squarepath",
            count: 8,
            isActive: true,
            tintColor: .green
        ) {
            print("Repost tapped")
        }
        
        // Comment button
        EngagementButton(
            icon: "bubble.left",
            count: 15
        ) {
            print("Comment tapped")
        }
        
        // Share button (no count)
        EngagementButton(
            icon: "arrow.turn.up.right",
            count: 0
        ) {
            print("Share tapped")
        }
    }
    .padding()
}

