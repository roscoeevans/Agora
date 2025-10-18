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

// Note: Networking re-exports AppFoundation, giving us access to Post and other types
// We don't need to explicitly import AppFoundation

public struct HomeForYouView: View {
    @Environment(\.deps) private var deps
    @Environment(\.navigateToPost) private var navigateToPost
    @State private var viewModel: ForYouViewModel?
    
    let onComposeAction: () -> Void
    
    public init(onComposeAction: @escaping () -> Void = {}) {
        self.onComposeAction = onComposeAction
    }
    
    public var body: some View {
        Group {
            if let viewModel = viewModel {
                ScrollView {
                    LazyVStack(spacing: SpacingTokens.md) {
                        if viewModel.posts.isEmpty && !viewModel.isLoading {
                            AgoraEmptyStateView.emptyFeed(action: onComposeAction)
                        } else {
                            ForEach(viewModel.posts, id: \.id) { post in
                                PostCardView(post: post) {
                                    if let navigate = navigateToPost, let uuid = UUID(uuidString: post.id) {
                                        navigate.action(uuid)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, SpacingTokens.md)
                    .padding(.bottom, 100) // Add bottom padding to ensure content extends under tab bar
                }
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
            } else {
                AgoraLoadingView.feedLoading()
            }
        }
        .task {
            // Initialize view model only once
            // The viewModel's init already triggers initial data load
            if viewModel == nil {
                self.viewModel = ForYouViewModel(
                    networking: deps.networking,
                    analytics: deps.analytics
                )
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
    PreviewDeps.scoped {
        HomeForYouView()
    }
}
#endif
