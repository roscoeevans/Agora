//
//  EngagementBar.swift
//  DesignSystem
//
//  Engagement bar with action buttons for posts
//

import SwiftUI

/// Engagement bar with action buttons
/// Displays reply, repost, like, and share actions with counts and states
public struct EngagementBar: View {
    let likeCount: Int
    let isLiked: Bool
    let isLikeLoading: Bool
    
    let repostCount: Int
    let isReposted: Bool
    let isRepostLoading: Bool
    
    let replyCount: Int
    
    let onLike: () -> Void
    let onRepost: () -> Void
    let onReply: () -> Void
    let onShare: () -> Void
    
    public init(
        likeCount: Int,
        isLiked: Bool = false,
        isLikeLoading: Bool = false,
        repostCount: Int,
        isReposted: Bool = false,
        isRepostLoading: Bool = false,
        replyCount: Int,
        onLike: @escaping () -> Void = {},
        onRepost: @escaping () -> Void = {},
        onReply: @escaping () -> Void = {},
        onShare: @escaping () -> Void = {}
    ) {
        self.likeCount = likeCount
        self.isLiked = isLiked
        self.isLikeLoading = isLikeLoading
        self.repostCount = repostCount
        self.isReposted = isReposted
        self.isRepostLoading = isRepostLoading
        self.replyCount = replyCount
        self.onLike = onLike
        self.onRepost = onRepost
        self.onReply = onReply
        self.onShare = onShare
    }
    
    public var body: some View {
        HStack(spacing: SpacingTokens.md) {
            // Like
            EngagementButton(
                icon: "heart",
                iconFilled: "heart.fill",
                count: likeCount,
                isActive: isLiked,
                isLoading: isLikeLoading,
                tintColor: .red,
                action: onLike
            )
            
            // Reply/Comment
            EngagementButton(
                icon: "bubble.left",
                count: replyCount,
                action: onReply
            )
            
            // Repost
            EngagementButton(
                icon: "arrow.2.squarepath",
                count: repostCount,
                isActive: isReposted,
                isLoading: isRepostLoading,
                tintColor: .green,
                action: onRepost
            )
            
            // Share
            EngagementButton(
                icon: "arrow.turn.up.right",
                count: 0,  // Share doesn't show count
                action: onShare
            )
            
            Spacer()
        }
        .padding(.top, SpacingTokens.xs)
    }
}

// MARK: - Previews

#Preview("Engagement Bar") {
    VStack(spacing: SpacingTokens.md) {
        EngagementBar(
            likeCount: 42,
            repostCount: 8,
            replyCount: 12,
            onLike: { print("Like") },
            onRepost: { print("Repost") },
            onReply: { print("Reply") },
            onShare: { print("Share") }
        )
        
        Divider()
        
        EngagementBar(
            likeCount: 0,
            repostCount: 0,
            replyCount: 0,
            onLike: { print("Like") },
            onRepost: { print("Repost") },
            onReply: { print("Reply") },
            onShare: { print("Share") }
        )
    }
    .padding()
}

