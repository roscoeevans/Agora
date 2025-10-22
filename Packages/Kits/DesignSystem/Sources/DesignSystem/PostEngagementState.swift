//
//  PostEngagementState.swift
//  DesignSystem
//
//  Observable state for post engagement with optimistic updates
//

import Foundation
import Observation
import AppFoundation

/// Observable state for post engagement with optimistic updates and rollback
@Observable
@MainActor
public final class PostEngagementState {
    // Optimistic state
    public var isLiked: Bool
    public var likeCount: Int
    public var isReposted: Bool
    public var repostCount: Int
    
    // Loading states
    public var isLikingInProgress = false
    public var isRepostingInProgress = false
    
    // Error state
    public var error: Error?
    
    private let postId: String
    private let engagementService: any Sendable  // Type-erased to avoid circular dependency
    
    public init(post: Post, engagementService: any Sendable) {
        self.postId = post.id
        self.isLiked = post.isLikedByViewer
        self.likeCount = post.likeCount
        self.isReposted = post.isRepostedByViewer
        self.repostCount = post.repostCount
        self.engagementService = engagementService
    }
    
    /// Toggle like with optimistic update and rollback on failure
    public func toggleLike() async {
        // Prevent reentrancy
        guard !isLikingInProgress else { return }
        
        // Capture previous state for rollback
        let previousLiked = isLiked
        let previousCount = likeCount
        
        // Optimistic update
        isLiked.toggle()
        likeCount = max(0, likeCount + (isLiked ? 1 : -1))  // Clamp to 0
        isLikingInProgress = true
        error = nil
        
        // Update cache immediately with optimistic state
        await EngagementStateCache.shared.updateState(
            for: postId,
            isLiked: isLiked,
            likeCount: likeCount,
            isReposted: isReposted,
            repostCount: repostCount
        )
        
        do {
            // Call service (cast to EngagementService protocol from Engagement kit)
            guard let service = engagementService as? any EngagementService else {
                throw EngagementStateError.serviceNotAvailable
            }
            
            let result = try await service.toggleLike(postId: postId)
            
            // Reconcile with server state
            isLiked = result.isLiked
            likeCount = max(0, result.likeCount)  // Clamp to 0
            
            // Update cache with final server state
            await EngagementStateCache.shared.updateState(
                for: postId,
                isLiked: isLiked,
                likeCount: likeCount,
                isReposted: isReposted,
                repostCount: repostCount
            )
        } catch {
            // Rollback on error
            isLiked = previousLiked
            likeCount = previousCount
            self.error = error
            
            // Update cache with rolled back state
            await EngagementStateCache.shared.updateState(
                for: postId,
                isLiked: isLiked,
                likeCount: likeCount,
                isReposted: isReposted,
                repostCount: repostCount
            )
        }
        
        isLikingInProgress = false
    }
    
    /// Toggle repost with optimistic update and rollback on failure
    public func toggleRepost() async {
        // Prevent reentrancy
        guard !isRepostingInProgress else { return }
        
        // Capture previous state for rollback
        let previousReposted = isReposted
        let previousCount = repostCount
        
        // Optimistic update
        isReposted.toggle()
        repostCount = max(0, repostCount + (isReposted ? 1 : -1))  // Clamp to 0
        isRepostingInProgress = true
        error = nil
        
        // Update cache immediately with optimistic state
        await EngagementStateCache.shared.updateState(
            for: postId,
            isLiked: isLiked,
            likeCount: likeCount,
            isReposted: isReposted,
            repostCount: repostCount
        )
        
        do {
            // Call service (cast to EngagementService protocol from Engagement kit)
            guard let service = engagementService as? any EngagementService else {
                throw EngagementStateError.serviceNotAvailable
            }
            
            let result = try await service.toggleRepost(postId: postId)
            
            // Reconcile with server state
            isReposted = result.isReposted
            repostCount = max(0, result.repostCount)  // Clamp to 0
            
            // Update cache with final server state
            await EngagementStateCache.shared.updateState(
                for: postId,
                isLiked: isLiked,
                likeCount: likeCount,
                isReposted: isReposted,
                repostCount: repostCount
            )
        } catch {
            // Rollback on error
            isReposted = previousReposted
            repostCount = previousCount
            self.error = error
            
            // Update cache with rolled back state
            await EngagementStateCache.shared.updateState(
                for: postId,
                isLiked: isLiked,
                likeCount: likeCount,
                isReposted: isReposted,
                repostCount: repostCount
            )
        }
        
        isRepostingInProgress = false
    }
    
    /// Update counts from real-time observer
    public func updateFromRealtime(likeCount: Int, repostCount: Int) {
        // Only update if not currently performing an action
        if !isLikingInProgress {
            self.likeCount = likeCount
        }
        
        if !isRepostingInProgress {
            self.repostCount = repostCount
        }
    }
}

// MARK: - Errors

enum EngagementStateError: LocalizedError {
    case serviceNotAvailable
    
    var errorDescription: String? {
        switch self {
        case .serviceNotAvailable:
            return "Engagement service is not available"
        }
    }
}

