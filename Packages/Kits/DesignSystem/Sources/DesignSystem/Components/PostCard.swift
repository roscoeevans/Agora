//
//  PostCard.swift
//  Agora
//
//  Reusable post display component
//

import SwiftUI

/// Post data model for display
public struct Post: Identifiable, Codable, Sendable {
    public let id: String
    public let authorId: String
    public let authorDisplayHandle: String
    public let authorDisplayName: String?
    public let authorAvatarUrl: String?
    public let text: String
    public let linkUrl: String?
    public let mediaBundleId: String?
    public let quotePostId: String?
    public let likeCount: Int
    public let repostCount: Int
    public let replyCount: Int
    public let createdAt: Date
    public let editedAt: Date?
    public let selfDestructAt: Date?
    
    public init(
        id: String,
        authorId: String,
        authorDisplayHandle: String,
        authorDisplayName: String? = nil,
        authorAvatarUrl: String? = nil,
        text: String,
        linkUrl: String? = nil,
        mediaBundleId: String? = nil,
        quotePostId: String? = nil,
        likeCount: Int = 0,
        repostCount: Int = 0,
        replyCount: Int = 0,
        createdAt: Date,
        editedAt: Date? = nil,
        selfDestructAt: Date? = nil
    ) {
        self.id = id
        self.authorId = authorId
        self.authorDisplayHandle = authorDisplayHandle
        self.authorDisplayName = authorDisplayName
        self.authorAvatarUrl = authorAvatarUrl
        self.text = text
        self.linkUrl = linkUrl
        self.mediaBundleId = mediaBundleId
        self.quotePostId = quotePostId
        self.likeCount = likeCount
        self.repostCount = repostCount
        self.replyCount = replyCount
        self.createdAt = createdAt
        self.editedAt = editedAt
        self.selfDestructAt = selfDestructAt
    }
}

/// Main post card component for displaying posts
public struct PostCard: View {
    let post: Post
    let onLike: () -> Void
    let onRepost: () -> Void
    let onReply: () -> Void
    let onShare: () -> Void
    let onAuthorTap: () -> Void
    
    public init(
        post: Post,
        onLike: @escaping () -> Void = {},
        onRepost: @escaping () -> Void = {},
        onReply: @escaping () -> Void = {},
        onShare: @escaping () -> Void = {},
        onAuthorTap: @escaping () -> Void = {}
    ) {
        self.post = post
        self.onLike = onLike
        self.onRepost = onRepost
        self.onReply = onReply
        self.onShare = onShare
        self.onAuthorTap = onAuthorTap
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.sm) {
            // Author info
            AuthorRow(
                displayHandle: post.authorDisplayHandle,
                displayName: post.authorDisplayName,
                avatarUrl: post.authorAvatarUrl,
                timestamp: post.createdAt,
                editedAt: post.editedAt,
                onTap: onAuthorTap
            )
            
            // Post text
            Text(post.text)
                .font(TypographyScale.body)
                .foregroundColor(ColorTokens.primaryText)
                .fixedSize(horizontal: false, vertical: true)
            
            // TODO: Add media display when ImageGridView is ready
            // TODO: Add link preview when LinkPreviewDisplayCard is ready
            // TODO: Add quoted post when QuotedPostCard is ready
            
            // Engagement bar
            EngagementBar(
                likeCount: post.likeCount,
                repostCount: post.repostCount,
                replyCount: post.replyCount,
                onLike: onLike,
                onRepost: onRepost,
                onReply: onReply,
                onShare: onShare
            )
        }
        .padding(SpacingTokens.md)
        .background(ColorTokens.background)
    }
}

