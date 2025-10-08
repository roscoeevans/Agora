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
                    LoadingView()
                } else {
                    EmptyStateView()
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

struct PostDetailCard: View {
    let post: Post
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.md) {
            HStack(alignment: .top, spacing: SpacingTokens.sm) {
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
                    HStack {
                        Text(post.author)
                            .font(TypographyScale.headline)
                            .foregroundColor(ColorTokens.primaryText)
                        
                        Spacer()
                        
                        Text(post.timestamp, style: .relative)
                            .font(TypographyScale.caption1)
                            .foregroundColor(ColorTokens.tertiaryText)
                    }
                    
                    Text(post.text)
                        .font(TypographyScale.body)
                        .foregroundColor(ColorTokens.primaryText)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            HStack(spacing: SpacingTokens.xl) {
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
            .padding(.top, SpacingTokens.xs)
        }
        .padding(SpacingTokens.md)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: SpacingTokens.sm))
        .overlay(
            RoundedRectangle(cornerRadius: SpacingTokens.sm)
                .stroke(ColorTokens.separator.opacity(0.3), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.05), radius: SpacingTokens.xxs, x: 0, y: 2)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Post by \(post.author)")
        .accessibilityHint("Double tap to interact with this post")
    }
}

struct ReplyCard: View {
    let reply: Reply
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.sm) {
            HStack(alignment: .top, spacing: SpacingTokens.sm) {
                // Author avatar placeholder
                Circle()
                    .fill(ColorTokens.agoraBrand)
                    .frame(width: 32, height: 32)
                    .overlay {
                        Text(String(reply.author.prefix(1)))
                            .font(TypographyScale.caption1)
                            .foregroundColor(.white)
                    }
                
                VStack(alignment: .leading, spacing: SpacingTokens.xxs) {
                    HStack {
                        Text(reply.author)
                            .font(TypographyScale.calloutEmphasized)
                            .foregroundColor(ColorTokens.primaryText)
                        
                        Spacer()
                        
                        Text(reply.timestamp, style: .relative)
                            .font(TypographyScale.caption1)
                            .foregroundColor(ColorTokens.tertiaryText)
                    }
                    
                    Text(reply.text)
                        .font(TypographyScale.body)
                        .foregroundColor(ColorTokens.primaryText)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(SpacingTokens.md)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: SpacingTokens.sm))
        .overlay(
            RoundedRectangle(cornerRadius: SpacingTokens.sm)
                .stroke(ColorTokens.separator.opacity(0.2), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.03), radius: SpacingTokens.xxs, x: 0, y: 1)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .padding(.horizontal, SpacingTokens.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Reply by \(reply.author)")
        .accessibilityHint("Double tap to interact with this reply")
    }
}

struct InteractionButton: View {
    let icon: String
    let count: Int
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            // Add haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            action()
        }) {
            HStack(spacing: SpacingTokens.xxs) {
                Image(systemName: icon)
                    .font(TypographyScale.callout)
                    .symbolEffect(.bounce, value: isPressed)
                
                if count > 0 {
                    Text("\(count)")
                        .font(TypographyScale.callout)
                }
            }
            .foregroundColor(ColorTokens.tertiaryText)
            .frame(minWidth: 44, minHeight: 44) // Ensure 44x44pt touch target
            .contentShape(Rectangle()) // Make entire area tappable
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(accessibilityValue)
    }
    
    private var accessibilityLabel: String {
        switch icon {
        case "heart":
            return "Like post"
        case "arrow.2.squarepath":
            return "Repost"
        case "bubble.right":
            return "Reply to post"
        default:
            return "Interact with post"
        }
    }
    
    private var accessibilityValue: String {
        if count > 0 {
            return "\(count) \(icon == "heart" ? "likes" : icon == "arrow.2.squarepath" ? "reposts" : "replies")"
        } else {
            return ""
        }
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: SpacingTokens.md) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading post...")
                .font(TypographyScale.callout)
                .foregroundColor(ColorTokens.secondaryText)
        }
        .padding(SpacingTokens.xl)
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: SpacingTokens.lg) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(ColorTokens.warning)
                .symbolEffect(.pulse, isActive: true)
            
            Text("Post Not Found")
                .font(TypographyScale.title2)
                .foregroundColor(ColorTokens.primaryText)
            
            Text("This post may have been deleted or is no longer available.")
                .font(TypographyScale.body)
                .foregroundColor(ColorTokens.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(SpacingTokens.xl)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(ColorTokens.separator.opacity(0.2), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Post not found. This post may have been deleted or is no longer available.")
    }
}

#Preview {
    NavigationStack {
        PostDetailView(postId: "sample-post-id")
    }
}