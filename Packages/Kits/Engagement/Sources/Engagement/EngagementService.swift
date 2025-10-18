import Foundation
import AppFoundation

/// Service for handling post engagement actions (like, repost, share)
/// This protocol is also defined in DesignSystem for UI layer to avoid circular dependencies
public protocol EngagementService: Sendable {
    /// Toggle like on a post (idempotent)
    /// - Parameter postId: The ID of the post to like/unlike
    /// - Returns: Result containing new like state and count
    /// - Throws: EngagementError if operation fails
    func toggleLike(postId: String) async throws -> LikeResult
    
    /// Toggle repost on a post (idempotent)
    /// - Parameter postId: The ID of the post to repost/unrepost
    /// - Returns: Result containing new repost state and count
    /// - Throws: EngagementError if operation fails
    func toggleRepost(postId: String) async throws -> RepostResult
    
    /// Get shareable URL for a post
    /// - Parameter postId: The ID of the post to share
    /// - Returns: Deep link URL for the post
    /// - Throws: EngagementError if operation fails
    func getShareURL(postId: String) async throws -> URL
}

/// Result of a like toggle operation
public struct LikeResult: Sendable, Equatable {
    public let isLiked: Bool
    public let likeCount: Int
    
    public init(isLiked: Bool, likeCount: Int) {
        self.isLiked = isLiked
        self.likeCount = likeCount
    }
}

/// Result of a repost toggle operation
public struct RepostResult: Sendable, Equatable {
    public let isReposted: Bool
    public let repostCount: Int
    
    public init(isReposted: Bool, repostCount: Int) {
        self.isReposted = isReposted
        self.repostCount = repostCount
    }
}

/// Errors that can occur during engagement operations
public enum EngagementError: LocalizedError, Sendable {
    case postNotFound
    case unauthorized
    case networkError
    case serverError(String)
    case rateLimited
    
    public var errorDescription: String? {
        switch self {
        case .postNotFound:
            return "Post not found"
        case .unauthorized:
            return "You must be signed in to perform this action"
        case .networkError:
            return "Network connection failed. Please try again."
        case .serverError(let message):
            return "Server error: \(message)"
        case .rateLimited:
            return "You're doing that too quickly. Please wait a moment."
        }
    }
}

