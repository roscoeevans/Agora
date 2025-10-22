//
//  CommentSheet.swift
//  Agora
//
//  Created by Agora Team on 2024.
//

import SwiftUI
import DesignSystem
import AppFoundation

/// Sheet for composing comments/replies to posts
/// Shows immediately with skeleton loading for comments
public struct CommentSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let post: Post
    let replyToCommentId: String?
    let replyToUsername: String?
    
    // Loading and content state
    @State private var isLoadingComments = true
    @State private var comments: [Comment] = []
    
    // Haptic feedback triggers
    @State private var postButtonHapticTrigger = false
    @State private var closeButtonHapticTrigger = false
    
    public init(
        post: Post,
        replyToCommentId: String? = nil,
        replyToUsername: String? = nil
    ) {
        self.post = post
        self.replyToCommentId = replyToCommentId
        self.replyToUsername = replyToUsername
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Top handle for swipe-to-dismiss
                Capsule()
                    .fill(ColorTokens.separator)
                    .frame(width: 36, height: 5)
                    .padding(.top, SpacingTokens.sm)
                    .padding(.bottom, SpacingTokens.md)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: SpacingTokens.lg) {
                        // Show who we're replying to
                        if let username = replyToUsername {
                            HStack(spacing: SpacingTokens.xs) {
                                Text("Replying to")
                                    .font(TypographyScale.footnote)
                                    .foregroundColor(ColorTokens.tertiaryText)
                                
                                Text("@\(username)")
                                    .font(TypographyScale.footnote)
                                    .foregroundColor(ColorTokens.agoraBrand)
                            }
                            .padding(.horizontal, SpacingTokens.md)
                        }
                        
                        // Original post context
                        VStack(alignment: .leading, spacing: SpacingTokens.sm) {
                            HStack(alignment: .top, spacing: SpacingTokens.sm) {
                                Circle()
                                    .fill(ColorTokens.agoraBrand)
                                    .frame(width: 32, height: 32)
                                    .overlay {
                                        Text(String((post.authorDisplayName ?? post.authorDisplayHandle).prefix(1)))
                                            .font(TypographyScale.caption1)
                                            .foregroundColor(.white)
                                    }
                                
                                VStack(alignment: .leading, spacing: SpacingTokens.xxs) {
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
                                    
                                    Text(post.text)
                                        .font(TypographyScale.body)
                                        .foregroundColor(ColorTokens.primaryText)
                                        .lineLimit(4)
                                }
                            }
                        }
                        .padding(.horizontal, SpacingTokens.md)
                        .padding(.bottom, SpacingTokens.sm)
                        
                        Divider()
                            .padding(.horizontal, SpacingTokens.md)
                        
                        // Comments section
                        VStack(alignment: .leading, spacing: SpacingTokens.md) {
                            Text("Comments")
                                .font(TypographyScale.calloutEmphasized)
                                .foregroundColor(ColorTokens.primaryText)
                                .padding(.horizontal, SpacingTokens.md)
                            
                            if isLoadingComments {
                                // Skeleton loading for comments
                                VStack(spacing: SpacingTokens.md) {
                                    ForEach(0..<3) { _ in
                                        CommentSkeletonView()
                                    }
                                }
                            } else {
                                // Actual comments
                                ForEach(comments, id: \.id) { comment in
                                    CommentRowView(comment: comment)
                                }
                            }
                        }
                        
                        Divider()
                            .padding(.horizontal, SpacingTokens.md)
                        
                        // Comment input area
                        VStack(alignment: .leading, spacing: SpacingTokens.md) {
                            TextEditor(text: .constant(""))
                                .font(TypographyScale.body)
                                .foregroundColor(ColorTokens.primaryText)
                                .frame(minHeight: 100)
                                .scrollContentBackground(.hidden)
                                .background(Color.clear)
                                .overlay(alignment: .topLeading) {
                                    Text("Add a comment...")
                                        .font(TypographyScale.body)
                                        .foregroundColor(ColorTokens.quaternaryText)
                                        .padding(.top, 8)
                                        .padding(.leading, 5)
                                        .allowsHitTesting(false)
                                }
                                .accessibilityLabel("Comment text")
                                .accessibilityHint("Type your comment here")
                            
                            // Character count
                            HStack {
                                Spacer()
                                Text("0/280")
                                    .font(TypographyScale.caption1)
                                    .foregroundColor(ColorTokens.tertiaryText)
                            }
                        }
                        .padding(.horizontal, SpacingTokens.md)
                    }
                }
                
                Spacer()
                
                // Post button at bottom
                Button(action: {
                    postButtonHapticTrigger.toggle()
                    // TODO: Implement posting
                }) {
                    Text("Post")
                        .font(TypographyScale.calloutEmphasized)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(ColorTokens.agoraBrand)
                        .cornerRadius(BorderRadiusTokens.md)
                }
                .padding(.horizontal, SpacingTokens.md)
                .padding(.bottom, SpacingTokens.md)
                .frame(minHeight: 44) // Minimum touch target
                .accessibilityLabel("Post comment")
                .accessibilityHint("Double tap to post your comment")
                .sensoryFeedback(.impact(weight: .medium), trigger: postButtonHapticTrigger)
            }
            .navigationTitle("\(post.replyCount) comments")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        closeButtonHapticTrigger.toggle()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(ColorTokens.tertiaryText)
                            .symbolRenderingMode(.hierarchical)
                    }
                    .frame(minWidth: 44, minHeight: 44) // Minimum touch target
                    .accessibilityLabel("Close comments")
                    .sensoryFeedback(.selection, trigger: closeButtonHapticTrigger)
                }
            }
        }
        .onAppear {
            loadComments()
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(BorderRadiusTokens.xl)
        .presentationBackground(.ultraThinMaterial)
    }
    
    /// Loads comments for the post
    private func loadComments() {
        // Simulate loading comments
        Task {
            try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            
            await MainActor.run {
                // TODO: Replace with actual API call
                self.comments = [] // Empty for now
                self.isLoadingComments = false
            }
        }
    }
}

/// Placeholder for comment row view
private struct CommentRowView: View {
    let comment: Comment
    
    var body: some View {
        Text("Comment: \(comment.id)")
            .padding(.horizontal, SpacingTokens.md)
    }
}

/// Placeholder Comment model
private struct Comment: Identifiable {
    let id: String
}

#if DEBUG
#Preview("Comment on Post") {
    PreviewDeps.scoped {
        CommentSheet(
            post: PreviewFixtures.shortPost
        )
    }
}

#Preview("Reply to Comment") {
    PreviewDeps.scoped {
        CommentSheet(
            post: PreviewFixtures.longPost,
            replyToCommentId: "some-comment-id",
            replyToUsername: "commenter"
        )
    }
}

#Preview("Comment on Popular Post") {
    PreviewDeps.scoped {
        CommentSheet(
            post: PreviewFixtures.popularPost
        )
    }
}

#Preview("Reply to Recent Post") {
    PreviewDeps.scoped {
        CommentSheet(
            post: PreviewFixtures.recentPost,
            replyToCommentId: "recent-comment-id",
            replyToUsername: "recentuser"
        )
    }
}
#endif

