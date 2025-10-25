import XCTest
@testable import Messaging
import AppFoundation

final class OptimisticUpdateTests: XCTestCase {
    
    var messagingService: MessagingServiceLive!
    var mockSupabase: MockSupabaseClient!
    
    override func setUp() {
        super.setUp()
        mockSupabase = MockSupabaseClient()
        messagingService = MessagingServiceLive(supabase: mockSupabase)
    }
    
    override func tearDown() {
        messagingService = nil
        mockSupabase = nil
        super.tearDown()
    }
    
    // MARK: - Optimistic Message Creation Tests
    
    func testCreateOptimisticMessage() {
        // Given
        let conversationId = UUID()
        let text = "Optimistic message"
        let nonce = MessageNonce()
        
        // When
        let optimisticMessage = messagingService.createOptimisticMessage(
            conversationId: conversationId,
            text: text,
            nonce: nonce
        )
        
        // Then
        XCTAssertEqual(optimisticMessage.conversationId, conversationId)
        XCTAssertEqual(optimisticMessage.content, text)
        XCTAssertEqual(optimisticMessage.nonce, nonce)
        XCTAssertEqual(optimisticMessage.deliveryStatus, .sending)
        XCTAssertNotNil(optimisticMessage.id)
        XCTAssertTrue(optimisticMessage.attachments.isEmpty)
    }
    
    func testCreateOptimisticMessageWithAttachments() {
        // Given
        let conversationId = UUID()
        let text = "Message with attachment"
        let nonce = MessageNonce()
        let attachment = createMockAttachment()
        
        // When
        let optimisticMessage = messagingService.createOptimisticMessage(
            conversationId: conversationId,
            text: text,
            nonce: nonce,
            attachments: [attachment]
        )
        
        // Then
        XCTAssertEqual(optimisticMessage.conversationId, conversationId)
        XCTAssertEqual(optimisticMessage.content, text)
        XCTAssertEqual(optimisticMessage.nonce, nonce)
        XCTAssertEqual(optimisticMessage.deliveryStatus, .sending)
        XCTAssertEqual(optimisticMessage.attachments.count, 1)
        XCTAssertEqual(optimisticMessage.attachments.first?.id, attachment.id)
    }
    
    // MARK: - Message Reconciliation Tests
    
    func testReconcileOptimisticMessage() {
        // Given
        let conversationId = UUID()
        let nonce = MessageNonce()
        let optimisticMessage = messagingService.createOptimisticMessage(
            conversationId: conversationId,
            text: "Test message",
            nonce: nonce
        )
        
        let serverMessage = Message(
            id: UUID(),
            conversationId: conversationId,
            senderId: UUID(),
            content: "Test message",
            attachments: [],
            timestamp: Date(),
            deliveryStatus: .sent,
            replyTo: nil,
            nonce: nonce,
            editedAt: nil,
            deletedAt: nil,
            expiresAt: nil,
            systemKind: nil,
            linkPreview: nil
        )
        
        // When
        let reconciledMessage = messagingService.reconcileOptimisticMessage(
            optimistic: optimisticMessage,
            server: serverMessage
        )
        
        // Then
        XCTAssertEqual(reconciledMessage.id, serverMessage.id)
        XCTAssertEqual(reconciledMessage.content, serverMessage.content)
        XCTAssertEqual(reconciledMessage.deliveryStatus, .sent)
        XCTAssertEqual(reconciledMessage.nonce, nonce)
        XCTAssertEqual(reconciledMessage.timestamp, serverMessage.timestamp)
    }
    
    func testReconcileOptimisticMessageWithConflict() {
        // Given
        let conversationId = UUID()
        let nonce = MessageNonce()
        let optimisticMessage = messagingService.createOptimisticMessage(
            conversationId: conversationId,
            text: "Original text",
            nonce: nonce
        )
        
        let serverMessage = Message(
            id: UUID(),
            conversationId: conversationId,
            senderId: UUID(),
            content: "Modified text", // Server modified the content
            attachments: [],
            timestamp: Date(),
            deliveryStatus: .sent,
            replyTo: nil,
            nonce: nonce,
            editedAt: Date(),
            deletedAt: nil,
            expiresAt: nil,
            systemKind: nil,
            linkPreview: nil
        )
        
        // When
        let reconciledMessage = messagingService.reconcileOptimisticMessage(
            optimistic: optimisticMessage,
            server: serverMessage
        )
        
        // Then - Server version should take precedence
        XCTAssertEqual(reconciledMessage.id, serverMessage.id)
        XCTAssertEqual(reconciledMessage.content, "Modified text")
        XCTAssertEqual(reconciledMessage.deliveryStatus, .sent)
        XCTAssertNotNil(reconciledMessage.editedAt)
    }
    
