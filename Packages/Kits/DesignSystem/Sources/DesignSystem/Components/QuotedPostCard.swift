//
//  QuotedPostCard.swift
//  DesignSystem
//
//  Compact quoted post display component
//

import SwiftUI
import AppFoundation
import UIKitBridge

/// Compact read-only quoted post display
public struct QuotedPostCard: View {
    let postId: String
    let onPostTap: () -> Void
    
    @State private var quotedPost: Post?
    @State private var isLoading = true
    @State private var error: Error?
    @State private var isPressed = false
    
    @Environment(\.deps) private var deps
    
    public init(postId: String, onPostTap: @escaping () -> Void = {}) {
        self.postId = postId
        self.onPostTap = onPostTap
    }
    
    public var body: some View {
        Button {
            DesignSystemBridge.lightImpact()
            onPostTap()
        } label: {
            VStack(alignment: .leading, spacing: SpacingTokens.sm) {
                if let post = quotedPost {
                    quotedPostContent(post)
                } else if isLoading {
                    loadingView
                } else {
                    errorView
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding(SpacingTokens.md)
        .background(ColorTokens.separator.opacity(0.1), in: RoundedRectangle(cornerRadius: BorderRadiusTokens.md))
        .overlay(
            RoundedRectangle(cornerRadius: BorderRadiusTokens.md)
                .stroke(ColorTokens.separator.opacity(0.3), lineWidth: 1)
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .task {
            await loadQuotedPost()
        }
        .accessibilityLabel("Quoted post by @\(quotedPost?.authorDisplayHandle ?? "unknown")")
    }
    
    private func quotedPostContent(_ post: Post) -> some View {
        VStack(alignment: .leading, spacing: SpacingTokens.sm) {
            // Author info
            HStack(spacing: SpacingTokens.xs) {
                // Avatar
                if let avatarUrl = post.authorAvatarUrl, let url = URL(string: avatarUrl) {
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
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                } else {
                    placeholderAvatar
                        .frame(width: 32, height: 32)
                }
                
                // Handle and timestamp
                VStack(alignment: .leading, spacing: 2) {
                    Text("@\(post.authorDisplayHandle)")
                        .font(TypographyScale.caption1)
                        .fontWeight(.semibold)
                        .foregroundColor(ColorTokens.primaryText)
                    
                    Text(formatTimestamp(post.createdAt))
                        .font(TypographyScale.caption2)
                        .foregroundColor(ColorTokens.tertiaryText)
                }
                
                Spacer()
            }
            
            // Post text (truncated)
            Text(post.text)
                .font(TypographyScale.callout)
                .foregroundColor(ColorTokens.secondaryText)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
            
            // Media thumbnail (if present)
            if let mediaBundleId = post.mediaBundleId {
                mediaThumbnail(mediaBundleId)
            }
        }
    }
    
    private var placeholderAvatar: some View {
        Circle()
            .fill(ColorTokens.separator.opacity(0.3))
            .overlay {
                Image(systemName: "person.fill")
                    .foregroundColor(ColorTokens.tertiaryText)
                    .font(.system(size: 14))
            }
    }
    
    private var loadingView: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.sm) {
            HStack(spacing: SpacingTokens.xs) {
                Circle()
                    .fill(ColorTokens.separator.opacity(0.3))
                    .frame(width: 32, height: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Rectangle()
                        .fill(ColorTokens.separator.opacity(0.3))
                        .frame(width: 80, height: 12)
                        .clipShape(RoundedRectangle(cornerRadius: 2))
                    
                    Rectangle()
                        .fill(ColorTokens.separator.opacity(0.2))
                        .frame(width: 60, height: 8)
                        .clipShape(RoundedRectangle(cornerRadius: 2))
                }
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Rectangle()
                    .fill(ColorTokens.separator.opacity(0.2))
                    .frame(height: 14)
                    .clipShape(RoundedRectangle(cornerRadius: 2))
                
                Rectangle()
                    .fill(ColorTokens.separator.opacity(0.2))
                    .frame(height: 14)
                    .clipShape(RoundedRectangle(cornerRadius: 2))
                
                Rectangle()
                    .fill(ColorTokens.separator.opacity(0.2))
                    .frame(width: 120, height: 14)
                    .clipShape(RoundedRectangle(cornerRadius: 2))
            }
        }
    }
    
    private var errorView: some View {
        HStack(spacing: SpacingTokens.xs) {
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(ColorTokens.tertiaryText)
                .font(.system(size: 16))
            
            Text("Unable to load quoted post")
                .font(TypographyScale.caption1)
                .foregroundColor(ColorTokens.tertiaryText)
        }
    }
    
    private func mediaThumbnail(_ mediaBundleId: String) -> some View {
        Rectangle()
            .fill(ColorTokens.separator.opacity(0.2))
            .frame(height: 60)
            .clipShape(RoundedRectangle(cornerRadius: BorderRadiusTokens.sm))
            .overlay {
                Image(systemName: "photo")
                    .foregroundColor(ColorTokens.tertiaryText)
                    .font(.system(size: 20))
            }
    }
    
    private func loadQuotedPost() async {
        // TODO: Implement actual post fetching using deps.networking
        // For now, create a mock post
        quotedPost = Post(
            id: postId,
            authorId: "mock-author",
            authorDisplayHandle: "quoted.user",
            text: "This is a quoted post that demonstrates how quoted content will appear in the feed. It should be truncated to show only the most important information.",
            linkUrl: nil,
            mediaBundleId: nil,
            replyToPostId: nil,
            quotePostId: nil,
            likeCount: 5,
            repostCount: 2,
            replyCount: 1,
            visibility: .public,
            createdAt: Date().addingTimeInterval(-3600), // 1 hour ago
            authorDisplayName: "Quoted User",
            authorAvatarUrl: nil,
            editedAt: nil,
            selfDestructAt: nil,
            score: 0,
            reasons: [],
            explore: false,
            isLikedByViewer: false,
            isRepostedByViewer: false
        )
        isLoading = false
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        
        if seconds < 60 {
            return "\(seconds)s"
        } else if seconds < 3600 {
            let minutes = seconds / 60
            return "\(minutes)m"
        } else if seconds < 86400 {
            let hours = seconds / 3600
            return "\(hours)h"
        } else {
            let days = seconds / 86400
            return "\(days)d"
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Quoted Post Card") {
    VStack(spacing: SpacingTokens.lg) {
        QuotedPostCard(
            postId: "mock-post-id",
            onPostTap: {
                print("Quoted post tapped")
            }
        )
        
        QuotedPostCard(
            postId: "loading-post-id",
            onPostTap: {
                print("Loading post tapped")
            }
        )
    }
    .padding()
    .background(ColorTokens.background)
}
#endif
