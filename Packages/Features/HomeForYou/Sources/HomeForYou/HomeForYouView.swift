//
//  HomeForYouView.swift
//  Agora
//
//  Created by Agora Team on 2024.
//

import SwiftUI
import DesignSystem
import AppFoundation
import Analytics
import Networking

public struct HomeForYouView: View {
    @Environment(\.deps) private var deps
    @State private var viewModel: ForYouViewModel?
    @State private var coordinator: ForYouCoordinator?
    
    public init() {}
    
    public var body: some View {
        Group {
            if let viewModel = viewModel, coordinator != nil {
                NavigationStack(path: Binding(
                    get: { coordinator?.navigationPath ?? NavigationPath() },
                    set: { coordinator?.navigationPath = $0 }
                )) {
                    ScrollView {
                        LazyVStack(spacing: SpacingTokens.md) {
                            if viewModel.posts.isEmpty && !viewModel.isLoading {
                                AgoraEmptyStateView.emptyFeed()
                            } else {
                                ForEach(viewModel.posts, id: \.id) { post in
                                    PostCardView(post: post) {
                                        coordinator?.navigateToPost(post)
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
            } else {
                AgoraLoadingView.feedLoading()
            }
        }
        .task {
            // Initialize view model and coordinator with dependencies from environment
            // Following DI rule: dependencies injected from environment
            self.viewModel = ForYouViewModel(
                networking: deps.networking,
                analytics: deps.analytics
            )
            self.coordinator = ForYouCoordinator(analytics: deps.analytics)
        }
    }
}

struct PostCardView: View {
    let post: Post
    let onTap: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.sm) {
            // Author and timestamp header
            HStack(alignment: .top, spacing: SpacingTokens.sm) {
                // Author avatar placeholder
                Circle()
                    .fill(ColorTokens.agoraBrand)
                    .frame(width: 40, height: 40)
                    .overlay {
                        Text(String(post.authorDisplayHandle.prefix(1)))
                            .font(TypographyScale.calloutEmphasized)
                            .foregroundColor(.white)
                    }
                
                VStack(alignment: .leading, spacing: SpacingTokens.xxs) {
                    // Display handle and timestamp on same line
                    HStack(spacing: SpacingTokens.xs) {
                        Text(post.authorDisplayHandle)
                            .font(TypographyScale.calloutEmphasized)
                            .foregroundColor(ColorTokens.primaryText)
                        
                        Text("·")
                            .font(TypographyScale.caption1)
                            .foregroundColor(ColorTokens.tertiaryText)
                        
                        Text(RelativeTimeFormatter.format(post.createdAt))
                            .font(TypographyScale.caption1)
                            .foregroundColor(ColorTokens.tertiaryText)
                    }
                    
                    // Post content aligned under display handle
                    Text(post.text)
                        .font(TypographyScale.body)
                        .foregroundColor(ColorTokens.primaryText)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
            }
            
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
        .accessibilityLabel("Post by \(post.authorDisplayHandle)")
        .accessibilityHint("Double tap to view post details")
    }
}



#Preview {
    HomeForYouView()
}
