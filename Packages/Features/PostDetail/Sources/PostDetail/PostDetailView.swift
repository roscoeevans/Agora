//
//  PostDetailView.swift
//  Agora
//
//  Created by Agora Team on 2024.
//

import SwiftUI
import DesignSystem

public struct PostDetailView: View {
    @State private var viewModel: PostDetailViewModel
    
    public init(postId: String) {
        self._viewModel = State(initialValue: PostDetailViewModel(postId: postId))
    }
    
    public var body: some View {
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
