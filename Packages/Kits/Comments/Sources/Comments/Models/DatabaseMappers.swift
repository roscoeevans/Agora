import Foundation
import AppFoundation

// MARK: - Database Mappers

extension DatabaseComment {
    /// Maps database comment to domain Comment model
    func toDomain() throws -> Comment {
        // Parse ISO 8601 timestamps
        let iso8601 = ISO8601DateFormatter()
        iso8601.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let createdAt = iso8601.date(from: created_at) else {
            throw CommentError.serverError("Invalid created_at timestamp")
        }
        
        guard let updatedAt = iso8601.date(from: updated_at) else {
            throw CommentError.serverError("Invalid updated_at timestamp")
        }
        
        return Comment(
            id: id,
            postId: post_id,
            authorId: author_id,
            parentCommentId: parent_comment_id,
            depth: depth,
            body: body,
            replyCount: reply_count,
            createdAt: createdAt,
            updatedAt: updatedAt,
            authorDisplayName: author_display_name,
            authorDisplayHandle: author_display_handle,
            authorAvatarUrl: author_avatar_url
        )
    }
}

extension CursorData {
    /// Maps database cursor to domain CommentCursor
    func toDomain() throws -> CommentCursor {
        let iso8601 = ISO8601DateFormatter()
        iso8601.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let createdAt = iso8601.date(from: last_created_at) else {
            throw CommentError.serverError("Invalid cursor timestamp")
        }
        
        return CommentCursor(lastCreatedAt: createdAt, lastID: last_id)
    }
}

extension CommentCursor {
    /// Converts domain cursor to database format for RPC calls
    func toDatabase() -> CursorData {
        let iso8601 = ISO8601DateFormatter()
        iso8601.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        return CursorData(
            last_created_at: iso8601.string(from: lastCreatedAt),
            last_id: lastID
        )
    }
}


