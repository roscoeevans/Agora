//
//  ReplyListView.swift
//  Agora
//
//  Created by Agora Team on 2024.
//

import SwiftUI
import DesignSystem
import AppFoundation
import Engagement

/// Displays a list of replies with nested threading (max 3-level indent)
/// Follows Twitter/Threads pattern: visual indent up to 3 levels, then shows "@username replying to @username"
public struct ReplyListView: View {
    let replies: [Post]
    let onReplyToReply: (Post) -> Void
    
    @Environment(\.deps) private var deps
    
    public init(
        replies: [Post],
        onReplyToReply: @escaping (Post) -> Void
    ) {
        self.replies = replies
        self.onReplyToReply = onReplyToReply
    }
    
    public var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(replies, id: \.id) { reply in
                ReplyRowView(
                    reply: reply,
                    onReplyTap: {
                        onReplyToReply(reply)
                    }
                )
                
                if reply.id != replies.last?.id {
                    Divider()
                        .padding(.leading, 52) // Align with content
                }
            }
        }
    }
}

/// Individual reply row with engagement actions
struct ReplyRowView: View {
    let reply: Post
    let onReplyTap: () -> Void
    
    @State private var engagementState: PostEngagementState?
    @Environment(\.deps) private var deps
    
    var body: some View {
        HStack(alignment: .top, spacing: SpacingTokens.sm) {
            // Author avatar
            Circle()
                .fill(ColorTokens.agoraBrand)
                .frame(width: 40, height: 40)
                .overlay {
                    Text(String((reply.authorDisplayName ?? reply.authorDisplayHandle).prefix(1)))
                        .font(TypographyScale.calloutEmphasized)
                        .foregroundColor(.white)
                }
            
            VStack(alignment: .leading, spacing: SpacingTokens.xs) {
                // Header: author and timestamp
                HStack(spacing: SpacingTokens.xs) {
                    Text("@\(reply.authorDisplayHandle)")
                        .font(TypographyScale.callout)
                        .fontWeight(.semibold)
                        .foregroundColor(ColorTokens.primaryText)
                    
                    Text("·")
                        .foregroundColor(ColorTokens.quaternaryText)
                    
                    Text(reply.createdAt, style: .relative)
                        .font(TypographyScale.caption1)
                        .foregroundColor(ColorTokens.tertiaryText)
                    
                    Spacer()
                }
                
                // Reply text
                Text(reply.text)
                    .font(TypographyScale.body)
                    .foregroundColor(ColorTokens.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Engagement bar
                if let state = engagementState {
                    HStack(spacing: SpacingTokens.lg) {
                        // Like button
                        EngagementButton(
                            icon: state.isLiked ? "heart.fill" : "heart",
                            count: state.likeCount,
                            isActive: state.isLiked,
                            isLoading: state.isLikingInProgress
                        ) {
                            Task { await state.toggleLike() }
                        }
                        
                        // Repost button
                        EngagementButton(
                            icon: "arrow.2.squarepath",
                            count: state.repostCount,
                            isActive: state.isReposted,
                            isLoading: state.isRepostingInProgress
                        ) {
                            Task { await state.toggleRepost() }
                        }
                        
                        // Reply button
                        EngagementButton(
                            icon: "bubble.right",
                            count: reply.replyCount,
                            isActive: false,
                            isLoading: false
                        ) {
                            onReplyTap()
                        }
                        
                        Spacer()
                    }
                    .padding(.top, SpacingTokens.xs)
                }
            }
        }
        .padding(SpacingTokens.md)
        .task {
            // Initialize engagement state using cache for persistence
            if let engagement = deps.engagement {
                engagementState = await EngagementStateCache.shared.getOrCreateState(
                    for: reply,
                    engagementService: engagement
                )
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Reply by \(reply.authorDisplayHandle)")
        .accessibilityHint("Double tap to reply to this comment")
    }
}

#if DEBUG
#Preview("Reply List") {
    PreviewDeps.scoped {
        ScrollView {
            ReplyListView(
                replies: [
                    Post(
                        id: "reply1",
                        authorId: "user1",
                        authorDisplayHandle: "firstuser",
                        text: "Great post! I totally agree with your point.",
                        likeCount: 5,
                        repostCount: 1,
                        replyCount: 2,
                        createdAt: Date().addingTimeInterval(-3600),
                        authorDisplayName: "First User"
                    ),
                    Post(
                        id: "reply2",
                        authorId: "user2",
                        authorDisplayHandle: "seconduser",
                        text: "Thanks for sharing this. Very insightful!",
                        likeCount: 3,
                        repostCount: 0,
                        replyCount: 0,
                        createdAt: Date().addingTimeInterval(-1800),
                        authorDisplayName: "Second User"
                    ),
                    Post(
                        id: "reply3",
                        authorId: "user3",
                        authorDisplayHandle: "thirduser",
                        text: "Can you elaborate more on this point? I'm curious to learn more about your perspective.",
                        likeCount: 1,
                        repostCount: 0,
                        replyCount: 1,
                        createdAt: Date().addingTimeInterval(-900),
                        authorDisplayName: "Third User"
                    )
                ],
                onReplyToReply: { _ in }
            )
        }
    }
}
#endif

