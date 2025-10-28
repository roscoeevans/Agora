//
//  EngagementButton.swift
//  DesignSystem
//
//  Individual engagement button with count, state, and animations
//

import SwiftUI

/// Animation style for engagement buttons
public enum AnimationStyle {
    case bounce
    case rotate
}

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
    let animationStyle: AnimationStyle
    let action: () -> Void
    
    @State private var isPressed = false
    @State private var animationTrigger = false
    @State private var hapticTrigger = 0
    @State private var rotationAngle: Angle = .zero
    
    public init(
        icon: String,
        iconFilled: String? = nil,
        count: Int,
        isActive: Bool = false,
        isLoading: Bool = false,  // Deprecated - optimistic UI doesn't show loading
        tintColor: Color? = nil,
        animationStyle: AnimationStyle = .bounce,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.iconFilled = iconFilled
        self.count = count
        self.isActive = isActive
        self.isLoading = isLoading
        self.tintColor = tintColor
        self.animationStyle = animationStyle
        self.action = action
    }
    
    public var body: some View {
        buttonContent
            .frame(minWidth: 44, alignment: .leading)
            .scaleEffect(isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isActive)
            .sensoryFeedback(.impact(weight: .light), trigger: hapticTrigger)
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                isPressed = pressing
            }, perform: {})
            .onChange(of: isActive) { oldValue, newValue in
                resetRotationIfNeeded(oldValue: oldValue, newValue: newValue)
            }
            .accessibilityLabel(accessibilityLabel)
            .accessibilityValue(count > 0 ? "\(count)" : "")
            .accessibilityHint(accessibilityHint)
    }
    
    private var buttonContent: some View {
        Button(action: handleButtonTap) {
            HStack(alignment: .center, spacing: SpacingTokens.xxs) {
                iconView
                countView
            }
            .foregroundColor(foregroundColor)
        }
    }
    
    @ViewBuilder
    private var iconView: some View {
        let currentIcon = isActive ? (iconFilled ?? icon) : icon
        
        if animationStyle == .rotate {
            // For rotate style, use rotation effect without discrete symbol effect
            Image(systemName: currentIcon)
                .font(.system(size: 16, weight: .regular))
                .rotationEffect(rotationAngle)
                .contentTransition(.symbolEffect(.replace))
        } else {
            // For bounce style, use bounce symbol effect
            Image(systemName: currentIcon)
                .font(.system(size: 16, weight: .regular))
                .symbolEffect(.bounce, value: animationTrigger)
                .contentTransition(.symbolEffect(.replace))
        }
    }
    
    @ViewBuilder
    private var countView: some View {
        if count > 0 {
            Text("\(count)")
                .font(TypographyScale.caption1)
                .contentTransition(.numericText())
        }
    }
    
    private func handleButtonTap() {
        hapticTrigger += 1
        animationTrigger.toggle()
        
        triggerRotationAnimationIfNeeded()
        action()
    }
    
    private func triggerRotationAnimationIfNeeded() {
        guard animationStyle == .rotate else { return }
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            rotationAngle = isActive ? .degrees(-180) : .degrees(180)
        }
    }
    
    private func resetRotationIfNeeded(oldValue: Bool, newValue: Bool) {
        guard animationStyle == .rotate && oldValue != newValue else { return }
        rotationAngle = .zero
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
        
        // Repost button - active (with rotation)
        EngagementButton(
            icon: "arrow.2.squarepath",
            count: 8,
            isActive: true,
            tintColor: .green,
            animationStyle: .rotate
        ) {
            print("Repost tapped")
        }
        
        // Repost button - inactive (with rotation)
        EngagementButton(
            icon: "arrow.2.squarepath",
            count: 7,
            isActive: false,
            tintColor: .green,
            animationStyle: .rotate
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

