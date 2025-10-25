import Foundation
import AppFoundation
import Analytics
import UserNotifications

/// Handles DM-specific push notifications
public final class DMNotificationHandler: Sendable {
    private let eventTracker: EventTracker?
    
    public init(eventTracker: EventTracker? = nil) {
        self.eventTracker = eventTracker
    }
    
    /// Handles a DM notification payload
    /// - Parameter payload: The notification payload
    /// - Returns: The conversation ID if this is a DM notification, nil otherwise
    public func handleNotification(_ payload: [AnyHashable: Any]) async -> UUID? {
        guard let type = payload["type"] as? String,
              type == "dm_message" else {
            return nil
        }
        
        guard let conversationIdString = payload["conversation_id"] as? String,
              let conversationId = UUID(uuidString: conversationIdString) else {
            return nil
        }
        
        // Track notification received
        await eventTracker?.track(.dmReceive)
        
        return conversationId
    }
    
    /// Sets up notification categories for DM notifications
    public func setupNotificationCategories() async {
        let replyAction = UNTextInputNotificationAction(
            identifier: "dm_reply",
            title: "Reply",
            options: [.foreground],
            textInputButtonTitle: "Send",
            textInputPlaceholder: "Type a message..."
        )
        
        let markReadAction = UNNotificationAction(
            identifier: "dm_mark_read",
            title: "Mark as Read",
            options: []
        )
        
        let dmCategory = UNNotificationCategory(
            identifier: "dm_message",
            actions: [replyAction, markReadAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        let center = UNUserNotificationCenter.current()
        center.setNotificationCategories([dmCategory])
    }
    
    /// Handles notification action responses
    /// - Parameters:
    ///   - response: The notification response
    ///   - messagingService: The messaging service to send replies
    public func handleNotificationResponse(
        _ response: UNNotificationResponse,
        messagingService: MessagingServiceProtocol?
    ) async {
        let payload = response.notification.request.content.userInfo
        
        guard let conversationIdString = payload["conversation_id"] as? String,
              let conversationId = UUID(uuidString: conversationIdString) else {
            return
        }
        
        switch response.actionIdentifier {
        case "dm_reply":
            if let textResponse = response as? UNTextInputNotificationResponse {
                let text = textResponse.userText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty else { return }
                
                do {
                    _ = try await messagingService?.send(text: text, in: conversationId)
                    await eventTracker?.track(.dmSend(hasMedia: false, characterCount: text.count))
                } catch {
                    // Handle error - could show local notification or log
                    print("Failed to send reply from notification: \(error)")
                }
            }
            
        case "dm_mark_read":
            // Mark conversation as read
            // This would require additional API support
            break
            
        default:
            break
        }
    }
}

/// Extension to create deep link URLs for DM notifications
extension DMNotificationHandler {
    /// Creates a deep link URL for a conversation
    /// - Parameter conversationId: The conversation ID
    /// - Returns: Deep link URL for the conversation
    public static func createDeepLink(for conversationId: UUID) -> URL? {
        return URL(string: "agora://messages/conversation/\(conversationId.uuidString)")
    }
}