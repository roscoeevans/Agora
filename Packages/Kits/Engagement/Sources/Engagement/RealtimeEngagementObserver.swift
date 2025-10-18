import Foundation
import AppFoundation
import Supabase

/// Observes real-time engagement count updates via Supabase Realtime
/// Uses a SINGLE channel per feed (not per post) with debounced visible post tracking
public actor RealtimeEngagementObserver {
    private let supabase: SupabaseClient
    private var subscription: RealtimeChannel?
    private var visiblePostIds: Set<String> = []
    private var updateDebounceTask: Task<Void, Never>?
    
    /// Stream of engagement updates (postId, likeCount, repostCount)
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
        await subscription?.unsubscribe()
        subscription = nil
    }
    
    /// Resume observing (called on foreground)
    private func resumeObserving() async {
        await resubscribe()
    }
    
    /// Resubscribe with current visible posts
    private func resubscribe() async {
        // Unsubscribe existing
        await subscription?.unsubscribe()
        subscription = nil
        
        guard !visiblePostIds.isEmpty else { return }
        
        // Build properly quoted filter for UUIDs/BigInts
        // For BigInt post IDs, we don't need quotes
        let postIdList = visiblePostIds.joined(separator: ",")
        let filter = "id=in.(\(postIdList))"
        
        // Single channel for all visible posts
        let channelId = "engagement_\(UUID().uuidString)"
        
        do {
            subscription = supabase.channel(channelId)
            
            // Subscribe to post updates
            let changeStream = await subscription!.postgresChange(
                InsertAction.self,
                schema: "public",
                table: "posts",
                filter: filter
            )
            
            // Listen to changes
            Task {
                for await change in changeStream {
                    await handleChange(change)
                }
            }
            
            // Subscribe to the channel
            await subscription!.subscribe()
        } catch {
            print("[RealtimeEngagementObserver] Failed to subscribe: \(error)")
        }
    }
    
    /// Stop observing updates
    public func stopObserving() async {
        updateDebounceTask?.cancel()
        await subscription?.unsubscribe()
        subscription = nil
    }
    
    private func handleChange(_ change: any PostgresAction) {
        // Extract post data from the change
        guard let record = change.record,
              let postId = record["id"] as? String,
              let likeCount = record["like_count"] as? Int,
              let repostCount = record["repost_count"] as? Int else {
            return
        }
        
        let update = EngagementUpdate(
            postId: postId,
            likeCount: likeCount,
            repostCount: repostCount
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
    
    public init(postId: String, likeCount: Int, repostCount: Int) {
        self.postId = postId
        self.likeCount = likeCount
        self.repostCount = repostCount
    }
}

