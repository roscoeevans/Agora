//
//  ThreadView.swift
//  Agora
//
//  Created by Agora Team on 2024.
//

import SwiftUI
import DesignSystem

public struct ThreadView: View {
    @State private var viewModel: ThreadViewModel
    
    public init(threadId: String) {
        self._viewModel = State(initialValue: ThreadViewModel(threadId: threadId))
    }
    
    public var body: some View {
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
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await viewModel.refresh()
        }
        .task {
            await viewModel.loadThread()
        }
    }
}

struct ThreadPostView: View {
    let post: ThreadPost
    let isLast: Bool
    
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
                HStack {
                    Text(post.author)
                        .font(TypographyScale.calloutEmphasized)
                        .foregroundColor(ColorTokens.primaryText)
                    
                    Spacer()
                    
                    Text(post.timestamp, style: .relative)
                        .font(TypographyScale.caption1)
                        .foregroundColor(ColorTokens.tertiaryText)
                }
                
                Text(post.text)
                    .font(TypographyScale.body)
                    .foregroundColor(ColorTokens.primaryText)
                
                HStack(spacing: SpacingTokens.lg) {
                    InteractionButton(
                        icon: "heart",
                        count: post.likeCount,
                        action: { /* TODO: Implement like */ }
                    )
                    
                    InteractionButton(
                        icon: "arrow.2.squarepath",
                        count: post.repostCount,
                        action: { /* TODO: Implement repost */ }
                    )
                    
                    InteractionButton(
                        icon: "bubble.right",
                        count: 0,
                        action: { /* TODO: Implement reply */ }
                    )
                    
                    Spacer()
                }
                .padding(.bottom, SpacingTokens.md)
            }
        }
        .padding(.horizontal, SpacingTokens.md)
    }
}

struct InteractionButton: View {
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

#Preview {
    NavigationStack {
        ThreadView(threadId: "sample-thread-id")
    }
}