//
//  FollowingView.swift
//  Agora
//
//  Created by Agora Team on 2024.
//

import SwiftUI
import DesignSystem

// Typealias for consistency with ContentView expectations
public typealias HomeFollowingView = FollowingView

public struct FollowingView: View {
    @State private var viewModel = FollowingViewModel()
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: SpacingTokens.md) {
                    if viewModel.posts.isEmpty && !viewModel.isLoading {
                        EmptyStateView()
                    } else {
                        ForEach(viewModel.posts, id: \.id) { post in
                            PostCardView(post: post) {
                                // TODO: Navigate to post detail
                            }
                        }
                    }
                }
                .padding(.horizontal, SpacingTokens.md)
            }
            .navigationTitle("Following")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .refreshable {
                await viewModel.refresh()
            }
            .overlay {
                if viewModel.isLoading && viewModel.posts.isEmpty {
                    LoadingView()
                }
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") {
                    viewModel.error = nil
                }
            } message: {
                Text(viewModel.error?.localizedDescription ?? "An unknown error occurred")
            }
        }
    }
}

struct PostCardView: View {
    let post: Post
    let onTap: () -> Void
    
    var body: some View {
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
                .multilineTextAlignment(.leading)
            
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
                    count: post.replyCount,
                    action: { /* TODO: Implement reply */ }
                )
                
                Spacer()
            }
        }
        .padding(SpacingTokens.md)
        .background(ColorTokens.background)
        .cornerRadius(SpacingTokens.xs)
        .shadow(color: ColorTokens.separator.opacity(0.3), radius: 2, x: 0, y: 1)
        .onTapGesture {
            onTap()
        }
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

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: SpacingTokens.lg) {
            Image(systemName: "person.2")
                .font(.system(size: 48))
                .foregroundColor(ColorTokens.agoraBrand)
            
            Text("No Posts Yet")
                .font(TypographyScale.title2)
                .foregroundColor(ColorTokens.primaryText)
            
            Text("Follow some people to see their posts in your chronological feed!")
                .font(TypographyScale.body)
                .foregroundColor(ColorTokens.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(SpacingTokens.xl)
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

#Preview {
    FollowingView()
}