/// Author row with avatar, handle, and timestamp
struct AuthorRow: View {
    let displayHandle: String
    let displayName: String?
    let avatarUrl: String?
    let timestamp: Date
    let editedAt: Date?
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: SpacingTokens.xs) {
            // Avatar
            Button(action: onTap) {
                if let avatarUrl = avatarUrl, let url = URL(string: avatarUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            placeholderAvatar
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            placeholderAvatar
                        @unknown default:
                            placeholderAvatar
                        }
                    }
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                } else {
                    placeholderAvatar
                }
            }
            .frame(width: 44, height: 44) // Ensure 44pt touch target
            
            // Name and handle
            VStack(alignment: .leading, spacing: 2) {
                if let displayName = displayName {
                    Text(displayName)
                        .font(TypographyScale.callout)
                        .fontWeight(.semibold)
                        .foregroundColor(ColorTokens.primaryText)
                }
                
                HStack(spacing: SpacingTokens.xxs) {
                    Text("@\(displayHandle)")
                        .font(TypographyScale.caption1)
                        .foregroundColor(ColorTokens.tertiaryText)
                    
                    Text("·")
                        .foregroundColor(ColorTokens.quaternaryText)
                    
                    Text(timestamp, style: .relative)
                        .font(TypographyScale.caption1)
                        .foregroundColor(ColorTokens.tertiaryText)
                    
                    if editedAt != nil {
                        Text("·")
                            .foregroundColor(ColorTokens.quaternaryText)
                        
                        HStack(spacing: 2) {
                            Image(systemName: "pencil.circle")
                            Text("Edited")
                        }
                        .font(TypographyScale.caption2)
                        .foregroundColor(ColorTokens.tertiaryText)
                    }
                }
            }
            
            Spacer()
        }
    }
    
    private var placeholderAvatar: some View {
        Circle()
            .fill(ColorTokens.separator.opacity(0.3))
            .frame(width: 40, height: 40)
            .overlay {
                Image(systemName: "person.fill")
                    .foregroundColor(ColorTokens.tertiaryText)
                    .font(.system(size: 18))
            }
    }
}

/// Engagement bar with action buttons
struct EngagementBar: View {
    let likeCount: Int
    let repostCount: Int
    let replyCount: Int
    let onLike: () -> Void
    let onRepost: () -> Void
    let onReply: () -> Void
    let onShare: () -> Void
    
    var body: some View {
        HStack(spacing: SpacingTokens.lg) {
            // Reply
            EngagementButton(
                icon: "bubble.left",
                count: replyCount,
                action: onReply
            )
            
            // Repost
            EngagementButton(
                icon: "arrow.2.squarepath",
                count: repostCount,
                action: onRepost
            )
            
            // Like
            EngagementButton(
                icon: "heart",
                count: likeCount,
                action: onLike
            )
            
            Spacer()
            
            // Share
            Button(action: onShare) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16))
                    .foregroundColor(ColorTokens.tertiaryText)
                    .frame(width: 44, height: 44) // Ensure 44pt touch target
            }
        }
        .padding(.top, SpacingTokens.xs)
    }
}

/// Individual engagement button with count
struct EngagementButton: View {
    let icon: String
    let count: Int
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            action()
        }) {
            HStack(spacing: SpacingTokens.xxs) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                
                if count > 0 {
                    Text("\(count)")
                        .font(TypographyScale.caption1)
                }
            }
            .foregroundColor(ColorTokens.tertiaryText)
            .frame(minWidth: 44, minHeight: 44) // Ensure 44pt touch target
        }
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Previews

#Preview("Post Card") {
    VStack(spacing: 0) {
        PostCard(
            post: Post(
                id: "1",
                authorId: "user1",
                authorDisplayHandle: "rocky.evans",
                authorDisplayName: "Rocky Evans",
                text: "Just shipped a new feature! The posting system is looking great with support for text, images, videos, and self-destruct. What do you think?",
                likeCount: 42,
                repostCount: 8,
                replyCount: 12,
                createdAt: Date().addingTimeInterval(-3600) // 1 hour ago
            )
        )
        
        Divider()
        
        PostCard(
            post: Post(
                id: "2",
                authorId: "user2",
                authorDisplayHandle: "jane.doe",
                text: "This is a shorter post.",
                likeCount: 5,
                repostCount: 1,
                replyCount: 2,
                createdAt: Date().addingTimeInterval(-7200), // 2 hours ago
                editedAt: Date().addingTimeInterval(-3600) // Edited 1 hour ago
            )
        )
    }
}

