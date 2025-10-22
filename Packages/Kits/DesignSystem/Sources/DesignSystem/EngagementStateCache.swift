//
//  EngagementStateCache.swift
//  DesignSystem
//
//  Shared cache for engagement state persistence across navigation
//

import Foundation
import AppFoundation

/// Shared cache for engagement state to persist optimistic updates across navigation
/// This ensures that liked/reposted state persists when navigating between tabs
@MainActor
public final class EngagementStateCache: ObservableObject {
    public static let shared = EngagementStateCache()
    
    private var cachedStates: [String: CachedEngagementState] = [:]
    private let maxCacheSize = 1000 // Prevent memory leaks
    
    private init() {}
    
    /// Get cached engagement state for a post, or create new one
    public func getOrCreateState(for post: Post, engagementService: any Sendable) async -> PostEngagementState {
        let postId = post.id
        
        // Check if we have cached state
        if let cached = cachedStates[postId] {
            // Update the cached state with latest post data (counts, etc.)
            await cached.updateFromPost(post)
            return cached.state
        }
        
        // Create new state and cache it
        let newState = PostEngagementState(post: post, engagementService: engagementService)
        let cachedState = CachedEngagementState(state: newState, postId: postId)
        cachedStates[postId] = cachedState
        
        // Cleanup old entries if cache is too large
        cleanupCacheIfNeeded()
        
        return newState
    }
    
    /// Update cached state when engagement changes
    public func updateState(for postId: String, isLiked: Bool, likeCount: Int, isReposted: Bool, repostCount: Int) async {
        await cachedStates[postId]?.updateEngagement(
            isLiked: isLiked,
            likeCount: likeCount,
            isReposted: isReposted,
            repostCount: repostCount
        )
    }
    
    /// Remove cached state for a post (when post is deleted, etc.)
    public func removeState(for postId: String) {
        cachedStates.removeValue(forKey: postId)
    }
    
    /// Clear all cached states
    public func clearAll() {
        cachedStates.removeAll()
    }
    
    /// Get current cache size for debugging
    public var cacheSize: Int {
        return cachedStates.count
    }
    
    private func cleanupCacheIfNeeded() {
        guard cachedStates.count > maxCacheSize else { return }
        
        // Remove oldest entries (simple LRU approximation)
        let sortedEntries = cachedStates.sorted { $0.value.lastAccessed < $1.value.lastAccessed }
        let entriesToRemove = sortedEntries.prefix(cachedStates.count - maxCacheSize + 100) // Remove 100 extra
        
        for (postId, _) in entriesToRemove {
            cachedStates.removeValue(forKey: postId)
        }
    }
}

/// Cached engagement state wrapper
private final class CachedEngagementState {
    let state: PostEngagementState
    let postId: String
    private(set) var lastAccessed: Date
    
    init(state: PostEngagementState, postId: String) {
        self.state = state
        self.postId = postId
        self.lastAccessed = Date()
    }
    
    @MainActor
    func updateFromPost(_ post: Post) {
        lastAccessed = Date()
        
        // Update counts from server data, but preserve optimistic engagement state
        // This ensures we don't lose optimistic changes when refreshing feed data
        state.likeCount = post.likeCount
        state.repostCount = post.repostCount
        
        // Only update engagement state if we're not currently performing an action
        // This prevents overriding optimistic updates with stale server data
        if !state.isLikingInProgress {
            // Only update if the server data differs significantly (to handle race conditions)
            let serverLiked = post.isLikedByViewer
            if abs(state.likeCount - post.likeCount) > 1 || state.isLiked != serverLiked {
                // Server data is different, update from server
                state.isLiked = serverLiked
            }
        }
        
        if !state.isRepostingInProgress {
            let serverReposted = post.isRepostedByViewer
            if abs(state.repostCount - post.repostCount) > 1 || state.isReposted != serverReposted {
                // Server data is different, update from server
                state.isReposted = serverReposted
            }
        }
    }
    
    @MainActor
    func updateEngagement(isLiked: Bool, likeCount: Int, isReposted: Bool, repostCount: Int) {
        lastAccessed = Date()
        
        state.isLiked = isLiked
        state.likeCount = likeCount
        state.isReposted = isReposted
        state.repostCount = repostCount
    }
}
