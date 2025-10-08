//
//  HomeForYouView.swift
//  Agora
//
//  Created by Agora Team on 2024.
//

import SwiftUI
import DesignSystem

public struct HomeForYouView: View {
    @State private var viewModel = ForYouViewModel()
    @State private var coordinator = ForYouCoordinator()
    
    public init() {}
    
    public var body: some View {
        NavigationStack(path: $coordinator.navigationPath) {
            ScrollView {
                LazyVStack(spacing: SpacingTokens.md) {
                    if viewModel.posts.isEmpty && !viewModel.isLoading {
                        AgoraEmptyStateView.emptyFeed()
                    } else {
                        ForEach(viewModel.posts, id: \.id) { post in
                            PostCardView(post: post) {
                                coordinator.navigateToPost(post)
                            }
                        }
                    }
                }
                .padding(.horizontal, SpacingTokens.md)
            }
            .navigationTitle("For You")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .refreshable {
                await viewModel.refresh()
            }
            .overlay {
                if viewModel.isLoading && viewModel.posts.isEmpty {
                    AgoraLoadingView.feedLoading()
                }
            }
            .alert("Couldn't Load Feed", isPresented: .constant(viewModel.error != nil)) {
                Button("Try Again") {
                    viewModel.error = nil
                    Task {
                        await viewModel.refresh()
                    }
                }
                Button("OK", role: .cancel) {
                    viewModel.error = nil
                }
            } message: {
                Text("We couldn't load your feed. Please check your connection and try again.")
            }
        }
        .environment(coordinator)
    }
}

struct PostCardView: View {
    let post: Post
    let onTap: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.sm) {
            // Author and timestamp header
            HStack(alignment: .top) {
                // Author avatar placeholder
                Circle()
                    .fill(ColorTokens.agoraBrand)
                    .frame(width: 40, height: 40)
                    .overlay {
                        Text(String(post.author.prefix(1)))
                            .font(TypographyScale.calloutEmphasized)
                            .foregroundColor(.white)
                    }
                
                VStack(alignment: .leading, spacing: SpacingTokens.xxs) {
                    Text(post.author)
                        .font(TypographyScale.calloutEmphasized)
                        .foregroundColor(ColorTokens.primaryText)
                    
                    Text(post.timestamp, style: .relative)
                        .font(TypographyScale.caption1)
                        .foregroundColor(ColorTokens.tertiaryText)
                }
                
                Spacer()
            }
            
            // Post content
            Text(post.text)
                .font(TypographyScale.body)
                .foregroundColor(ColorTokens.primaryText)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            
            // Interaction buttons
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
        .accessibilityLabel("Post by \(post.author)")
        .accessibilityHint("Double tap to view post details")
    }
}



#Preview {
    HomeForYouView()
}
