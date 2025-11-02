import SwiftUI
import DesignSystem
import AppFoundation

/// Single comment view with YouTube-style threading (depth-based indentation)
struct ThreadedCommentView: View {
    let comment: Comment
    let onReply: () -> Void
    let onLoadReplies: () -> Void
    
    // Haptic triggers
    @State private var replyHapticTrigger = false
    @State private var loadRepliesHapticTrigger = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Indent based on depth (0px, 32px, 64px)
            if comment.depth > 0 {
                Spacer()
                    .frame(width: CGFloat(comment.depth) * 32)
            }
            
            // Avatar
            Circle()
                .fill(ColorTokens.agoraBrand)
                .frame(width: avatarSize, height: avatarSize)
                .overlay {
                    if let displayName = comment.authorDisplayName {
                        Text(String(displayName.prefix(1)))
                            .font(avatarFont)
                            .foregroundColor(.white)
                    } else {
                        Text("?")
                            .font(avatarFont)
                            .foregroundColor(.white)
                    }
                }
            
            // Comment content
            VStack(alignment: .leading, spacing: SpacingTokens.xs) {
                // Author and timestamp
                HStack(spacing: SpacingTokens.xs) {
                    if let handle = comment.authorDisplayHandle {
                        Text(handle)
                            .font(TypographyScale.calloutEmphasized)
                            .foregroundColor(ColorTokens.primaryText)
                    }
                    
                    Text("·")
                        .font(TypographyScale.caption1)
                        .foregroundColor(ColorTokens.tertiaryText)
                    
                    Text(comment.createdAt, style: .relative)
                        .font(TypographyScale.caption1)
                        .foregroundColor(ColorTokens.tertiaryText)
                }
                
                // Comment body
                Text(comment.body)
                    .font(bodyFont)
                    .foregroundColor(ColorTokens.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Action buttons
                HStack(spacing: SpacingTokens.md) {
                    // Reply button
                    Button(action: {
                        replyHapticTrigger.toggle()
                        onReply()
                    }) {
                        HStack(spacing: SpacingTokens.xxs) {
                            Image(systemName: "arrowshape.turn.up.left")
                                .font(.system(size: 14, weight: .medium))
                            Text("Reply")
                                .font(TypographyScale.caption1)
                        }
                        .foregroundColor(ColorTokens.secondaryText)
                    }
                    .frame(minWidth: 44, minHeight: 32)
                    .sensoryFeedback(.selection, trigger: replyHapticTrigger)
                    
                    // Load replies button (if has replies and not fully expanded)
                    if comment.replyCount > 0 {
                        Button(action: {
                            loadRepliesHapticTrigger.toggle()
                            onLoadReplies()
                        }) {
                            HStack(spacing: SpacingTokens.xxs) {
                                Image(systemName: "bubble.left")
                                    .font(.system(size: 14, weight: .medium))
                                Text("\(comment.replyCount) \(comment.replyCount == 1 ? "reply" : "replies")")
                                    .font(TypographyScale.caption1)
                            }
                            .foregroundColor(ColorTokens.agoraBrand)
                        }
                        .frame(minWidth: 44, minHeight: 32)
                        .sensoryFeedback(.selection, trigger: loadRepliesHapticTrigger)
                    }
                }
                .padding(.top, SpacingTokens.xxs)
            }
            .padding(.leading, SpacingTokens.sm)
            
            Spacer()
        }
        .padding(.horizontal, SpacingTokens.md)
        .padding(.vertical, SpacingTokens.sm)
    }
    
    // MARK: - Dynamic Sizing
    
    /// Avatar size decreases with depth (40 → 32 → 28)
    private var avatarSize: CGFloat {
        switch comment.depth {
        case 0: return 40
        case 1: return 32
        default: return 28
        }
    }
    
    /// Avatar font size matches avatar size
    private var avatarFont: Font {
        switch comment.depth {
        case 0: return TypographyScale.body
        case 1: return TypographyScale.footnote
        default: return TypographyScale.caption1
        }
    }
    
    /// Body font slightly smaller at deeper levels
    private var bodyFont: Font {
        comment.depth >= 2 ? TypographyScale.footnote : TypographyScale.body
    }
}

// MARK: - Preview Support

