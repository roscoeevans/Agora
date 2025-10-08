//
//  PostDetailViewModel.swift
//  Agora
//
//  Created by Agora Team on 2024.
//

import Foundation
import SwiftUI
import Networking

@MainActor
@Observable
public class PostDetailViewModel {
    public var post: Post?
    public var replies: [Reply] = []
    public var isLoading = false
    public var error: Error?
    
    private let postId: String
    private let networking: APIClient
    
    public init(postId: String, networking: APIClient = APIClient.shared) {
        self.postId = postId
        self.networking = networking
    }
    
    public func loadPost() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // TODO: Implement actual API call
            // For now, simulate network delay and load placeholder data
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            loadPlaceholderData()
        } catch {
            self.error = error
        }
    }
    
    public func refresh() async {
        await loadPost()
    }
    
    private func loadPlaceholderData() {
        post = Post(
            text: "This is a detailed view of a post. You can see the full content and all replies here.",
            author: "Sample Author",
            timestamp: Date().addingTimeInterval(-3600),
            likeCount: 42,
            repostCount: 7,
            replyCount: 3
        )
        
        replies = [
            Reply(text: "Great post! Thanks for sharing.", author: "Reply User 1", timestamp: Date().addingTimeInterval(-1800)),
            Reply(text: "I completely agree with this perspective.", author: "Reply User 2", timestamp: Date().addingTimeInterval(-900)),
            Reply(text: "This is really insightful.", author: "Reply User 3", timestamp: Date().addingTimeInterval(-300))
        ]
    }
}

public struct Post: Identifiable, Codable, Sendable {
    public let id: String
    public let text: String
    public let author: String
    public let timestamp: Date
    public let likeCount: Int
    public let repostCount: Int
    public let replyCount: Int
    
    public init(text: String, author: String, timestamp: Date = Date(), likeCount: Int = 0, repostCount: Int = 0, replyCount: Int = 0) {
        self.id = UUID().uuidString
        self.text = text
        self.author = author
        self.timestamp = timestamp
        self.likeCount = likeCount
        self.repostCount = repostCount
        self.replyCount = replyCount
    }
}

public struct Reply: Identifiable, Codable, Sendable {
    public let id: String
    public let text: String
    public let author: String
    public let timestamp: Date
    
    public init(text: String, author: String, timestamp: Date = Date()) {
        self.id = UUID().uuidString
        self.text = text
        self.author = author
        self.timestamp = timestamp
    }
}