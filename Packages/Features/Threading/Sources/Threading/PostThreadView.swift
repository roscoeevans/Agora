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
                .navigationBarTitleDisplayMode(.inline)
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
                    
                    Text(RelativeTimeFormatter.format(post.timestamp))
                        .font(TypographyScale.caption1)
                        .foregroundColor(ColorTokens.tertiaryText)
                    
                    Spacer()
                }
                
                Text(post.text)
                    .font(TypographyScale.body)
                    .foregroundColor(ColorTokens.primaryText)
                
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
                .padding(.bottom, SpacingTokens.md)
            }
        }
        .padding(.horizontal, SpacingTokens.md)
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

#Preview {
    NavigationStack {
        PostThreadView(threadId: "sample-thread-id")
    }
}