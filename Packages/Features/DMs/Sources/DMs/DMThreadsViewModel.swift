//
//  DMThreadsViewModel.swift
//  Agora
//
//  Created by Agora Team on 2024.
//

import Foundation
import SwiftUI
import Networking

@MainActor
@Observable
public class DMThreadsViewModel {
    public var threads: [DMThread] = []
    public var isLoading = false
    public var error: Error?
    
    private let networking: APIClient
    
    public init(networking: APIClient = APIClient.shared) {
        self.networking = networking
    }
    
    public func loadThreads() async {
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
        await loadThreads()
    }
    
    private func loadPlaceholderData() {
        threads = [
            DMThread(
                otherUser: DMUser(
                    id: "user1",
                    handle: "alice",
                    displayName: "Alice Johnson"
                ),
                lastMessage: DMMessage(
                    text: "Hey! How's the new project going?",
                    timestamp: Date().addingTimeInterval(-1800),
                    isFromCurrentUser: false
                ),
                hasUnreadMessages: true
            ),
            DMThread(
                otherUser: DMUser(
                    id: "user2",
                    handle: "bob",
                    displayName: "Bob Smith"
                ),
                lastMessage: DMMessage(
                    text: "Thanks for the feedback on the design!",
                    timestamp: Date().addingTimeInterval(-7200),
                    isFromCurrentUser: true
                ),
                hasUnreadMessages: false
            ),
            DMThread(
                otherUser: DMUser(
                    id: "user3",
                    handle: "carol",
                    displayName: "Carol Davis"
                ),
                lastMessage: DMMessage(
                    text: "Looking forward to our collaboration!",
                    timestamp: Date().addingTimeInterval(-86400),
                    isFromCurrentUser: false
                ),
                hasUnreadMessages: false
            )
        ]
    }
}

public struct DMThread: Identifiable, Codable {
    public let id: String
    public let otherUser: DMUser
    public let lastMessage: DMMessage
    public let hasUnreadMessages: Bool
    
    public init(otherUser: DMUser, lastMessage: DMMessage, hasUnreadMessages: Bool) {
        self.id = UUID().uuidString
        self.otherUser = otherUser
        self.lastMessage = lastMessage
        self.hasUnreadMessages = hasUnreadMessages
    }
}

public struct DMUser: Identifiable, Codable {
    public let id: String
    public let handle: String
    public let displayName: String
    
    public init(id: String, handle: String, displayName: String) {
        self.id = id
        self.handle = handle
        self.displayName = displayName
    }
}

public struct DMMessage: Identifiable, Codable {
    public let id: String
    public let text: String
    public let timestamp: Date
    public let isFromCurrentUser: Bool
    
    public init(text: String, timestamp: Date = Date(), isFromCurrentUser: Bool) {
        self.id = UUID().uuidString
        self.text = text
        self.timestamp = timestamp
        self.isFromCurrentUser = isFromCurrentUser
    }
}