    // MARK: - Nonce-based Deduplication Tests
    
    func testFindOptimisticMessageByNonce() {
        // Given
        let conversationId = UUID()
        let nonce1 = MessageNonce()
        let nonce2 = MessageNonce()
        
        let message1 = messagingService.createOptimisticMessage(
            conversationId: conversationId,
            text: "Message 1",
            nonce: nonce1
        )
        
        let message2 = messagingService.createOptimisticMessage(
            conversationId: conversationId,
            text: "Message 2",
            nonce: nonce2
        )
        
        let messages = [message1, message2]
        
        // When
        let foundMessage = messagingService.findOptimisticMessage(
            in: messages,
            with: nonce1,
            conversationId: conversationId
        )
        
        // Then
        XCTAssertNotNil(foundMessage)
        XCTAssertEqual(foundMessage?.id, message1.id)
        XCTAssertEqual(foundMessage?.nonce, nonce1)
    }
    
    func testFindOptimisticMessageByNonceNotFound() {
        // Given
        let conversationId = UUID()
        let nonce1 = MessageNonce()
        let nonce2 = MessageNonce()
        
        let message = messagingService.createOptimisticMessage(
            conversationId: conversationId,
            text: "Message",
            nonce: nonce1
        )
        
        let messages = [message]
        
        // When
        let foundMessage = messagingService.findOptimisticMessage(
            in: messages,
            with: nonce2, // Different nonce
            conversationId: conversationId
        )
        
        // Then
        XCTAssertNil(foundMessage)
    }
    
    func testDeduplicateMessages() {
        // Given
        let conversationId = UUID()
        let nonce = MessageNonce()
        
        let optimisticMessage = messagingService.createOptimisticMessage(
            conversationId: conversationId,
            text: "Test message",
            nonce: nonce
        )
        
        let serverMessage = Message(
            id: UUID(),
            conversationId: conversationId,
            senderId: UUID(),
            content: "Test message",
            attachments: [],
            timestamp: Date(),
            deliveryStatus: .sent,
            replyTo: nil,
            nonce: nonce,
            editedAt: nil,
            deletedAt: nil,
            expiresAt: nil,
            systemKind: nil,
            linkPreview: nil
        )
        
        let messages = [optimisticMessage, serverMessage]
        
        // When
        let deduplicatedMessages = messagingService.deduplicateMessages(messages)
        
        // Then
        XCTAssertEqual(deduplicatedMessages.count, 1)
        XCTAssertEqual(deduplicatedMessages.first?.id, serverMessage.id)
        XCTAssertEqual(deduplicatedMessages.first?.deliveryStatus, .sent)
    }
    
    // MARK: - Delivery Status Progression Tests
    
    func testDeliveryStatusProgression() {
        // Given
        let message = createMockMessage(deliveryStatus: .sending)
        
        // When & Then - Test valid progressions
        XCTAssertTrue(messagingService.canProgressDeliveryStatus(from: .sending, to: .sent))
        XCTAssertTrue(messagingService.canProgressDeliveryStatus(from: .sent, to: .delivered))
        XCTAssertTrue(messagingService.canProgressDeliveryStatus(from: .delivered, to: .read))
        XCTAssertTrue(messagingService.canProgressDeliveryStatus(from: .sending, to: .failed))
        
        // Test invalid progressions
        XCTAssertFalse(messagingService.canProgressDeliveryStatus(from: .sent, to: .sending))
        XCTAssertFalse(messagingService.canProgressDeliveryStatus(from: .delivered, to: .sent))
        XCTAssertFalse(messagingService.canProgressDeliveryStatus(from: .read, to: .delivered))
        XCTAssertFalse(messagingService.canProgressDeliveryStatus(from: .failed, to: .sent))
    }
    
    func testUpdateDeliveryStatus() {
        // Given
        let message = createMockMessage(deliveryStatus: .sending)
        
        // When
        let updatedMessage = messagingService.updateDeliveryStatus(
            message: message,
            newStatus: .sent
        )
        
        // Then
        XCTAssertEqual(updatedMessage.deliveryStatus, .sent)
        XCTAssertEqual(updatedMessage.id, message.id)
        XCTAssertEqual(updatedMessage.content, message.content)
    }
    
