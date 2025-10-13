//
//  ThreadViewModel.swift
//  Agora
//
//  Created by Agora Team on 2024.
//

import Foundation
import SwiftUI
import Networking

@MainActor
@Observable
public class ThreadViewModel {
    public var threadPosts: [ThreadPost] = []
    public var isLoading = false
    public var error: Error?
    
    private let threadId: String
    private let networking: APIClient
    
    public init(threadId: String, networking: APIClient = APIClient.shared) {
        self.threadId = threadId
        self.networking = networking
    }
    
    public func loadThread() async {
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
        await loadThread()
    }
    
    private func loadPlaceholderData() {
        threadPosts = [
            ThreadPost(
                text: "This is the original post that started the thread.",
                author: "Thread Starter",
                timestamp: Date().addingTimeInterval(-7200),
                likeCount: 15,
                repostCount: 3
            ),
            ThreadPost(
                text: "This is a reply to the original post, continuing the conversation.",
                author: "Thread Starter",
                timestamp: Date().addingTimeInterval(-5400),
                likeCount: 8,
                repostCount: 1
            ),
            ThreadPost(
                text: "And this is the final post in the thread, wrapping up the thought.",
                author: "Thread Starter",
                timestamp: Date().addingTimeInterval(-3600),
                likeCount: 12,
                repostCount: 2
            )
        ]
    }
}

public struct ThreadPost: Identifiable, Codable {
    public let id: String
    public let text: String
    public let author: String
    public let authorDisplayHandle: String
    public let timestamp: Date
    public let likeCount: Int
    public let repostCount: Int
    
    public init(text: String, author: String, authorDisplayHandle: String? = nil, timestamp: Date = Date(), likeCount: Int = 0, repostCount: Int = 0) {
        self.id = UUID().uuidString
        self.text = text
        self.author = author
        self.authorDisplayHandle = authorDisplayHandle ?? author
        self.timestamp = timestamp
        self.likeCount = likeCount
        self.repostCount = repostCount
    }
}