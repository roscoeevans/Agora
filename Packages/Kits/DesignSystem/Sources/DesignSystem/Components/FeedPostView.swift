//
//  FeedPostView.swift
//  DesignSystem
//
//  Reusable post display component for feeds
//

import SwiftUI
import AppFoundation

/// Post view component for displaying posts in feed lists
/// Uses AppFoundation.Post as the canonical domain model
public struct FeedPostView: View {
    let post: Post
    let onAuthorTap: () -> Void
    let onReply: () -> Void
    
    @State private var engagementState: PostEngagementState?
    @State private var showShareMenu = false
    @State private var shareURL: URL?
    
    @Environment(\.deps) private var deps
    
    public init(
        post: Post,
        onAuthorTap: @escaping () -> Void = {},
        onReply: @escaping () -> Void = {}
    ) {
        self.post = post
        self.onAuthorTap = onAuthorTap
        self.onReply = onReply
    }
    
    public var body: some View {
        HStack(alignment: .top, spacing: SpacingTokens.sm) {
            // Left column: Profile picture
            Button(action: onAuthorTap) {
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
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                } else {
                    placeholderAvatar
                }
            }
            .frame(width: 44, height: 44) // Ensure 44pt touch target
            
            // Right column: All content
            VStack(alignment: .leading, spacing: SpacingTokens.xs) {
                // Header row: Handle, timestamp, edited indicator
                HStack(alignment: .lastTextBaseline, spacing: SpacingTokens.xxs) {
                    Text(post.authorDisplayHandle)
                        .font(TypographyScale.body)
                        .fontWeight(.semibold)
                        .foregroundColor(ColorTokens.primaryText)
                    
                    // TODO: Add verification badge when available
                    // TODO: Add @ symbol badge when available
                    
                    Text("·")
                        .font(TypographyScale.body)
                        .foregroundColor(ColorTokens.quaternaryText)
                    
                    Text(formatTimestamp(post.createdAt))
                        .font(TypographyScale.body)
                        .foregroundColor(ColorTokens.tertiaryText)
                    
                    if post.editedAt != nil {
                        Text("·")
                            .font(TypographyScale.body)
                            .foregroundColor(ColorTokens.quaternaryText)
                        
                        HStack(spacing: 2) {
                            Image(systemName: "pencil.circle")
                            Text("Edited")
                        }
                        .font(TypographyScale.caption2)
                        .foregroundColor(ColorTokens.tertiaryText)
                    }
                    
                    Spacer()
                }
                
                // Post text with rich content (mentions, links)
                RichTextView(
                    text: post.text,
                    onMentionTap: { handle in
                        // Navigate to profile using handle
                        // TODO: Implement profile navigation
                        print("Mention tapped: @\(handle)")
                    },
                    onLinkTap: { url in
                        // Open in Safari
                        #if os(iOS)
                        UIApplication.shared.open(url)
                        #endif
                    }
                )
                
                // Media content (images/videos)
                if let mediaBundleId = post.mediaBundleId {
                    MediaContentView(
                        bundleId: mediaBundleId,
                        onImageTap: { index in
                            // Navigate to image gallery
                            // TODO: Get image URLs from bundle and navigate
                            print("Image tapped: \(index)")
                        },
                        onVideoTap: {
                            // Navigate to fullscreen video player
                            // TODO: Get video URL from bundle and navigate
                            print("Video tapped")
                        }
                    )
                }
                
                // Link preview
                if let linkUrl = post.linkUrl {
                    LinkPreviewDisplayCard(url: linkUrl)
                }
                
                // Quoted post
                if let quotePostId = post.quotePostId {
                    QuotedPostCard(
                        postId: quotePostId,
                        onPostTap: {
                            // TODO: Navigate to quoted post
                            print("Quoted post tapped")
                        }
                    )
                }
                
                // Engagement bar
                if let state = engagementState {
                    EngagementBar(
                        likeCount: state.likeCount,
                        isLiked: state.isLiked,
                        isLikeLoading: state.isLikingInProgress,
                        repostCount: state.repostCount,
                        isReposted: state.isReposted,
                        isRepostLoading: state.isRepostingInProgress,
                        replyCount: post.replyCount,
                        onLike: { Task { await state.toggleLike() } },
                        onRepost: { Task { await state.toggleRepost() } },
                        onReply: onReply,
                        onShare: { Task { await handleShare() } }
                    )
                }
            }
        }
        .padding(.vertical, SpacingTokens.xs)
        .background(ColorTokens.background)
        .task {
            // Initialize engagement state using cache for persistence
            if let engagement = deps.engagement {
                engagementState = await EngagementStateCache.shared.getOrCreateState(
                    for: post,
                    engagementService: engagement
                )
            }
        }
        .sheet(isPresented: $showShareMenu) {
            if let shareURL {
                ShareMenu(
                    post: post,
                    shareURL: shareURL,
                    onShareToDM: { /* TODO: Navigate to DM picker */ },
                    onDismiss: { showShareMenu = false }
                )
            }
        }
        .alert(
            "Action Failed",
            isPresented: Binding(
                get: { engagementState?.error != nil },
                set: { if !$0 { engagementState?.error = nil } }
            ),
            presenting: engagementState?.error
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { error in
            Text(error.localizedDescription)
        }
    }
    