    func testUpdateDeliveryStatusInvalidProgression() {
        // Given
        let message = createMockMessage(deliveryStatus: .delivered)
        
        // When
        let updatedMessage = messagingService.updateDeliveryStatus(
            message: message,
            newStatus: .sending // Invalid progression
        )
        
        // Then - Should keep original status
        XCTAssertEqual(updatedMessage.deliveryStatus, .delivered)
    }
    
    // MARK: - Conflict Resolution Tests
    
    func testResolveMessageConflict() {
        // Given
        let messageId = UUID()
        let conversationId = UUID()
        
        let localMessage = Message(
            id: messageId,
            conversationId: conversationId,
            senderId: UUID(),
            content: "Local version",
            attachments: [],
            timestamp: Date().addingTimeInterval(-10), // Older timestamp
            deliveryStatus: .sent,
            replyTo: nil,
            nonce: nil,
            editedAt: nil,
            deletedAt: nil,
            expiresAt: nil,
            systemKind: nil,
            linkPreview: nil
        )
        
        let serverMessage = Message(
            id: messageId,
            conversationId: conversationId,
            senderId: UUID(),
            content: "Server version",
            attachments: [],
            timestamp: Date(), // Newer timestamp
            deliveryStatus: .delivered,
            replyTo: nil,
            nonce: nil,
            editedAt: Date(),
            deletedAt: nil,
            expiresAt: nil,
            systemKind: nil,
            linkPreview: nil
        )
        
        // When
        let resolvedMessage = messagingService.resolveMessageConflict(
            local: localMessage,
            server: serverMessage
        )
        
        // Then - Server version should win
        XCTAssertEqual(resolvedMessage.content, "Server version")
        XCTAssertEqual(resolvedMessage.deliveryStatus, .delivered)
        XCTAssertNotNil(resolvedMessage.editedAt)
    }
    
    func testResolveMessageConflictLocalNewer() {
        // Given
        let messageId = UUID()
        let conversationId = UUID()
        
        let localMessage = Message(
            id: messageId,
            conversationId: conversationId,
            senderId: UUID(),
            content: "Local version",
            attachments: [],
            timestamp: Date(), // Newer timestamp
            deliveryStatus: .sent,
            replyTo: nil,
            nonce: nil,
            editedAt: Date(),
            deletedAt: nil,
            expiresAt: nil,
            systemKind: nil,
            linkPreview: nil
        )
        
        let serverMessage = Message(
            id: messageId,
            conversationId: conversationId,
            senderId: UUID(),
            content: "Server version",
            attachments: [],
            timestamp: Date().addingTimeInterval(-10), // Older timestamp
            deliveryStatus: .delivered,
            replyTo: nil,
            nonce: nil,
            editedAt: nil,
            deletedAt: nil,
            expiresAt: nil,
            systemKind: nil,
            linkPreview: nil
        )
        
        // When
        let resolvedMessage = messagingService.resolveMessageConflict(
            local: localMessage,
            server: serverMessage
        )
        
        // Then - Local version should win (newer edit)
        XCTAssertEqual(resolvedMessage.content, "Local version")
        XCTAssertEqual(resolvedMessage.deliveryStatus, .delivered) // But keep server delivery status
        XCTAssertNotNil(resolvedMessage.editedAt)
    }
    
    // MARK: - Helper Methods
    
    private func createMockMessage(
        deliveryStatus: DeliveryStatus = .sent,
        nonce: MessageNonce? = nil
    ) -> Message {
        Message(
            id: UUID(),
            conversationId: UUID(),
            senderId: UUID(),
            content: "Test message",
            attachments: [],
            timestamp: Date(),
            deliveryStatus: deliveryStatus,
            replyTo: nil,
            nonce: nonce,
            editedAt: nil,
            deletedAt: nil,
            expiresAt: nil,
            systemKind: nil,
            linkPreview: nil
        )
    }
    
    private func createMockAttachment() -> Attachment {
        Attachment(
            id: UUID(),
            type: .image,
            url: URL(string: "https://example.com/image.jpg")!,
            thumbnailUrl: URL(string: "https://example.com/thumb.jpg"),
            sizeBytes: 1024,
            duration: nil,
            metadata: AttachmentMetadata(
                filename: "image.jpg",
                mimeType: "image/jpeg",
                width: 800,
                height: 600
            )
        )
    }
}

