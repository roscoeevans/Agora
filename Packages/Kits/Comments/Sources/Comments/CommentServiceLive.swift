import Foundation
import AppFoundation
import Supabase

/// Live comment service implementation using Supabase RPC functions
final class CommentServiceLive: CommentServiceProtocol {
    private let supabase: SupabaseClient
    
    init(supabase: SupabaseClient) {
        self.supabase = supabase
    }
    
    // MARK: - Fetch Top-Level Comments
    
    func fetchTopLevelComments(
        postId: String,
        pageSize: Int = 50,
        cursor: CommentCursor? = nil
    ) async throws -> (items: [Comment], next: CommentCursor?) {
        do {
            // Build RPC parameters
            let dbCursor = cursor?.toDatabase()
            let params = FetchCommentsParams(
                p_post_id: postId,
                p_limit: pageSize,
                p_cursor_created_at: dbCursor?.last_created_at,
                p_cursor_id: dbCursor?.last_id
            )
            
            // Call fetch_post_comments RPC
            let response: FetchCommentsResponse = try await supabase
                .rpc("fetch_post_comments", params: params)
                .execute()
                .value
            
            // Map to domain models
            let comments = try response.items.map { try $0.toDomain() }
            let nextCursor = try response.next_cursor?.toDomain()
            
            return (items: comments, next: nextCursor)
            
        } catch let error as CommentError {
            throw error
        } catch {
            throw CommentError.networkError
        }
    }
    
    // MARK: - Fetch Replies
    
    func fetchReplies(
        parentId: String,
        pageSize: Int = 25,
        cursor: CommentCursor? = nil
    ) async throws -> (items: [Comment], next: CommentCursor?) {
        do {
            // Build RPC parameters
            let dbCursor = cursor?.toDatabase()
            let params = FetchRepliesParams(
                p_parent_id: parentId,
                p_limit: pageSize,
                p_cursor_created_at: dbCursor?.last_created_at,
                p_cursor_id: dbCursor?.last_id
            )
            
            // Call fetch_comment_replies RPC
            let response: FetchRepliesResponse = try await supabase
                .rpc("fetch_comment_replies", params: params)
                .execute()
                .value
            
            // Map to domain models
            let replies = try response.items.map { try $0.toDomain() }
            let nextCursor = try response.next_cursor?.toDomain()
            
            return (items: replies, next: nextCursor)
            
        } catch let error as CommentError {
            throw error
        } catch {
            throw CommentError.networkError
        }
    }
    
    // MARK: - Create Comment
    
    func createComment(postId: String, body: String) async throws -> Comment {
        // Validate body length
        guard !body.isEmpty else {
            throw CommentError.bodyTooShort
        }
        
        guard body.count <= 2000 else {
            throw CommentError.bodyTooLong
        }
        
        do {
            let params = CreateCommentRequest(
                p_post_id: postId,
                p_body: body
            )
            
            // Call create_comment RPC
            let dbComment: DatabaseComment = try await supabase
                .rpc("create_comment", params: params)
                .execute()
                .value
            
            // Map to domain model
            return try dbComment.toDomain()
            
        } catch let error as CommentError {
            throw error
        } catch {
            throw CommentError.networkError
        }
    }
    
    // MARK: - Create Reply
    
    func createReply(parentId: String, body: String) async throws -> Comment {
        // Validate body length
        guard !body.isEmpty else {
            throw CommentError.bodyTooShort
        }
        
        guard body.count <= 2000 else {
            throw CommentError.bodyTooLong
        }
        
        do {
            let params = CreateReplyRequest(
                p_parent_id: parentId,
                p_body: body
            )
            
            // Call create_reply RPC (enforces max depth = 2)
            let dbComment: DatabaseComment = try await supabase
                .rpc("create_reply", params: params)
                .execute()
                .value
            
            // Map to domain model
            return try dbComment.toDomain()
            
        } catch let error as CommentError {
            throw error
        } catch {
            // Check if it's a max depth error from backend
            if let errorMessage = (error as NSError).userInfo["message"] as? String,
               errorMessage.contains("depth") {
                throw CommentError.maxDepthExceeded
            }
            throw CommentError.networkError
        }
    }
}

