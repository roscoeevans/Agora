//
//  PostDetailView.swift
//  Agora
//
//  Created by Agora Team on 2024.
//

import SwiftUI
import DesignSystem
import AppFoundation

/// Post view component displaying the main post with author information and interaction buttons
struct PostDetailView: View {
    let post: Post
    @Environment(\.deps) private var deps
    @State private var isPressed = false
    @State private var engagementState: PostEngagementState?
    
    var body: some View {
        styledPostCard
    }
    
    private var styledPostCard: some View {
        let cardShape = RoundedRectangle(cornerRadius: SpacingTokens.sm)
        let cardBorder = cardShape
            .stroke(ColorTokens.separator.opacity(0.3), lineWidth: 0.5)
        let errorBinding = Binding(
            get: { engagementState?.error != nil },
            set: { if !$0 { engagementState?.error = nil } }
        )
        
        return postCard
            .padding(SpacingTokens.md)
            .background(.regularMaterial, in: cardShape)
            .overlay(cardBorder)
            .shadow(color: .black.opacity(0.05), radius: SpacingTokens.xxs, x: 0, y: 2)
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                isPressed = pressing
            }, perform: {})
            .task(loadEngagementState)
            .alert("Action Failed", isPresented: errorBinding, presenting: engagementState?.error) { _ in
                Button("OK", role: .cancel) {}
            } message: { error in
                Text(error.localizedDescription)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityHint("Double tap to interact with this post")
    }
    
    private var postCard: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.md) {
            postHeader
            engagementSection
        }
    }
    
    private var postHeader: some View {
        HStack(alignment: .top, spacing: SpacingTokens.sm) {
            authorAvatar
            postContent
        }
    }
    
    private var authorAvatar: some View {
        Circle()
            .fill(ColorTokens.agoraBrand)
            .frame(width: 40, height: 40)
            .overlay {
                Text(String(authorInitial))
                    .font(TypographyScale.calloutEmphasized)
                    .foregroundColor(.white)
            }
    }
    
    private var authorInitial: String {
        (post.authorDisplayName ?? post.authorDisplayHandle).prefix(1).uppercased()
    }
    
    private var postContent: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.xxs) {
            authorInfoRow
            postText
        }
    }
    
    private var authorInfoRow: some View {
        HStack(spacing: SpacingTokens.xs) {
            Text(post.authorDisplayHandle)
                .font(TypographyScale.headline)
                .foregroundColor(ColorTokens.primaryText)
            
            Text("·")
                .font(TypographyScale.caption1)
                .foregroundColor(ColorTokens.tertiaryText)
            
            Text(post.createdAt, style: .relative)
                .font(TypographyScale.caption1)
                .foregroundColor(ColorTokens.tertiaryText)
            
            Spacer()
        }
    }
    
    private var postText: some View {
        Text(post.text)
            .font(TypographyScale.body)
            .foregroundColor(ColorTokens.primaryText)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    private var engagementSection: some View {
        HStack(spacing: SpacingTokens.xl) {
            engagementBar
            Spacer()
        }
        .padding(.top, SpacingTokens.xs)
        .padding(.leading, 52) // Align with post content (40pt avatar + 12pt spacing)
    }
    
    @ViewBuilder
    private var engagementBar: some View {
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
                onReply: { /* TODO: Implement reply */ }
            ) {
                shareButton
            }
        } else {
            fallbackEngagementButtons
        }
    }
    
    private var shareButton: some View {
        Button {
            // TODO: Implement share
        } label: {
            Image(systemName: "arrow.turn.up.right")
                .foregroundStyle(.secondary)
        }
    }
    
    private var fallbackEngagementButtons: some View {
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
    }
    
    private var accessibilityLabel: String {
        "Post by \(post.authorDisplayName ?? post.authorDisplayHandle)"
    }
    
    @Sendable
    private func loadEngagementState() async {
        guard let engagement = deps.engagement else { return }
        engagementState = await EngagementStateCache.shared.getOrCreateState(
            for: post,
            engagementService: engagement
        )
    }
}

#Preview("Post Detail View") {
    PostDetailView(
        post: Post(
            id: "1",
            authorId: "user1",
            authorDisplayHandle: "sampleauthor",
            text: "This is a detailed view of a post with all the interactions.",
            likeCount: 42,
            repostCount: 7,
            replyCount: 3,
            createdAt: Date().addingTimeInterval(-3600),
            authorDisplayName: "Sample Author"
        )
    )
    .padding()
}

#Preview("Post Detail View - No Interactions") {
    PostDetailView(
        post: Post(
            id: "2",
            authorId: "user2",
            authorDisplayHandle: "newuser",
            text: "A brand new post with no interactions yet.",
            likeCount: 0,
            repostCount: 0,
            replyCount: 0,
            createdAt: Date(),
            authorDisplayName: "New User"
        )
    )
    .padding()
}

#Preview("Post Detail View - Long Text") {
    PostDetailView(
        post: Post(
            id: "3",
            authorId: "user3",
            authorDisplayHandle: "verboseuser",
            text: "This is a much longer post to test how the card handles multi-line text content properly.",
            likeCount: 128,
            repostCount: 15,
            replyCount: 24,
            createdAt: Date().addingTimeInterval(-7200),
            authorDisplayName: "Verbose User"
        )
    )
    .padding()
}

