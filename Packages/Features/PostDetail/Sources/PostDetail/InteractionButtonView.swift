//
//  InteractionButtonViewView.swift
//  Agora
//
//  Created by Agora Team on 2024.
//

import SwiftUI
import DesignSystem

/// A button view for post interactions (like, repost, reply) with haptic feedback
struct InteractionButtonView: View {
    let icon: String
    let count: Int
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            // Add haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            action()
        }) {
            HStack(spacing: SpacingTokens.xxs) {
                Image(systemName: icon)
                    .font(TypographyScale.callout)
                    .symbolEffect(.bounce, value: isPressed)
                
                if count > 0 {
                    Text("\(count)")
                        .font(TypographyScale.callout)
                }
            }
            .foregroundColor(ColorTokens.tertiaryText)
            .frame(minWidth: 44, minHeight: 44) // Ensure 44x44pt touch target
            .contentShape(Rectangle()) // Make entire area tappable
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(accessibilityValue)
    }
    
    private var accessibilityLabel: String {
        switch icon {
        case "heart":
            return "Like post"
        case "arrow.2.squarepath":
            return "Repost"
        case "bubble.right":
            return "Reply to post"
        case "square.and.arrow.up":
            return "Share post"
        default:
            return "Interact with post"
        }
    }
    
    private var accessibilityValue: String {
        if count > 0 {
            let countType: String
            switch icon {
            case "heart":
                countType = "likes"
            case "arrow.2.squarepath":
                countType = "reposts"
            case "bubble.right":
                countType = "replies"
            default:
                countType = "interactions"
            }
            return "\(count) \(countType)"
        } else {
            return ""
        }
    }
}

#Preview("Like Button - No Interactions") {
    InteractionButtonView(
        icon: "heart",
        count: 0,
        action: { print("Like tapped") }
    )
    .padding()
}

#Preview("Like Button - With Count") {
    InteractionButtonView(
        icon: "heart",
        count: 42,
        action: { print("Like tapped") }
    )
    .padding()
}

#Preview("Repost Button") {
    InteractionButtonView(
        icon: "arrow.2.squarepath",
        count: 7,
        action: { print("Repost tapped") }
    )
    .padding()
}

#Preview("Reply Button") {
    InteractionButtonView(
        icon: "bubble.right",
        count: 15,
        action: { print("Reply tapped") }
    )
    .padding()
}

#Preview("Share Button") {
    InteractionButtonView(
        icon: "square.and.arrow.up",
        count: 0,
        action: { print("Share tapped") }
    )
    .padding()
}

#Preview("All Interaction Buttons") {
    HStack(spacing: SpacingTokens.xl) {
        InteractionButtonView(
            icon: "heart",
            count: 42,
            action: { print("Like tapped") }
        )
        
        InteractionButtonView(
            icon: "arrow.2.squarepath",
            count: 7,
            action: { print("Repost tapped") }
        )
        
        InteractionButtonView(
            icon: "bubble.right",
            count: 15,
            action: { print("Reply tapped") }
        )
        
        InteractionButtonView(
            icon: "square.and.arrow.up",
            count: 0,
            action: { print("Share tapped") }
        )
    }
    .padding()
}

#Preview("High Count Buttons") {
    HStack(spacing: SpacingTokens.xl) {
        InteractionButtonView(
            icon: "heart",
            count: 1234,
            action: { print("Like tapped") }
        )
        
        InteractionButtonView(
            icon: "arrow.2.squarepath",
            count: 567,
            action: { print("Repost tapped") }
        )
        
        InteractionButtonView(
            icon: "bubble.right",
            count: 890,
            action: { print("Reply tapped") }
        )
    }
    .padding()
}

