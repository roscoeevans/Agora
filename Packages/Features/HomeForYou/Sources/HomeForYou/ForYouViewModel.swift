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
    
    private let networking: APIClient
    private let analytics: AnalyticsManager
    private var nextCursor: String?
    
    public init(networking: APIClient = APIClient.shared, analytics: AnalyticsManager = AnalyticsManager.shared) {
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
            analytics.track(event: "feed_refresh_started", properties: ["feed_type": "for_you"])
            
            // Call the real API
            let response = try await networking.getForYouFeed(limit: 20)
            
            // Map API posts to view model posts
            self.posts = response.posts.map { apiPost in
                Post(
                    id: apiPost.id,
                    text: apiPost.text,
                    author: apiPost.authorId, // TODO: Load author display name
                    timestamp: apiPost.createdAt,
                    likeCount: apiPost.likeCount ?? 0,
                    repostCount: apiPost.repostCount ?? 0,
                    replyCount: apiPost.replyCount ?? 0
                )
            }
            self.nextCursor = response.nextCursor
            
            analytics.track(event: "feed_refresh_completed", properties: ["feed_type": "for_you", "post_count": posts.count])
        } catch {
            self.error = error
            analytics.track(event: "feed_refresh_failed", properties: ["feed_type": "for_you", "error": error.localizedDescription])
            print("[ForYouViewModel] ❌ Failed to load feed: \(error)")
        }
    }
    
    public func loadMore() async {
        guard let cursor = nextCursor, !isLoading else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            analytics.track(event: "feed_load_more", properties: ["feed_type": "for_you"])
            
            let response = try await networking.getForYouFeed(cursor: cursor, limit: 20)
            
            // Append new posts
            let newPosts = response.posts.map { apiPost in
                Post(
                    id: apiPost.id,
                    text: apiPost.text,
                    author: apiPost.authorId,
                    timestamp: apiPost.createdAt,
                    likeCount: apiPost.likeCount ?? 0,
                    repostCount: apiPost.repostCount ?? 0,
                    replyCount: apiPost.replyCount ?? 0
                )
            }
            self.posts.append(contentsOf: newPosts)
            self.nextCursor = response.nextCursor
            
            analytics.track(event: "feed_load_more_completed", properties: ["new_posts_count": newPosts.count])
        } catch {
            self.error = error
            analytics.track(event: "feed_load_more_failed", properties: ["error": error.localizedDescription])
        }
    }
}

public struct Post: Identifiable, Codable {
    public let id: String
    public let text: String
    public let author: String
    public let timestamp: Date
    public let likeCount: Int
    public let repostCount: Int
    public let replyCount: Int
    
    public init(id: String, text: String, author: String, timestamp: Date = Date(), likeCount: Int = 0, repostCount: Int = 0, replyCount: Int = 0) {
        self.id = id
        self.text = text
        self.author = author
        self.timestamp = timestamp
        self.likeCount = likeCount
        self.repostCount = repostCount
        self.replyCount = replyCount
    }
}
