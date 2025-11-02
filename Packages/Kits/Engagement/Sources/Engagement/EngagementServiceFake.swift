import Foundation
import AppFoundation

/// Fake engagement service for testing and previews
public actor EngagementServiceFake: EngagementService {
    public var likedPosts: Set<String> = []
    public var repostedPosts: Set<String> = []
    public var shouldFail = false
    public var delay: Duration = .zero
    
    public init() {}
    
    public func toggleLike(postId: String) async throws -> LikeResult {
        if delay > .zero {
            try await Task.sleep(for: delay)
        }
        
        if shouldFail {
            throw EngagementError.networkError
        }
        
        let isLiked: Bool
        let count: Int
        
        if likedPosts.contains(postId) {
            likedPosts.remove(postId)
            isLiked = false
            count = 41  // Mock decrement
        } else {
            likedPosts.insert(postId)
            isLiked = true
            count = 42  // Mock increment
        }
        
        return LikeResult(isLiked: isLiked, likeCount: count)
    }
    
    public func toggleRepost(postId: String) async throws -> RepostResult {
        if delay > .zero {
            try await Task.sleep(for: delay)
        }
        
        if shouldFail {
            throw EngagementError.networkError
        }
        
        let isReposted: Bool
        let count: Int
        
        if repostedPosts.contains(postId) {
            repostedPosts.remove(postId)
            isReposted = false
            count = 7  // Mock decrement
        } else {
            repostedPosts.insert(postId)
            isReposted = true
            count = 8  // Mock increment
        }
        
        return RepostResult(isReposted: isReposted, repostCount: count)
    }
    
    public func getShareURL(postId: String) async throws -> URL {
        if delay > .zero {
            try await Task.sleep(for: delay)
        }
        
        if shouldFail {
            throw EngagementError.networkError
        }
        
        return URL(string: "https://agora.app/p/\(postId)")!
    }
    
    public func recordShare(postId: String) async throws -> ShareResult {
        if delay > .zero {
            try await Task.sleep(for: delay)
        }
        
        if shouldFail {
            throw EngagementError.networkError
        }
        
        // Mock: Always returns count of 5 (idempotent in real implementation)
        return ShareResult(shareCount: 5)
    }
}

