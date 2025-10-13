//
//  ForYouViewModel.swift
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
public class ForYouViewModel {
    public var posts: [Post] = []
    public var isLoading = false
    public var error: Error?
    
    private let networking: any AgoraAPIClient
    private let analytics: AnalyticsClient
    private var nextCursor: String?
    
    /// Initialize ForYouViewModel with explicit dependencies
    /// 
    /// Following the DI rule:
    /// - No default parameters (forces explicit injection)
    /// - Dependencies are protocols, not concrete types
    /// - Injected via initializer, not pulled from singletons
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
            await analytics.track(event: "feed_refresh_started", properties: ["feed_type": "for_you"])
            
            // Call the real API
            let response = try await networking.fetchForYouFeed(cursor: nil, limit: 20)
            
            // Use the protocol's Post directly - it now includes enhanced metadata!
            self.posts = response.posts
            self.nextCursor = response.nextCursor
            
            // Track explore impressions using enhanced metadata
            let exploreCount = posts.filter { $0.explore == true }.count
            await analytics.track(event: "feed_refresh_completed", properties: [
                "feed_type": "for_you",
                "post_count": posts.count,
                "explore_count": exploreCount
            ])
        } catch {
            self.error = error
            await analytics.track(event: "feed_refresh_failed", properties: ["feed_type": "for_you", "error": error.localizedDescription])
            print("[ForYouViewModel] ❌ Failed to load feed: \(error)")
        }
    }
    
    public func loadMore() async {
        guard let cursor = nextCursor, !isLoading else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            await analytics.track(event: "feed_load_more", properties: ["feed_type": "for_you"])
            
            let response = try await networking.fetchForYouFeed(cursor: cursor, limit: 20)
            
            // Append new posts directly from protocol
            self.posts.append(contentsOf: response.posts)
            self.nextCursor = response.nextCursor
            
            // Track explore impressions using enhanced metadata
            let exploreCount = response.posts.filter { $0.explore == true }.count
            await analytics.track(event: "feed_load_more_completed", properties: [
                "new_posts_count": response.posts.count,
                "explore_count": exploreCount
            ])
        } catch {
            self.error = error
            await analytics.track(event: "feed_load_more_failed", properties: ["error": error.localizedDescription])
        }
    }
}

// Note: Post and RecommendationReason are now imported from Networking module
// (which re-exports them from AppFoundation via @_exported import AppFoundation)
