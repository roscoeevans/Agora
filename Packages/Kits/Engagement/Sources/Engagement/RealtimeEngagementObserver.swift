import Foundation
import AppFoundation
import Supabase
#if canImport(UIKit)
import UIKit
#endif

/// Observes real-time engagement count updates via Supabase Realtime
/// Uses server-side filtering with `in` operator (max 100 IDs per channel)
/// For >100 visible posts, creates multiple chunked subscriptions
/// NOTE: Postgres Changes doesn't scale as well as Broadcast; consider migrating at scale
public actor RealtimeEngagementObserver {
    private let supabase: SupabaseClient
    private var subscriptions: [RealtimeChannelV2] = []
    private var visiblePostIds: Set<String> = []
    private var updateDebounceTask: Task<Void, Never>?
    
    /// Maximum post IDs per subscription (Supabase limit for `in` operator)
    private let maxPostIdsPerChannel = 100
    
    /// Stream of engagement updates (postId, likeCount, repostCount, replyCount)
    public let updates: AsyncStream<EngagementUpdate>
    private let continuation: AsyncStream<EngagementUpdate>.Continuation
    
    /// Throttle state: map of postId -> last update time
    private var lastUpdateTimes: [String: Date] = [:]
    private let throttleInterval: TimeInterval = 0.3  // 300ms
    
    /// Buffer for updates received during in-progress actions
    private var bufferedUpdates: [String: EngagementUpdate] = [:]
    private var inProgressPosts: Set<String> = []
    
    public init(supabase: SupabaseClient) {
        self.supabase = supabase
        
        // Create async stream for updates
        (self.updates, self.continuation) = AsyncStream.makeStream()
        
        // Listen for app lifecycle events
        #if canImport(UIKit)
        Task { @MainActor in
            NotificationCenter.default.addObserver(
                forName: UIApplication.didEnterBackgroundNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { await self?.pauseObserving() }
            }
            
            NotificationCenter.default.addObserver(
                forName: UIApplication.willEnterForegroundNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { await self?.resumeObserving() }
            }
        }
        #endif
    }
    
    /// Update visible posts and resubscribe with new filter
    public func updateVisiblePosts(_ postIds: Set<String>) async {
        guard visiblePostIds != postIds else { return }
        visiblePostIds = postIds
        
        // Debounce subscription updates (avoid churn during scroll)
        updateDebounceTask?.cancel()
        updateDebounceTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            await resubscribe()
        }
    }
    
    /// Mark a post as having an action in progress (buffer realtime updates)
    public func markInProgress(_ postId: String) {
        inProgressPosts.insert(postId)
    }
    
    /// Mark a post as no longer in progress (flush buffered updates)
    public func markCompleted(_ postId: String) {
        inProgressPosts.remove(postId)
        
        // Flush any buffered update for this post
        if let buffered = bufferedUpdates.removeValue(forKey: postId) {
            continuation.yield(buffered)
        }
    }
    
    /// Pause observing (called on background)
    private func pauseObserving() async {
        for subscription in subscriptions {
            await subscription.unsubscribe()
        }
        subscriptions.removeAll()
    }
    
    /// Resume observing (called on foreground)
    private func resumeObserving() async {
        await resubscribe()
    }
    
    /// Resubscribe with current visible posts
    /// Chunks post IDs into batches of ≤100 and creates one channel per batch
    private func resubscribe() async {
        // Unsubscribe existing channels
        for subscription in subscriptions {
            await subscription.unsubscribe()
        }
        subscriptions.removeAll()
        
        guard !visiblePostIds.isEmpty else { return }
        
        // Chunk post IDs into batches of max 100 (Supabase `in` operator limit)
        let postIdChunks = Array(visiblePostIds).chunked(into: maxPostIdsPerChannel)
        
        // Create one subscription per chunk
        for (index, chunk) in postIdChunks.enumerated() {
            let channelId = "engagement_\(UUID().uuidString)_\(index)"
            let channel = supabase.channel(channelId)
            
            // Build server-side filter: id=in.(uuid1,uuid2,uuid3)
            // Note: UUIDs work unquoted; no spaces in the list
            let postIdsFilter = chunk.joined(separator: ",")
            let filter = "id=in.(\(postIdsFilter))"
            
            // Subscribe to UPDATE events on posts table with server-side filtering
            let updates = channel.postgresChange(
                UpdateAction.self,
                schema: "public",
                table: "posts",
                filter: filter  // ✅ Server-side filtering (max 100 IDs)
            )
            
            // Subscribe to the channel
            await channel.subscribe()
            subscriptions.append(channel)
            
            // Listen to updates in background task
            Task { [weak self] in
                for await update in updates {
                    await self?.handleUpdate(update)
                }
            }
        }
    }
    
    /// Stop observing updates
    public func stopObserving() async {
        updateDebounceTask?.cancel()
        for subscription in subscriptions {
            await subscription.unsubscribe()
        }
        subscriptions.removeAll()
    }
    
    private func handleUpdate(_ action: UpdateAction) {
        // Extract new record data from the update action
        let record = action.record
        
        guard let postId = record["id"] as? String,
              let likeCount = record["like_count"] as? Int,
              let repostCount = record["repost_count"] as? Int,
              let replyCount = record["reply_count"] as? Int else {
            return
        }
        
        // Server-side filter ensures we only get updates for visible posts
        // No need for client-side filtering anymore!
        
        let update = EngagementUpdate(
            postId: postId,
            likeCount: likeCount,
            repostCount: repostCount,
            replyCount: replyCount
        )
        
        // If action in progress, buffer the update
        if inProgressPosts.contains(postId) {
            bufferedUpdates[postId] = update
            return
        }
        
        // Throttle: only emit if >300ms since last update for this post
        let now = Date()
        if let lastUpdate = lastUpdateTimes[postId],
           now.timeIntervalSince(lastUpdate) < throttleInterval {
            // Drop update (too soon)
            return
        }
        
        lastUpdateTimes[postId] = now
        continuation.yield(update)
    }
    
    deinit {
        continuation.finish()
    }
}

/// Real-time engagement update
public struct EngagementUpdate: Sendable {
    public let postId: String
    public let likeCount: Int
    public let repostCount: Int
    public let replyCount: Int
    
    public init(postId: String, likeCount: Int, repostCount: Int, replyCount: Int) {
        self.postId = postId
        self.likeCount = likeCount
        self.repostCount = repostCount
        self.replyCount = replyCount
    }
}

// MARK: - Array Chunking Helper

private extension Array {
    /// Splits array into chunks of specified size
    /// Used for splitting post IDs into batches of ≤100 for Supabase `in` filter limit
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

