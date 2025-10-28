//
//  HomeForYouView.swift
//  Agora
//
//  Created by Agora Team on 2024.
//

import SwiftUI
import DesignSystem
import Analytics
import Networking
import AppFoundation
import PostDetail
import Engagement

public struct HomeForYouView: View {
    @Environment(\.deps) private var deps
    @Environment(\.navigateToPost) private var navigateToPost
    @State private var viewModel: ForYouViewModel?
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
                                loadingMessage: "Loading your feed",
                                loadedMessage: "Feed loaded"
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
                        ForEach(0..<SkeletonConfiguration.homeForYou.placeholderCount, id: \.self) { index in
                            VStack(spacing: 0) {
                                FeedPostSkeletonView()
                                    .padding(.horizontal, SpacingTokens.sm)
                                
                                // Add divider between skeleton posts (except after the last post)
                                if index < SkeletonConfiguration.homeForYou.placeholderCount - 1 {
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
                self.viewModel = ForYouViewModel(
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
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.sm) {
            postHeader
            interactionButtons
        }
        .padding(SpacingTokens.md)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: BorderRadiusTokens.md))
        .overlay(
            RoundedRectangle(cornerRadius: BorderRadiusTokens.md)
                .stroke(ColorTokens.separator.opacity(0.3), lineWidth: 0.5)
        )
        .agoraShadow(ShadowTokens.subtle)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Post by \(post.authorDisplayHandle)")
        .accessibilityHint("Double tap to view post details")
    }
    
    private var postHeader: some View {
        HStack(alignment: .top, spacing: SpacingTokens.sm) {
            authorAvatar
            
            VStack(alignment: .leading, spacing: SpacingTokens.xxs) {
                metadataLine
                postContent
            }
            
            Spacer()
        }
    }
    
    private var authorAvatar: some View {
        Circle()
            .fill(ColorTokens.agoraBrand)
            .frame(width: 40, height: 40)
            .overlay {
                Text(String(post.authorDisplayHandle.prefix(1)))
                    .font(TypographyScale.calloutEmphasized)
                    .foregroundColor(.white)
            }
    }
    
    private var metadataLine: some View {
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
        }
    }
    
    private var postContent: some View {
        Text(post.text)
            .font(TypographyScale.body)
            .foregroundColor(ColorTokens.primaryText)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    private var interactionButtons: some View {
        HStack(spacing: SpacingTokens.xl) {
            AgoraInteractionButton.like(count: post.likeCount) {
                /* TODO: Implement like */
            }
            
            AgoraInteractionButton.repost(count: post.repostCount) {
                /* TODO: Implement repost */
            }
            
            AgoraInteractionButton.reply(count: post.replyCount) {
                /* TODO: Implement reply */
            }
            
            Spacer()
        }
        .padding(.top, SpacingTokens.xs)
    }
}



#if DEBUG
#Preview("For You Feed") {
    let deps = Dependencies.test().withEngagement(EngagementServiceFake())
    return HomeForYouView()
        .environment(\.deps, deps)
        .environment(\.navigateToPost, NavigateToPost { _ in print("Navigate to post") })
        .environment(\.colorScheme, .light)
        .environment(\.locale, .init(identifier: "en_US"))
}
#endif
