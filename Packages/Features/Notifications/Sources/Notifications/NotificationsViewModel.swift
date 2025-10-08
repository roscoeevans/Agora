//
//  NotificationsViewModel.swift
//  Agora
//
//  Created by Agora Team on 2024.
//

import Foundation
import SwiftUI
import Networking

@MainActor
@Observable
public class NotificationsViewModel {
    public var notifications: [NotificationItem] = []
    public var isLoading = false
    public var error: Error?
    
    private let networking: APIClient
    
    public init(networking: APIClient = APIClient.shared) {
        self.networking = networking
    }
    
    public func loadNotifications() async {
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
        await loadNotifications()
    }
    
    public func markAsRead(_ notification: NotificationItem) {
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
            notifications[index] = NotificationItem(
                type: notification.type,
                title: notification.title,
                message: notification.message,
                actionText: notification.actionText,
                timestamp: notification.timestamp,
                isRead: true
            )
        }
    }
    
    private func loadPlaceholderData() {
        notifications = [
            NotificationItem(
                type: .like,
                title: "Alice Johnson",
                message: "liked your post",
                actionText: "\"Just shipped a new feature! Really excited about the user feedback so far.\"",
                timestamp: Date().addingTimeInterval(-1800),
                isRead: false
            ),
            NotificationItem(
                type: .repost,
                title: "Bob Smith",
                message: "reposted your post",
                actionText: "\"Working on something exciting. Can't wait to share more details soon!\"",
                timestamp: Date().addingTimeInterval(-3600),
                isRead: false
            ),
            NotificationItem(
                type: .reply,
                title: "Carol Davis",
                message: "replied to your post",
                actionText: "\"Great insights! I'd love to hear more about your process.\"",
                timestamp: Date().addingTimeInterval(-7200),
                isRead: true
            ),
            NotificationItem(
                type: .follow,
                title: "David Wilson",
                message: "started following you",
                timestamp: Date().addingTimeInterval(-10800),
                isRead: true
            ),
            NotificationItem(
                type: .mention,
                title: "Emma Brown",
                message: "mentioned you in a post",
                actionText: "\"Thanks @myhandle for the inspiration!\"",
                timestamp: Date().addingTimeInterval(-14400),
                isRead: true
            )
        ]
    }
}

public struct NotificationItem: Identifiable, Codable {
    public let id: String
    public let type: NotificationType
    public let title: String
    public let message: String
    public let actionText: String?
    public let timestamp: Date
    public let isRead: Bool
    
    public init(
        type: NotificationType,
        title: String,
        message: String,
        actionText: String? = nil,
        timestamp: Date = Date(),
        isRead: Bool = false
    ) {
        self.id = UUID().uuidString
        self.type = type
        self.title = title
        self.message = message
        self.actionText = actionText
        self.timestamp = timestamp
        self.isRead = isRead
    }
}

public enum NotificationType: String, Codable, CaseIterable {
    case like
    case repost
    case reply
    case follow
    case mention
}