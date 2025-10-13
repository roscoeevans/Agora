//
//  PostDetailView.swift
//  Agora
//
//  Created by Agora Team on 2024.
//

import SwiftUI
import DesignSystem
import AppFoundation

public struct PostDetailView: View {
    @Environment(\.deps) private var deps
    @State private var viewModel: PostDetailViewModel?
    
    private let postId: String
    
    public init(postId: String) {
        self.postId = postId
    }
    
    public var body: some View {
        Group {
            if let viewModel = viewModel {
                ScrollView {
                    VStack(alignment: .leading, spacing: SpacingTokens.lg) {
                        if let post = viewModel.post {
                            PostDetailCard(post: post)
                            
                            if !viewModel.replies.isEmpty {
                                Divider()
                                    .padding(.horizontal, SpacingTokens.md)
                                
                                LazyVStack(spacing: SpacingTokens.md) {
                                    ForEach(viewModel.replies, id: \.id) { reply in
                                        ReplyCard(reply: reply)
                                    }
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
                .navigationBarTitleDisplayMode(.inline)
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
        .task {
            // Initialize view model with dependencies from environment
            // Following DI rule: dependencies injected from environment
            self.viewModel = PostDetailViewModel(postId: postId, networking: deps.networking)
        }
    }
}

#Preview("Post Detail View") {
    NavigationStack {
        PostDetailView(postId: "sample-post-id")
    }
}

#Preview("Post Detail View - Dark Mode") {
    NavigationStack {
        PostDetailView(postId: "sample-post-id")
    }
    .preferredColorScheme(.dark)
}
