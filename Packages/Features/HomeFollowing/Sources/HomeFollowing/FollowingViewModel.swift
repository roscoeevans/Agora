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
        
        // Load placeholder data
        loadPlaceholderData()
    }
    
    public func refresh() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            await analytics.track(event: "feed_refresh_started", properties: ["feed_type": "following"])
            
            // TODO: Implement actual API call
            // For now, simulate network delay and reload placeholder data
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            loadPlaceholderData()
            
            await analytics.track(event: "feed_refresh_completed", properties: ["feed_type": "following", "post_count": posts.count])
        } catch {
            self.error = error
            await analytics.track(event: "feed_refresh_failed", properties: ["feed_type": "following", "error": error.localizedDescription])
        }
    }
    
    public func loadMore() async {
        // TODO: Implement pagination
        await analytics.track(event: "feed_load_more", properties: ["feed_type": "following"])
    }
    
    private func loadPlaceholderData() {
        posts = [
            Post(text: "Just posted my first thought on Agora! Excited to be part of this community.", author: "Alice Johnson", timestamp: Date().addingTimeInterval(-1800)),
            Post(text: "Beautiful sunset today. Sometimes the simple moments are the best.", author: "Bob Smith", timestamp: Date().addingTimeInterval(-3600)),
            Post(text: "Working on a new project. Can't wait to share more details soon!", author: "Carol Davis", timestamp: Date().addingTimeInterval(-5400)),
            Post(text: "Coffee and code - the perfect combination for a productive morning.", author: "David Wilson", timestamp: Date().addingTimeInterval(-7200))
        ]
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
    
    public init(text: String, author: String, authorDisplayHandle: String? = nil, timestamp: Date = Date(), likeCount: Int = 0, repostCount: Int = 0, replyCount: Int = 0) {
        self.id = UUID().uuidString
        self.text = text
        self.author = author
        self.authorDisplayHandle = authorDisplayHandle ?? author
        self.timestamp = timestamp
        self.likeCount = likeCount
        self.repostCount = repostCount
        self.replyCount = replyCount
    }
}