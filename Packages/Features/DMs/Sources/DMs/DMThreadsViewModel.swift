//
//  DMThreadsViewModel.swift
//  Agora
//
//  Created by Agora Team on 2024.
//

import Foundation
import SwiftUI
import AppFoundation
import Networking

@MainActor
@Observable
public class DMThreadsViewModel {
    public var threads: [DMThread] = []
    public var isLoading = false
    public var error: Error?
    
    private let messaging: MessagingServiceProtocol?
    private let sessionStore: SessionStore
    
    /// Initialize DMThreadsViewModel with explicit dependencies
    /// Following the DI rule pattern
    public init(messaging: MessagingServiceProtocol?, sessionStore: SessionStore = SessionStore()) {
        self.messaging = messaging
        self.sessionStore = sessionStore
    }
    
    public func loadThreads() async {
        guard let messaging = messaging else {
            print("⚠️ MessagingService not available, using placeholder data")
            loadPlaceholderData()
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Fetch conversations from the messaging service
            let conversations = try await messaging.fetchConversations(page: 0, pageSize: 50)
            
            // Get current user to determine which participant is "other"
            let currentUser = try? await sessionStore.getCurrentUser()
            
            // Convert domain Conversation models to UI DMThread models
            threads = conversations.compactMap { conversation in
                convertToDMThread(conversation, currentUserId: currentUser?.id)
            }
        } catch {
            self.error = error
            print("❌ Failed to load conversations: \(error)")
        }
    }
    
    public func refresh() async {
        await loadThreads()
    }
    
    // MARK: - Model Conversion
    
    private func convertToDMThread(_ conversation: Conversation, currentUserId: String?) -> DMThread? {
        // Find the "other" participant (not the current user)
        guard let otherParticipant = conversation.participants.first(where: { $0.id != currentUserId }) else {
            return nil
        }
        
        // Convert to DMUser
        let otherUser = DMUser(
            id: otherParticipant.id,
            handle: otherParticipant.handle,
            displayName: otherParticipant.displayName
        )
        
        // Convert last message if available
        let lastMessage: DMMessage
        if let message = conversation.lastMessage {
            let isFromCurrentUser = message.senderId.uuidString == currentUserId
            lastMessage = DMMessage(
                text: message.content,
                timestamp: message.timestamp,
                isFromCurrentUser: isFromCurrentUser
            )
        } else {
            // No messages yet, create placeholder
            lastMessage = DMMessage(
                text: "No messages yet",
                timestamp: conversation.lastActivity,
                isFromCurrentUser: false
            )
        }
        
        return DMThread(
            otherUser: otherUser,
            lastMessage: lastMessage,
            hasUnreadMessages: conversation.unreadCount > 0
        )
    }
    
    // MARK: - Placeholder Data (Fallback)
    
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