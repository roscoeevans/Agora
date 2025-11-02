import Foundation
import AppFoundation

/// Fake comment service for testing and previews
public final class CommentServiceFake: CommentServiceProtocol {
    
    public init() {}
    
    // MARK: - Fetch Top-Level Comments
    
    public func fetchTopLevelComments(
        postId: String,
        pageSize: Int,
        cursor: CommentCursor?
    ) async throws -> (items: [Comment], next: CommentCursor?) {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        let comments = [
            Comment(
                id: "comment-1",
                postId: postId,
                authorId: "author-1",
                parentCommentId: nil,
                depth: 0,
                body: "This is a great post! Really insightful analysis.",
                replyCount: 3,
                createdAt: Date().addingTimeInterval(-3600),
                updatedAt: Date().addingTimeInterval(-3600),
                authorDisplayName: "Jane Doe",
                authorDisplayHandle: "jane.doe",
                authorAvatarUrl: nil
            ),
            Comment(
                id: "comment-2",
                postId: postId,
                authorId: "author-2",
                parentCommentId: nil,
                depth: 0,
                body: "I disagree with this take. Here's why...",
                replyCount: 5,
                createdAt: Date().addingTimeInterval(-7200),
                updatedAt: Date().addingTimeInterval(-7200),
                authorDisplayName: "John Smith",
                authorDisplayHandle: "john.smith",
                authorAvatarUrl: nil
            ),
            Comment(
                id: "comment-3",
                postId: postId,
                authorId: "author-3",
                parentCommentId: nil,
                depth: 0,
                body: "Thanks for sharing! 🙌",
                replyCount: 0,
                createdAt: Date().addingTimeInterval(-10800),
                updatedAt: Date().addingTimeInterval(-10800),
                authorDisplayName: "Alice Johnson",
                authorDisplayHandle: "alice.j",
                authorAvatarUrl: nil
            )
        ]
        
        // Return with no next cursor for simplicity
        return (items: comments, next: nil)
    }
    
    // MARK: - Fetch Replies
    
    public func fetchReplies(
        parentId: String,
        pageSize: Int,
        cursor: CommentCursor?
    ) async throws -> (items: [Comment], next: CommentCursor?) {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        let replies = [
            Comment(
                id: "reply-1",
                postId: "mock-post-id",
                authorId: "author-4",
                parentCommentId: parentId,
                depth: 1,
                body: "Great point! I completely agree.",
                replyCount: 2,
                createdAt: Date().addingTimeInterval(-1800),
                updatedAt: Date().addingTimeInterval(-1800),
                authorDisplayName: "Bob Wilson",
                authorDisplayHandle: "bob.w",
                authorAvatarUrl: nil
            ),
            Comment(
                id: "reply-2",
                postId: "mock-post-id",
                authorId: "author-5",
                parentCommentId: parentId,
                depth: 1,
                body: "Can you elaborate on this?",
                replyCount: 0,
                createdAt: Date().addingTimeInterval(-3600),
                updatedAt: Date().addingTimeInterval(-3600),
                authorDisplayName: "Carol Davis",
                authorDisplayHandle: "carol.d",
                authorAvatarUrl: nil
            )
        ]
        
        return (items: replies, next: nil)
    }
    
    // MARK: - Create Comment
    
    public func createComment(postId: String, body: String) async throws -> Comment {
        // Validate body
        guard !body.isEmpty else {
            throw CommentError.bodyTooShort
        }
        
        guard body.count <= 2000 else {
            throw CommentError.bodyTooLong
        }
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        return Comment(
            id: "new-comment-\(UUID().uuidString)",
            postId: postId,
            authorId: "current-user",
            parentCommentId: nil,
            depth: 0,
            body: body,
            replyCount: 0,
            createdAt: Date(),
            updatedAt: Date(),
            authorDisplayName: "You",
            authorDisplayHandle: "current.user",
            authorAvatarUrl: nil
        )
    }
    
    // MARK: - Create Reply
    
    public func createReply(parentId: String, body: String) async throws -> Comment {
        // Validate body
        guard !body.isEmpty else {
            throw CommentError.bodyTooShort
        }
        
        guard body.count <= 2000 else {
            throw CommentError.bodyTooLong
        }
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        return Comment(
            id: "new-reply-\(UUID().uuidString)",
            postId: "mock-post-id",
            authorId: "current-user",
            parentCommentId: parentId,
            depth: 1, // Simplified - would need to calculate real depth
            body: body,
            replyCount: 0,
            createdAt: Date(),
            updatedAt: Date(),
            authorDisplayName: "You",
            authorDisplayHandle: "current.user",
            authorAvatarUrl: nil
        )
    }
}


