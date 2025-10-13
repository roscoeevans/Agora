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
                let basePost = apiPost.value1
                let enhancedData = apiPost.value2
                return Post(
                    id: basePost.id,
                    text: basePost.text,
                    author: basePost.authorId,
                    authorDisplayHandle: basePost.authorDisplayHandle,
                    timestamp: basePost.createdAt,
                    likeCount: basePost.likeCount ?? 0,
                    repostCount: basePost.repostCount ?? 0,
                    replyCount: basePost.replyCount ?? 0,
                    score: enhancedData.score.map(Double.init),
                    reasons: enhancedData.reasons?.map { RecommendationReason(signal: $0.signal, weight: Double($0.weight)) },
                    explore: enhancedData.explore
                )
            }
            self.nextCursor = response.nextCursor
            
            // Track explore impressions
            let exploreCount = posts.filter { $0.explore == true }.count
            analytics.track(event: "feed_refresh_completed", properties: [
                "feed_type": "for_you",
                "post_count": posts.count,
                "explore_count": exploreCount
            ])
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
                let basePost = apiPost.value1
                let enhancedData = apiPost.value2
                return Post(
                    id: basePost.id,
                    text: basePost.text,
                    author: basePost.authorId,
                    authorDisplayHandle: basePost.authorDisplayHandle,
                    timestamp: basePost.createdAt,
                    likeCount: basePost.likeCount ?? 0,
                    repostCount: basePost.repostCount ?? 0,
                    replyCount: basePost.replyCount ?? 0,
                    score: enhancedData.score.map(Double.init),
                    reasons: enhancedData.reasons?.map { RecommendationReason(signal: $0.signal, weight: Double($0.weight)) },
                    explore: enhancedData.explore
                )
            }
            self.posts.append(contentsOf: newPosts)
            self.nextCursor = response.nextCursor
            
            let exploreCount = newPosts.filter { $0.explore == true }.count
            analytics.track(event: "feed_load_more_completed", properties: [
                "new_posts_count": newPosts.count,
                "explore_count": exploreCount
            ])
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
    public let authorDisplayHandle: String
    public let timestamp: Date
    public let likeCount: Int
    public let repostCount: Int
    public let replyCount: Int
    
    // Enhanced feed fields
    public let score: Double?
    public let reasons: [RecommendationReason]?
    public let explore: Bool?
    
    public init(
        id: String, 
        text: String, 
        author: String, 
        authorDisplayHandle: String? = nil, 
        timestamp: Date = Date(), 
        likeCount: Int = 0, 
        repostCount: Int = 0, 
        replyCount: Int = 0,
        score: Double? = nil,
        reasons: [RecommendationReason]? = nil,
        explore: Bool? = nil
    ) {
        self.id = id
        self.text = text
        self.author = author
        self.authorDisplayHandle = authorDisplayHandle ?? author
        self.timestamp = timestamp
        self.likeCount = likeCount
        self.repostCount = repostCount
        self.replyCount = replyCount
        self.score = score
        self.reasons = reasons
        self.explore = explore
    }
}

public struct RecommendationReason: Codable {
    public let signal: String
    public let weight: Double
    
    public init(signal: String, weight: Double) {
        self.signal = signal
        self.weight = weight
    }
}
