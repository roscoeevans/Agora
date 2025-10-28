//
//  HomeFollowingView.swift
//  Agora
//
//  Created by Agora Team on 2024.
//

import SwiftUI
import DesignSystem
import AppFoundation
import Analytics
import Networking
import PostDetail

public struct HomeFollowingView: View {
    @Environment(\.deps) private var deps
    @Environment(\.navigateToPost) private var navigateToPost
    @State private var viewModel: FollowingViewModel?
    @State private var postToCommentOn: Post?
    
    let onComposeAction: () -> Void
    
    public init(onComposeAction: @escaping () -> Void = {}) {
        self.onComposeAction = onComposeAction
    }
    
    public var body: some View {
        Group {
            if let viewModel = viewModel {
                Group {
                    if viewModel.skeletonAwarePosts.isEmpty && (viewModel.skeletonLoadingState == .loaded || viewModel.skeletonLoadingState == .idle) {
                        // Show centered empty state (no ScrollView needed)
                        VStack {
                            Spacer()
                            AgoraEmptyStateView.emptyFeed(action: onComposeAction)
                                .padding(.horizontal, SpacingTokens.md)
                                .transition(.liquidGlass)
                            Spacer()
                        }
                        .transition(.opacity)
                    } else {
                        // Show scrollable feed with enhanced pagination skeleton integration
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(Array(viewModel.skeletonAwarePosts.enumerated()), id: \.offset) { index, post in
                                    VStack(spacing: 0) {
                                        SkeletonAwareFeedPostView(
                                            post: post,
                                            error: viewModel.errorForIndex(index),
                                            index: index,
                                            onAuthorTap: {
                                                // TODO: Navigate to profile
                                            },
                                            onReply: {
                                                if let post = post {
                                                    postToCommentOn = post
                                                }
                                            },
                                            onTap: {
                                                if let post = post,
                                                   let navigate = navigateToPost,
                                                   let uuid = UUID(uuidString: post.id) {
                                                    navigate.action(uuid)
                                                }
                                            },
                                            onRetry: {
                                                Task {
                                                    await viewModel.retryLoadingAtIndex(index)
                                                }
                                            },
                                            shouldDisableShimmer: viewModel.shouldDisableShimmer,
                                            performanceMonitor: viewModel.performanceMonitor
                                        )
                                        .padding(.horizontal, SpacingTokens.sm)
                                        .onAppear {
                                            // Enhanced pagination trigger with 5-row threshold
                                            if viewModel.shouldTriggerPagination(currentIndex: index) {
                                                Task {
                                                    await viewModel.loadMoreWithSkeletonSupport()
                                                }
                                            }
                                        }
                                        
                                        // Add divider between posts (except after the last post)
                                        if index < viewModel.skeletonAwarePosts.count - 1 {
                                            Divider()
                                                .padding(.horizontal, SpacingTokens.sm)
                                                .padding(.vertical, SpacingTokens.xs)
                                        }
                                    }
                                }
                                
                                // Pagination error handling
                                if let paginationError = viewModel.paginationError {
                                    SkeletonErrorView.paginationError(
                                        error: paginationError,
                                        retryAction: {
                                            Task {
                                                await viewModel.retryPagination()
                                            }
                                        }
                                    )
                                    .padding(.top, SpacingTokens.md)
                                }
                            }
                            .padding(.bottom, 100) // Add bottom padding to ensure content extends under tab bar
                            .skeletonContainerAccessibility(
                                isLoading: viewModel.skeletonLoadingState.isLoading,
                                loadingMessage: "Loading following feed",
                                loadedMessage: "Following feed loaded"
                            )
                        }
                    }
                }
                .animation(.liquidGlass, value: viewModel.skeletonLoadingState)
                .animation(.liquidGlass, value: viewModel.skeletonAwarePosts.isEmpty)
                .refreshable {
                    await viewModel.refreshWithSkeletonSupport()
                }
                .alert("Couldn't Load Feed", isPresented: .constant(viewModel.error != nil)) {
                    Button("Try Again") {
                        viewModel.error = nil
                        Task {
                            await viewModel.refreshWithSkeletonSupport()
                        }
                    }
                    Button("OK", role: .cancel) {
                        viewModel.error = nil
                    }
                } message: {
                    Text("Please check your connection and try again.")
                }
            } else {
                // Initial loading state with skeleton
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(0..<SkeletonConfiguration.homeFollowing.placeholderCount, id: \.self) { index in
                            VStack(spacing: 0) {
                                FeedPostSkeletonView()
                                    .padding(.horizontal, SpacingTokens.sm)
                                
                                // Add divider between skeleton posts (except after the last post)
                                if index < SkeletonConfiguration.homeFollowing.placeholderCount - 1 {
                                    Divider()
                                        .padding(.horizontal, SpacingTokens.sm)
                                        .padding(.vertical, SpacingTokens.xs)
                                }
                            }
                        }
                    }
                }
            }
        }
        .skeletonTheme(DefaultSkeletonTheme())
        .sheet(item: $postToCommentOn) { post in
            CommentSheet(
                post: post,
                replyToCommentId: nil,
                replyToUsername: nil
            )
        }
        .task {
            // Initialize view model only once
            if viewModel == nil {
                self.viewModel = FollowingViewModel(
                    networking: deps.networking,
                    analytics: deps.analytics
                )
                
                // Pre-seed skeleton placeholders for 200ms target display time
                viewModel?.preloadSkeletonPlaceholders()
                
                // Start initial data load with skeleton support
                Task {
                    await viewModel?.refreshWithSkeletonSupport()
                }
            }
        }
    }
}

struct PostCardView: View {
    let post: Post
    let onTap: () -> Void
    @Environment(\.deps) private var deps
    @State private var engagementState: PostEngagementState?
    
    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.xs) {
            HStack(spacing: SpacingTokens.xs) {
                Text(post.authorDisplayHandle)
                    .font(TypographyScale.calloutEmphasized)
                    .foregroundColor(ColorTokens.primaryText)
                
                Text("·")
                    .font(TypographyScale.caption1)
                    .foregroundColor(ColorTokens.tertiaryText)
                
                Text(post.createdAt, style: .relative)
                    .font(TypographyScale.caption1)
                    .foregroundColor(ColorTokens.tertiaryText)
                
                Spacer()
            }
            
            Text(post.text)
                .font(TypographyScale.body)
                .foregroundColor(ColorTokens.primaryText)
                .multilineTextAlignment(.leading)
            
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
                        replyCount: post.replyCount,
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
                            count: post.replyCount,
                            action: { /* TODO: Implement reply */ }
                        )
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(SpacingTokens.md)
        .background(ColorTokens.background)
        .cornerRadius(SpacingTokens.xs)
        .shadow(color: ColorTokens.separator.opacity(0.3), radius: 2, x: 0, y: 1)
        .onTapGesture {
            onTap()
        }
        .task {
            // Initialize engagement state
            if let engagement = deps.engagement {
                engagementState = PostEngagementState(
                    post: post,
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


struct LoadingView: View {
    var body: some View {
        VStack(spacing: SpacingTokens.md) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading your feed...")
                .font(TypographyScale.callout)
                .foregroundColor(ColorTokens.secondaryText)
        }
    }
}

#if DEBUG
#Preview("Following Feed") {
    PreviewDeps.scoped {
        HomeFollowingView()
    }
}
#endif