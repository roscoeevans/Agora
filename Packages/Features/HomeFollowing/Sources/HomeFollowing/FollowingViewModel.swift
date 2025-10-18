//
//  FollowingViewModel.swift
//  Agora
//
//  Created by Agora Team on 2024.
//

import Foundation
import SwiftUI
import Networking
import Analytics

@MainActor
@Observable
public class FollowingViewModel {
    public var posts: [Post] = []
    public var isLoading = false
    public var error: Error?
    
    private let networking: any AgoraAPIClient
    private let analytics: AnalyticsClient
    
    /// Initialize FollowingViewModel with explicit dependencies
    /// Following the DI rule pattern
    public init(
        networking: any AgoraAPIClient,
        analytics: AnalyticsClient
    ) {
        self.networking = networking
        self.analytics = analytics
        
        // Load initial data on init
        Task {
            await refresh()
        }
    }
    
    public func refresh() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            await analytics.track(event: "feed_refresh_started", properties: ["feed_type": "following"])
            
            // Call the real API
            let response = try await networking.fetchFollowingFeed(cursor: nil, limit: 20)
            
            self.posts = response.posts
            self.nextCursor = response.nextCursor
            
            await analytics.track(event: "feed_refresh_completed", properties: [
                "feed_type": "following",
                "post_count": posts.count
            ])
        } catch {
            self.error = error
            await analytics.track(event: "feed_refresh_failed", properties: ["feed_type": "following", "error": error.localizedDescription])
            print("[FollowingViewModel] ❌ Failed to load following feed: \(error)")
        }
    }
    
    public func loadMore() async {
        guard let cursor = nextCursor, !isLoading else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            await analytics.track(event: "feed_load_more", properties: ["feed_type": "following"])
            
            let response = try await networking.fetchFollowingFeed(cursor: cursor, limit: 20)
            
            // Append new posts
            self.posts.append(contentsOf: response.posts)
            self.nextCursor = response.nextCursor
            
            await analytics.track(event: "feed_load_more_completed", properties: [
                "new_posts_count": response.posts.count
            ])
        } catch {
            self.error = error
            await analytics.track(event: "feed_load_more_failed", properties: ["error": error.localizedDescription])
        }
    }
    
    private var nextCursor: String?
}

// Note: Post is imported from Networking (which re-exports AppFoundation)
// No need to define it here - use the canonical AppFoundation.Post