    @MainActor
    private func handleShare() async {
        guard let service = deps.engagement else {
            return
        }
        
        do {
            shareURL = try await service.getShareURL(postId: post.id)
            showShareMenu = true
        } catch {
            // Handle error silently or show toast
            print("Failed to get share URL: \(error)")
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
    
    /// Format timestamp using Twitter-style relative time
    private func formatTimestamp(_ date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        
        if seconds < 5 {
            return "just now"
        } else if seconds < 60 {
            return "\(seconds) sec"
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
#Preview("Short Post - Light") {
    DesignSystemPreviewDeps.withEngagement {
        ScrollView {
            FeedPostView(post: PreviewFixtures.shortPost)
                .padding(.horizontal, SpacingTokens.sm)
        }
        .background(ColorTokens.background)
    }
}
#Preview("Long Post - Light") {
    DesignSystemPreviewDeps.withEngagement {
        ScrollView {
            FeedPostView(post: PreviewFixtures.longPost)
                .padding(.horizontal, SpacingTokens.sm)
        }
        .background(ColorTokens.background)
    }
}

#Preview("Popular Post - Dark") {
    DesignSystemPreviewDeps.withEngagementDark {
        ScrollView {
            FeedPostView(post: PreviewFixtures.popularPost)
                .padding(.horizontal, SpacingTokens.sm)
        }
        .background(ColorTokens.background)
    }
}

#Preview("Recent Post - Minimal Engagement") {
    DesignSystemPreviewDeps.withEngagement {
        ScrollView {
            FeedPostView(post: PreviewFixtures.recentPost)
                .padding(.horizontal, SpacingTokens.sm)
        }
        .background(ColorTokens.background)
    }
}

#Preview("Multiple Posts in Feed") {
    DesignSystemPreviewDeps.withEngagement {
        ScrollView {
            LazyVStack(spacing: 0) {
                FeedPostView(post: PreviewFixtures.shortPost)
                    .padding(.horizontal, SpacingTokens.sm)
                Divider()
                    .padding(.horizontal, SpacingTokens.sm)
                FeedPostView(post: PreviewFixtures.longPost)
                    .padding(.horizontal, SpacingTokens.sm)
                Divider()
                    .padding(.horizontal, SpacingTokens.sm)
                FeedPostView(post: PreviewFixtures.popularPost)
                    .padding(.horizontal, SpacingTokens.sm)
                Divider()
                    .padding(.horizontal, SpacingTokens.sm)
                FeedPostView(post: PreviewFixtures.recentPost)
                    .padding(.horizontal, SpacingTokens.sm)
            }
        }
        .background(ColorTokens.background)
    }
}
#endif


//#if DEBUG && canImport(SwiftUI)
////@available(iOS 26.0, *)
//#Preview("Sanity") { Text("Hello, previews") }
//#endif
