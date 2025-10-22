//
//  PostThreadView.swift
//  Agora
//
//  Created by Agora Team on 2024.
//

import SwiftUI
import DesignSystem
import AppFoundation

public struct PostThreadView: View {
    @Environment(\.deps) private var deps
    @State private var viewModel: ThreadViewModel?
    
    private let threadId: String
    
    public init(threadId: String) {
        self.threadId = threadId
    }
    
    public var body: some View {
        Group {
            if let viewModel = viewModel {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(viewModel.threadPosts.enumerated()), id: \.element.id) { index, post in
                            ThreadPostView(
                                post: post,
                                isLast: index == viewModel.threadPosts.count - 1
                            )
                        }
                    }
                }
                .navigationTitle("Thread")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .refreshable {
                    await viewModel.refresh()
                }
                .task {
                    await viewModel.loadThread()
                }
            } else {
                ProgressView()
            }
        }
        .task {
            // Initialize view model with dependencies from environment
            // Following DI rule: dependencies injected from environment
            self.viewModel = ThreadViewModel(threadId: threadId, networking: deps.networking)
        }
    }
}

struct ThreadPostView: View {
    let post: ThreadPost
    let isLast: Bool
    @Environment(\.deps) private var deps
    @State private var engagementState: PostEngagementState?
    
    var body: some View {
        HStack(alignment: .top, spacing: SpacingTokens.sm) {
            VStack {
                Circle()
                    .fill(ColorTokens.agoraBrand)
                    .frame(width: 32, height: 32)
                    .overlay {
                        Text(String(post.author.prefix(1)))
                            .font(TypographyScale.caption1)
                            .foregroundColor(.white)
                    }
                
                if !isLast {
                    Rectangle()
                        .fill(ColorTokens.separator)
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            
            VStack(alignment: .leading, spacing: SpacingTokens.xs) {
                HStack(spacing: SpacingTokens.xs) {
                    Text(post.authorDisplayHandle)
                        .font(TypographyScale.calloutEmphasized)
                        .foregroundColor(ColorTokens.primaryText)
                    
                    Text("·")
                        .font(TypographyScale.caption1)
                        .foregroundColor(ColorTokens.tertiaryText)
                    
                    Text(post.timestamp, style: .relative)
                        .font(TypographyScale.caption1)
                        .foregroundColor(ColorTokens.tertiaryText)
                    
                    Spacer()
                }
                
                Text(post.text)
                    .font(TypographyScale.body)
                    .foregroundColor(ColorTokens.primaryText)
                
                HStack(spacing: SpacingTokens.lg) {
                    // Engagement bar
                    if let state = engagementState {
                        EngagementBar(
                            likeCount: state.likeCount,
                            isLiked: state.isLiked,
                            isLikeLoading: state.isLikingInProgress,
                            repostCount: state.repostCount,
                            isReposted: state.isReposted,
                            isRepostLoading: state.isRepostingInProgress,
                            replyCount: 0, // ThreadPost doesn't have reply count
                            onLike: { Task { await state.toggleLike() } },
                            onRepost: { Task { await state.toggleRepost() } },
                            onReply: { /* TODO: Implement reply */ },
                            onShare: { /* TODO: Implement share */ }
                        )
                    } else {
                        // Fallback to static buttons while loading
                        HStack(spacing: SpacingTokens.lg) {
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
                                count: 0,
                                action: { /* TODO: Implement reply */ }
                            )
                            
                            Spacer()
                        }
                    }
                }
                .padding(.bottom, SpacingTokens.md)
            }
        }
        .padding(.horizontal, SpacingTokens.md)
        .task {
            // Initialize engagement state
            if let engagement = deps.engagement {
                // Convert ThreadPost to Post for engagement state
                let postForEngagement = Post(
                    id: post.id,
                    authorId: post.author, // Using author as authorId for now
                    authorDisplayHandle: post.authorDisplayHandle,
                    text: post.text,
                    likeCount: post.likeCount,
                    repostCount: post.repostCount,
                    replyCount: 0,
                    createdAt: post.timestamp,
                    authorDisplayName: post.author,
                    isLikedByViewer: false, // Default to false for now
                    isRepostedByViewer: false
                )
                
                engagementState = PostEngagementState(
                    post: postForEngagement,
                    engagementService: engagement
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
}

struct InteractionButtonView: View {
    let icon: String
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: SpacingTokens.xxs) {
                Image(systemName: icon)
                    .font(TypographyScale.footnote)
                
                if count > 0 {
                    Text("\(count)")
                        .font(TypographyScale.caption1)
                }
            }
            .foregroundColor(ColorTokens.tertiaryText)
        }
    }
}

#if DEBUG
#Preview("Post Thread") {
    PreviewDeps.scoped {
        NavigationStack {
            PostThreadView(threadId: "sample-thread-id")
        }
    }
}
#endif