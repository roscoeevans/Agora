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
    private let networking: any AgoraAPIClient
    
    /// Initialize PostDetailViewModel with explicit dependencies
    /// Following the DI rule pattern
    public init(postId: String, networking: any AgoraAPIClient) {
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
        // Using AppFoundation.Post (re-exported via Networking)
        post = Post(
            id: UUID().uuidString,
            authorId: "sample-author-id",
            authorDisplayHandle: "sample.author",
            text: "This is a detailed view of a post. You can see the full content and all replies here.",
            createdAt: Date().addingTimeInterval(-3600),
            authorDisplayName: "Sample Author"
        )
        
        replies = [
            Reply(text: "Great post! Thanks for sharing.", author: "Reply User 1", timestamp: Date().addingTimeInterval(-1800)),
            Reply(text: "I completely agree with this perspective.", author: "Reply User 2", timestamp: Date().addingTimeInterval(-900)),
            Reply(text: "This is really insightful.", author: "Reply User 3", timestamp: Date().addingTimeInterval(-300))
        ]
    }
}

// Note: Post is imported from Networking (which re-exports AppFoundation)
// No need to define it here - use the canonical AppFoundation.Post

public struct Reply: Identifiable, Codable, Sendable {
    public let id: String
    public let text: String
    public let author: String
    public let authorDisplayHandle: String
    public let timestamp: Date
    
    public init(text: String, author: String, authorDisplayHandle: String? = nil, timestamp: Date = Date()) {
        self.id = UUID().uuidString
        self.text = text
        self.author = author
        self.authorDisplayHandle = authorDisplayHandle ?? author
        self.timestamp = timestamp
    }
}