// MARK: - MessagingServiceLive Extensions for Testing

extension MessagingServiceLive {
    func createOptimisticMessage(
        conversationId: UUID,
        text: String,
        nonce: MessageNonce,
        attachments: [Attachment] = []
    ) -> Message {
        Message(
            id: UUID(), // Temporary client ID
            conversationId: conversationId,
            senderId: UUID(), // Current user ID
            content: text,
            attachments: attachments,
            timestamp: Date(),
            deliveryStatus: .sending,
            replyTo: nil,
            nonce: nonce,
            editedAt: nil,
            deletedAt: nil,
            expiresAt: nil,
            systemKind: nil,
            linkPreview: nil
        )
    }
    
    func reconcileOptimisticMessage(
        optimistic: Message,
        server: Message
    ) -> Message {
        // Server message takes precedence, but preserve client nonce
        Message(
            id: server.id,
            conversationId: server.conversationId,
            senderId: server.senderId,
            content: server.content,
            attachments: server.attachments,
            timestamp: server.timestamp,
            deliveryStatus: server.deliveryStatus,
            replyTo: server.replyTo,
            nonce: optimistic.nonce,
            editedAt: server.editedAt,
            deletedAt: server.deletedAt,
            expiresAt: server.expiresAt,
            systemKind: server.systemKind,
            linkPreview: server.linkPreview
        )
    }
    
    func findOptimisticMessage(
        in messages: [Message],
        with nonce: MessageNonce,
        conversationId: UUID
    ) -> Message? {
        return messages.first { message in
            message.nonce == nonce && message.conversationId == conversationId
        }
    }
    
    func deduplicateMessages(_ messages: [Message]) -> [Message] {
        var deduplicatedMessages: [Message] = []
        var seenNonces: Set<MessageNonce> = []
        
        for message in messages {
            if let nonce = message.nonce {
                if seenNonces.contains(nonce) {
                    // Skip optimistic version if server version exists
                    if message.deliveryStatus != .sending {
                        // Replace optimistic with server version
                        deduplicatedMessages.removeAll { $0.nonce == nonce }
                        deduplicatedMessages.append(message)
                    }
                } else {
                    seenNonces.insert(nonce)
                    deduplicatedMessages.append(message)
                }
            } else {
                deduplicatedMessages.append(message)
            }
        }
        
        return deduplicatedMessages
    }
    
    func canProgressDeliveryStatus(from current: DeliveryStatus, to new: DeliveryStatus) -> Bool {
        switch (current, new) {
        case (.sending, .sent), (.sending, .failed):
            return true
        case (.sent, .delivered):
            return true
        case (.delivered, .read):
            return true
        default:
            return false
        }
    }
    
    func updateDeliveryStatus(message: Message, newStatus: DeliveryStatus) -> Message {
        guard canProgressDeliveryStatus(from: message.deliveryStatus, to: newStatus) else {
            return message
        }
        
        return Message(
            id: message.id,
            conversationId: message.conversationId,
            senderId: message.senderId,
            content: message.content,
            attachments: message.attachments,
            timestamp: message.timestamp,
            deliveryStatus: newStatus,
            replyTo: message.replyTo,
            nonce: message.nonce,
            editedAt: message.editedAt,
            deletedAt: message.deletedAt,
            expiresAt: message.expiresAt,
            systemKind: message.systemKind,
            linkPreview: message.linkPreview
        )
    }
    
    func resolveMessageConflict(local: Message, server: Message) -> Message {
        // Server version wins for most fields, but check edit timestamps
        let useLocalContent = local.editedAt ?? local.timestamp > server.editedAt ?? server.timestamp
        
        return Message(
            id: server.id,
            conversationId: server.conversationId,
            senderId: server.senderId,
            content: useLocalContent ? local.content : server.content,
            attachments: server.attachments,
            timestamp: server.timestamp,
            deliveryStatus: server.deliveryStatus, // Always use server delivery status
            replyTo: server.replyTo,
            nonce: server.nonce,
            editedAt: useLocalContent ? local.editedAt : server.editedAt,
            deletedAt: server.deletedAt,
            expiresAt: server.expiresAt,
            systemKind: server.systemKind,
            linkPreview: server.linkPreview
        )
    }
}