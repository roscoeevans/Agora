//
//  PostDetailScreen.swift
//  Agora
//
//  Created by Agora Team on 2024.
//

import SwiftUI
import DesignSystem
import AppFoundation

public struct PostDetailScreen: View {
    @Environment(\.deps) private var deps
    @State private var viewModel: PostDetailViewModel?
    @State private var showCommentSheet = false
    @State private var replyToPost: Post?
    
    private let postId: String
    
    public init(postId: String) {
        self.postId = postId
    }
    
    public var body: some View {
        Group {
            if let viewModel = viewModel {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        if let post = viewModel.post {
                            // Original post
                            PostDetailView(post: post)
                                .padding(.bottom, SpacingTokens.lg)
                            
                            // Replies section
                            if !viewModel.replies.isEmpty {
                                Divider()
                                
                                ReplyListView(
                                    replies: viewModel.replies,
                                    onReplyToReply: { reply in
                                        replyToPost = post
                                        showCommentSheet = true
                                    }
                                )
                            } else if !viewModel.isLoadingReplies {
                                // Empty state for no replies
                                VStack(spacing: SpacingTokens.md) {
                                    Divider()
                                    
                                    Text("No comments yet")
                                        .font(TypographyScale.body)
                                        .foregroundColor(ColorTokens.tertiaryText)
                                        .padding(.vertical, SpacingTokens.xl)
                                }
                            }
                        } else if viewModel.isLoading {
                            PostDetailLoadingView()
                        } else {
                            PostDetailEmptyStateView()
                        }
                    }
                }
                .navigationTitle("Post")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        if let post = viewModel.post {
                            Button {
                                replyToPost = post
                                showCommentSheet = true
                            } label: {
                                Image(systemName: "bubble.right")
                                    .font(.system(size: 18))
                            }
                            .accessibilityLabel("Add comment")
                        }
                    }
                }
                .refreshable {
                    await viewModel.refresh()
                }
                .task {
                    await viewModel.loadPost()
                }
            } else {
                PostDetailLoadingView()
            }
        }
        .sheet(isPresented: $showCommentSheet) {
            if let post = replyToPost {
                CommentSheetSkeleton(post: post)
            }
        }
        .task {
            // Initialize view model with dependencies from environment
            // Following DI rule: dependencies injected from environment
            self.viewModel = PostDetailViewModel(postId: postId, networking: deps.networking)
        }
    }
}

#if DEBUG
#Preview("Post Detail Screen") {
    PreviewDeps.scoped {
        NavigationStack {
            PostDetailScreen(postId: "sample-post-id")
        }
    }
}

#Preview("Post Detail Screen - Dark Mode") {
    PreviewDeps.scopedDark {
        NavigationStack {
            PostDetailScreen(postId: "sample-post-id")
        }
    }
}
#endif
