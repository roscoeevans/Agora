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
    
    @State private var engagementState: PostEngagementState?
    @State private var showCommentSheet = false
    @State private var showShareMenu = false
    @State private var shareURL: URL?
    
    @Environment(\.deps) private var deps
    
    public init(
        post: Post,
        onAuthorTap: @escaping () -> Void = {}
    ) {
        self.post = post
        self.onAuthorTap = onAuthorTap
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
            VStack(alignment: .leading, spacing: SpacingTokens.sm) {
                // Header row: Handle, timestamp, edited indicator
                HStack(alignment: .firstTextBaseline, spacing: SpacingTokens.xxs) {
                    Text("@\(post.authorDisplayHandle)")
                        .font(TypographyScale.callout)
                        .fontWeight(.semibold)
                        .foregroundColor(ColorTokens.primaryText)
                    
                    // TODO: Add verification badge when available
                    // TODO: Add @ symbol badge when available
                    
                    Text("·")
                        .foregroundColor(ColorTokens.quaternaryText)
                    
                    Text(formatTimestamp(post.createdAt))
                        .font(TypographyScale.caption1)
                        .foregroundColor(ColorTokens.tertiaryText)
                    
                    if post.editedAt != nil {
                        Text("·")
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
                
                // Post text
                Text(post.text)
                    .font(TypographyScale.body)
                    .foregroundColor(ColorTokens.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
                
                // TODO: Add media display when ImageGridView is ready
                // TODO: Add link preview when LinkPreviewDisplayCard is ready
                // TODO: Add quoted post when QuotedPostCard is ready
                
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
                        onReply: { showCommentSheet = true },
                        onShare: { Task { await handleShare() } }
                    )
                }
            }
        }
        .padding(SpacingTokens.md)
        .background(ColorTokens.background)
        .task {
            // Initialize engagement state
            if let engagement = deps.engagement {
                engagementState = PostEngagementState(
                    post: post,
                    engagementService: engagement
                )
            }
        }
        .sheet(isPresented: $showCommentSheet) {
            CommentSheet(post: post, onDismiss: { showCommentSheet = false })
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
        guard let service = deps.engagement as? any EngagementServiceProtocol else {
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
    PreviewDeps.scoped {
        ScrollView {
            FeedPostView(post: PreviewFixtures.shortPost)
                .padding()
        }
        .background(ColorTokens.background)
    }
}
//
//#Preview("Long Post - Light") {
//    PreviewDeps.scoped {
//        ScrollView {
//            FeedPostView(post: PreviewFixtures.longPost)
//                .padding()
//        }
//        .background(ColorTokens.background)
//    }
//}
//
//#Preview("Popular Post - Dark") {
//    PreviewDeps.scopedDark {
//        ScrollView {
//            FeedPostView(post: PreviewFixtures.popularPost)
//                .padding()
//        }
//        .background(ColorTokens.background)
//    }
//}
//
//#Preview("Recent Post - Minimal Engagement") {
//    PreviewDeps.scoped {
//        ScrollView {
//            FeedPostView(post: PreviewFixtures.recentPost)
//                .padding()
//        }
//        .background(ColorTokens.background)
//    }
//}
//
//#Preview("Multiple Posts in Feed") {
//    PreviewDeps.scoped {
//        ScrollView {
//            LazyVStack(spacing: SpacingTokens.md) {
//                FeedPostView(post: PreviewFixtures.shortPost)
//                FeedPostView(post: PreviewFixtures.longPost)
//                FeedPostView(post: PreviewFixtures.popularPost)
//                FeedPostView(post: PreviewFixtures.recentPost)
//            }
//            .padding()
//        }
//        .background(ColorTokens.background)
//    }
//}
#endif


//#if DEBUG && canImport(SwiftUI)
////@available(iOS 26.0, *)
//#Preview("Sanity") { Text("Hello, previews") }
//#endif
