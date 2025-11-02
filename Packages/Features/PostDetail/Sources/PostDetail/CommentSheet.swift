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
/// Shows threaded comments with YouTube-style nesting (max depth = 2)
public struct CommentSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.deps) private var deps
    
    let post: Post
    let replyToCommentId: String?
    let replyToUsername: String?
    
    // Loading and content state
    @State private var isLoadingComments = true
    @State private var topLevelComments: [Comment] = []
    @State private var repliesMap: [String: [Comment]] = [:] // commentId -> replies
    @State private var expandedComments: Set<String> = []
    
    // Comment composition
    @State private var commentText: String = ""
    @State private var currentReplyToId: String? = nil
    @State private var currentReplyToUsername: String? = nil
    
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
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Comments")
                                .font(TypographyScale.calloutEmphasized)
                                .foregroundColor(ColorTokens.primaryText)
                                .padding(.horizontal, SpacingTokens.md)
                                .padding(.bottom, SpacingTokens.sm)
                            
                            if isLoadingComments {
                                // Skeleton loading for comments
                                VStack(spacing: SpacingTokens.md) {
                                    ForEach(0..<3) { _ in
                                        CommentSkeletonView()
                                    }
                                }
                            } else if topLevelComments.isEmpty {
                                // Empty state
                                VStack(spacing: SpacingTokens.sm) {
                                    Text("No comments yet")
                                        .font(TypographyScale.body)
                                        .foregroundColor(ColorTokens.secondaryText)
                                    
                                    Text("Be the first to share your thoughts")
                                        .font(TypographyScale.footnote)
                                        .foregroundColor(ColorTokens.tertiaryText)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, SpacingTokens.xl)
                            } else {
                                // Threaded comments
                                ForEach(topLevelComments) { comment in
                                    VStack(spacing: 0) {
                                        ThreadedCommentView(
                                            comment: comment,
                                            onReply: {
                                                handleReply(to: comment)
                                            },
                                            onLoadReplies: {
                                                loadReplies(for: comment)
                                            }
                                        )
                                        
                                        // Show replies if expanded
                                        if expandedComments.contains(comment.id),
                                           let replies = repliesMap[comment.id] {
                                            ForEach(replies) { reply in
                                                ThreadedCommentView(
                                                    comment: reply,
                                                    onReply: {
                                                        handleReply(to: reply)
                                                    },
                                                    onLoadReplies: {
                                                        loadReplies(for: reply)
                                                    }
                                                )
                                            }
                                        }
                                        
                                        Divider()
                                            .padding(.leading, CGFloat(comment.depth) * 32 + 56)
                                    }
                                }
                            }
                        }
                        
                        Divider()
                            .padding(.horizontal, SpacingTokens.md)
                        
                        // Comment input area
                        VStack(alignment: .leading, spacing: SpacingTokens.md) {
                            // Show reply context if replying
                            if let username = currentReplyToUsername {
                                HStack(spacing: SpacingTokens.xs) {
                                    Image(systemName: "arrowshape.turn.up.left")
                                        .font(.system(size: 12))
                                        .foregroundColor(ColorTokens.agoraBrand)
                                    
                                    Text("Replying to @\(username)")
                                        .font(TypographyScale.caption1)
                                        .foregroundColor(ColorTokens.agoraBrand)
                                    
                                    Spacer()
                                    
                                    Button {
                                        clearReplyContext()
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(ColorTokens.tertiaryText)
                                    }
                                }
                                .padding(.horizontal, SpacingTokens.sm)
                                .padding(.vertical, SpacingTokens.xs)
                                .background(ColorTokens.agoraBrand.opacity(0.1))
                                .cornerRadius(BorderRadiusTokens.sm)
                            }
                            
                            TextEditor(text: $commentText)
                                .font(TypographyScale.body)
                                .foregroundColor(ColorTokens.primaryText)
                                .frame(minHeight: 100)
                                .scrollContentBackground(.hidden)
                                .background(Color.clear)
                                .overlay(alignment: .topLeading) {
                                    if commentText.isEmpty {
                                        Text("Add a comment...")
                                            .font(TypographyScale.body)
                                            .foregroundColor(ColorTokens.quaternaryText)
                                            .padding(.top, 8)
                                            .padding(.leading, 5)
                                            .allowsHitTesting(false)
                                    }
                                }
                                .accessibilityLabel("Comment text")
                                .accessibilityHint("Type your comment here")
                            
                            // Character count
                            HStack {
                                Spacer()
                                Text("\(commentText.count)/2000")
                                    .font(TypographyScale.caption1)
                                    .foregroundColor(commentText.count > 2000 ? .red : ColorTokens.tertiaryText)
                            }
                        }
                        .padding(.horizontal, SpacingTokens.md)
                    }
                }
                
                Spacer()
                
                // Post button at bottom
                Button(action: {
                    postButtonHapticTrigger.toggle()
                    postComment()
                }) {
                    Text("Post")
                        .font(TypographyScale.calloutEmphasized)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(commentText.isEmpty ? ColorTokens.separator : ColorTokens.agoraBrand)
                        .cornerRadius(BorderRadiusTokens.md)
                }
                .disabled(commentText.isEmpty || commentText.count > 2000)
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
    
    // MARK: - Actions
    
    /// Loads top-level comments for the post
    private func loadComments() {
        guard let commentService = deps.commentService else { return }
        
        Task {
            do {
                let result = try await commentService.fetchTopLevelComments(
                    postId: post.id,
                    pageSize: 50,
                    cursor: nil
                )
                
                await MainActor.run {
                    self.topLevelComments = result.items
                    self.isLoadingComments = false
                }
            } catch {
                print("Failed to load comments: \(error)")
                await MainActor.run {
                    self.isLoadingComments = false
                }
            }
        }
    }
    
    /// Loads replies for a specific comment
    private func loadReplies(for comment: Comment) {
        guard let commentService = deps.commentService else { return }
        
        // Toggle expansion
        if expandedComments.contains(comment.id) {
            expandedComments.remove(comment.id)
            return
        }
        
        // If we already have replies cached, just expand
        if repliesMap[comment.id] != nil {
            expandedComments.insert(comment.id)
            return
        }
        
        // Otherwise fetch replies
        Task {
            do {
                let result = try await commentService.fetchReplies(
                    parentId: comment.id,
                    pageSize: 25,
                    cursor: nil
                )
                
                await MainActor.run {
                    self.repliesMap[comment.id] = result.items
                    self.expandedComments.insert(comment.id)
                }
            } catch {
                print("Failed to load replies: \(error)")
            }
        }
    }
    
    /// Sets up reply context when user taps reply button
    private func handleReply(to comment: Comment) {
        currentReplyToId = comment.id
        currentReplyToUsername = comment.authorDisplayHandle
    }
    
    /// Clears reply context
    private func clearReplyContext() {
        currentReplyToId = nil
        currentReplyToUsername = nil
    }
    
    /// Posts a new comment or reply
    private func postComment() {
        guard let commentService = deps.commentService else { return }
        guard !commentText.isEmpty else { return }
        
        let body = commentText
        
        Task {
            do {
                let newComment: Comment
                
                if let replyToId = currentReplyToId {
                    // Posting a reply
                    newComment = try await commentService.createReply(
                        parentId: replyToId,
                        body: body
                    )
                } else {
                    // Posting top-level comment
                    newComment = try await commentService.createComment(
                        postId: post.id,
                        body: body
                    )
                }
                
                await MainActor.run {
                    // Add to appropriate list
                    if newComment.depth == 0 {
                        // Top-level comment - prepend to list
                        self.topLevelComments.insert(newComment, at: 0)
                    } else if let parentId = newComment.parentCommentId {
                        // Reply - add to replies map
                        if self.repliesMap[parentId] != nil {
                            self.repliesMap[parentId]?.insert(newComment, at: 0)
                        } else {
                            self.repliesMap[parentId] = [newComment]
                        }
                        // Ensure parent is expanded
                        self.expandedComments.insert(parentId)
                    }
                    
                    // Clear input
                    self.commentText = ""
                    self.clearReplyContext()
                }
            } catch {
                print("Failed to post comment: \(error)")
                // TODO: Show error toast to user
            }
        }
    }
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

