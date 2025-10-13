//
//  ReplyCard.swift
//  Agora
//
//  Created by Agora Team on 2024.
//

import SwiftUI
import DesignSystem

/// A card view displaying a reply to a post with author information and timestamp
struct ReplyCard: View {
    let reply: Reply
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.sm) {
            HStack(alignment: .top, spacing: SpacingTokens.sm) {
                // Author avatar placeholder
                Circle()
                    .fill(ColorTokens.agoraBrand)
                    .frame(width: 32, height: 32)
                    .overlay {
                        Text(String(reply.author.prefix(1)))
                            .font(TypographyScale.caption1)
                            .foregroundColor(.white)
                    }
                
                VStack(alignment: .leading, spacing: SpacingTokens.xxs) {
                    HStack(spacing: SpacingTokens.xs) {
                        Text(reply.authorDisplayHandle)
                            .font(TypographyScale.calloutEmphasized)
                            .foregroundColor(ColorTokens.primaryText)
                        
                        Text("·")
                            .font(TypographyScale.caption1)
                            .foregroundColor(ColorTokens.tertiaryText)
                        
                        Text(RelativeTimeFormatter.format(reply.timestamp))
                            .font(TypographyScale.caption1)
                            .foregroundColor(ColorTokens.tertiaryText)
                        
                        Spacer()
                    }
                    
                    Text(reply.text)
                        .font(TypographyScale.body)
                        .foregroundColor(ColorTokens.primaryText)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(SpacingTokens.md)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: SpacingTokens.sm))
        .overlay(
            RoundedRectangle(cornerRadius: SpacingTokens.sm)
                .stroke(ColorTokens.separator.opacity(0.2), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.03), radius: SpacingTokens.xxs, x: 0, y: 1)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .padding(.horizontal, SpacingTokens.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Reply by \(reply.author)")
        .accessibilityHint("Double tap to interact with this reply")
    }
}

#Preview("Reply Card") {
    ReplyCard(
        reply: Reply(
            text: "Great post! Thanks for sharing.",
            author: "Reply User",
            authorDisplayHandle: "@replyuser",
            timestamp: Date().addingTimeInterval(-1800)
        )
    )
}

#Preview("Reply Card - Recent") {
    ReplyCard(
        reply: Reply(
            text: "Just posted this reply a few seconds ago.",
            author: "Quick Replier",
            authorDisplayHandle: "@quickreplier",
            timestamp: Date()
        )
    )
}

#Preview("Reply Card - Long Text") {
    ReplyCard(
        reply: Reply(
            text: "This is a much longer reply that spans multiple lines to test how the card handles longer text content.",
            author: "Detailed User",
            authorDisplayHandle: "@detaileduser",
            timestamp: Date().addingTimeInterval(-300)
        )
    )
}

#Preview("Reply Card - Multiple in List") {
    VStack(spacing: SpacingTokens.md) {
        ReplyCard(
            reply: Reply(
                text: "First reply in the thread",
                author: "User One",
                authorDisplayHandle: "@userone",
                timestamp: Date().addingTimeInterval(-3600)
            )
        )
        
        ReplyCard(
            reply: Reply(
                text: "Second reply with more content",
                author: "User Two",
                authorDisplayHandle: "@usertwo",
                timestamp: Date().addingTimeInterval(-1800)
            )
        )
        
        ReplyCard(
            reply: Reply(
                text: "Third reply most recent",
                author: "User Three",
                authorDisplayHandle: "@userthree",
                timestamp: Date().addingTimeInterval(-900)
            )
        )
    }
}

