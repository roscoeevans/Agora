//
//  PostDetailCard.swift
//  Agora
//
//  Created by Agora Team on 2024.
//

import SwiftUI
import DesignSystem

/// A card view displaying the main post details with author information and interaction buttons
struct PostDetailCard: View {
    let post: Post
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.md) {
            HStack(alignment: .top, spacing: SpacingTokens.sm) {
                // Author avatar placeholder
                Circle()
                    .fill(ColorTokens.agoraBrand)
                    .frame(width: 40, height: 40)
                    .overlay {
                        Text(String(post.author.prefix(1)))
                            .font(TypographyScale.calloutEmphasized)
                            .foregroundColor(.white)
                    }
                
                VStack(alignment: .leading, spacing: SpacingTokens.xxs) {
                    HStack(spacing: SpacingTokens.xs) {
                        Text(post.authorDisplayHandle)
                            .font(TypographyScale.headline)
                            .foregroundColor(ColorTokens.primaryText)
                        
                        Text("·")
                            .font(TypographyScale.caption1)
                            .foregroundColor(ColorTokens.tertiaryText)
                        
                        Text(RelativeTimeFormatter.format(post.timestamp))
                            .font(TypographyScale.caption1)
                            .foregroundColor(ColorTokens.tertiaryText)
                        
                        Spacer()
                    }
                    
                    Text(post.text)
                        .font(TypographyScale.body)
                        .foregroundColor(ColorTokens.primaryText)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            HStack(spacing: SpacingTokens.xl) {
                InteractionButtonView(
                    icon: "heart",
                    count: post.likeCount,
                    action: { /* TODO: Implement like */ }
                )
                
                InteractionButtonView(
                    icon: "arrow.2.squarepath",
                    count: post.repostCount,
                    action: { /* TODO: Implement repost */ }
                )
                
                InteractionButtonView(
                    icon: "bubble.right",
                    count: post.replyCount,
                    action: { /* TODO: Implement reply */ }
                )
                
                InteractionButtonView(
                    icon: "square.and.arrow.up",
                    count: 0,
                    action: { /* TODO: Implement share */ }
                )
                
                Spacer()
            }
            .padding(.top, SpacingTokens.xs)
            .padding(.leading, 52) // Align with post content (40pt avatar + 12pt spacing)
        }
        .padding(SpacingTokens.md)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: SpacingTokens.sm))
        .overlay(
            RoundedRectangle(cornerRadius: SpacingTokens.sm)
                .stroke(ColorTokens.separator.opacity(0.3), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.05), radius: SpacingTokens.xxs, x: 0, y: 2)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Post by \(post.author)")
        .accessibilityHint("Double tap to interact with this post")
    }
}

#Preview("Post Detail Card") {
    PostDetailCard(
        post: Post(
            text: "This is a detailed view of a post with all the interactions.",
            author: "Sample Author",
            authorDisplayHandle: "@sampleauthor",
            timestamp: Date().addingTimeInterval(-3600),
            likeCount: 42,
            repostCount: 7,
            replyCount: 3
        )
    )
    .padding()
}

#Preview("Post Detail Card - No Interactions") {
    PostDetailCard(
        post: Post(
            text: "A brand new post with no interactions yet.",
            author: "New User",
            authorDisplayHandle: "@newuser",
            timestamp: Date(),
            likeCount: 0,
            repostCount: 0,
            replyCount: 0
        )
    )
    .padding()
}

#Preview("Post Detail Card - Long Text") {
    PostDetailCard(
        post: Post(
            text: "This is a much longer post to test how the card handles multi-line text content properly.",
            author: "Verbose User",
            authorDisplayHandle: "@verboseuser",
            timestamp: Date().addingTimeInterval(-7200),
            likeCount: 128,
            repostCount: 15,
            replyCount: 24
        )
    )
    .padding()
}

