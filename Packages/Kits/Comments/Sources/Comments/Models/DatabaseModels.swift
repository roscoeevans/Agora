import Foundation

// MARK: - Database Models

/// Database comment row returned from Supabase RPC functions
struct DatabaseComment: Codable {
    let id: String
    let post_id: String
    let author_id: String
    let parent_comment_id: String?
    let body: String
    let depth: Int
    let reply_count: Int
    let created_at: String  // ISO 8601 timestamp
    let updated_at: String  // ISO 8601 timestamp
    
    // Author info from join
    let author_display_name: String?
    let author_display_handle: String?
    let author_avatar_url: String?
}

/// Response from fetch_post_comments RPC
struct FetchCommentsResponse: Codable {
    let items: [DatabaseComment]
    let next_cursor: CursorData?
}

/// Response from fetch_comment_replies RPC
struct FetchRepliesResponse: Codable {
    let items: [DatabaseComment]
    let next_cursor: CursorData?
}

/// Cursor data for pagination
struct CursorData: Codable {
    let last_created_at: String  // ISO 8601 timestamp
    let last_id: String
}

/// Request parameters for fetch_post_comments RPC
struct FetchCommentsParams: Encodable {
    let p_post_id: String
    let p_limit: Int
    let p_cursor_created_at: String?
    let p_cursor_id: String?
}

/// Request parameters for fetch_comment_replies RPC
struct FetchRepliesParams: Encodable {
    let p_parent_id: String
    let p_limit: Int
    let p_cursor_created_at: String?
    let p_cursor_id: String?
}

/// Request body for create_comment RPC
struct CreateCommentRequest: Encodable {
    let p_post_id: String
    let p_body: String
}

/// Request body for create_reply RPC
struct CreateReplyRequest: Encodable {
    let p_parent_id: String
    let p_body: String
}