#if DEBUG
#Preview("Top-Level Comment (Depth 0)") {
    PreviewDeps.scoped {
        VStack(spacing: 0) {
            ThreadedCommentView(
                comment: Comment(
                    id: "comment-1",
                    postId: "post-1",
                    authorId: "author-1",
                    parentCommentId: nil,
                    depth: 0,
                    body: "This is a top-level comment with some thoughtful analysis about the post.",
                    replyCount: 3,
                    createdAt: Date().addingTimeInterval(-3600),
                    updatedAt: Date().addingTimeInterval(-3600),
                    authorDisplayName: "Jane Doe",
                    authorDisplayHandle: "jane.doe",
                    authorAvatarUrl: nil
                ),
                onReply: {},
                onLoadReplies: {}
            )
            
            Divider()
        }
    }
}

#Preview("Reply (Depth 1)") {
    PreviewDeps.scoped {
        VStack(spacing: 0) {
            ThreadedCommentView(
                comment: Comment(
                    id: "comment-2",
                    postId: "post-1",
                    authorId: "author-2",
                    parentCommentId: "comment-1",
                    depth: 1,
                    body: "Great point! I completely agree with your analysis.",
                    replyCount: 2,
                    createdAt: Date().addingTimeInterval(-1800),
                    updatedAt: Date().addingTimeInterval(-1800),
                    authorDisplayName: "John Smith",
                    authorDisplayHandle: "john.smith",
                    authorAvatarUrl: nil
                ),
                onReply: {},
                onLoadReplies: {}
            )
            
            Divider()
        }
    }
}

#Preview("Deep Reply (Depth 2)") {
    PreviewDeps.scoped {
        VStack(spacing: 0) {
            ThreadedCommentView(
                comment: Comment(
                    id: "comment-3",
                    postId: "post-1",
                    authorId: "author-3",
                    parentCommentId: "comment-2",
                    depth: 2,
                    body: "Thanks! Can you elaborate on the second point you made?",
                    replyCount: 0,
                    createdAt: Date().addingTimeInterval(-900),
                    updatedAt: Date().addingTimeInterval(-900),
                    authorDisplayName: "Alice Johnson",
                    authorDisplayHandle: "alice.j",
                    authorAvatarUrl: nil
                ),
                onReply: {},
                onLoadReplies: {}
            )
            
            Divider()
        }
    }
}

#Preview("All Depths") {
    PreviewDeps.scoped {
        ScrollView {
            VStack(spacing: 0) {
                // Depth 0
                ThreadedCommentView(
                    comment: Comment(
                        id: "comment-1",
                        postId: "post-1",
                        authorId: "author-1",
                        parentCommentId: nil,
                        depth: 0,
                        body: "Top-level comment",
                        replyCount: 2,
                        createdAt: Date().addingTimeInterval(-3600),
                        updatedAt: Date().addingTimeInterval(-3600),
                        authorDisplayName: "User 1",
                        authorDisplayHandle: "user1",
                        authorAvatarUrl: nil
                    ),
                    onReply: {},
                    onLoadReplies: {}
                )
                
                Divider()
                
                // Depth 1
                ThreadedCommentView(
                    comment: Comment(
                        id: "comment-2",
                        postId: "post-1",
                        authorId: "author-2",
                        parentCommentId: "comment-1",
                        depth: 1,
                        body: "First reply",
                        replyCount: 1,
                        createdAt: Date().addingTimeInterval(-1800),
                        updatedAt: Date().addingTimeInterval(-1800),
                        authorDisplayName: "User 2",
                        authorDisplayHandle: "user2",
                        authorAvatarUrl: nil
                    ),
                    onReply: {},
                    onLoadReplies: {}
                )
                
                Divider()
                
                // Depth 2
                ThreadedCommentView(
                    comment: Comment(
                        id: "comment-3",
                        postId: "post-1",
                        authorId: "author-3",
                        parentCommentId: "comment-2",
                        depth: 2,
                        body: "Deep reply",
                        replyCount: 0,
                        createdAt: Date().addingTimeInterval(-900),
                        updatedAt: Date().addingTimeInterval(-900),
                        authorDisplayName: "User 3",
                        authorDisplayHandle: "user3",
                        authorAvatarUrl: nil
                    ),
                    onReply: {},
                    onLoadReplies: {}
                )
                
                Divider()
            }
        }
    }
}
#endif


