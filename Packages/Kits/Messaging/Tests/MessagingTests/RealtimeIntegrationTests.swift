import XCTest
@testable import Messaging
import AppFoundation

final class RealtimeIntegrationTests: XCTestCase {
    
    var messagingService: MessagingServiceLive!
    var realtimeService: MessagingRealtimeLive!
    var observer: MessagingRealtimeObserver!
    var mockSupabase: MockSupabaseClient!
    
    override func setUp() async throws {
        try await super.setUp()
        
        mockSupabase = MockSupabaseClient()
        messagingService = MessagingServiceLive(supabase: mockSupabase)
        
        let (outputStream, outputContinuation) = AsyncStream<MessagingRealtimeObserver.Output>.makeStream()
        observer = MessagingRealtimeObserver(
            config: MessagingRealtimeObserver.Config(),
            supabase: mockSupabase,
            outputContinuation: outputContinuation
        )
        
        realtimeService = MessagingRealtimeLive(observer: observer)
    }
    
    override func tearDown() async throws {
        observer = nil
        realtimeService = nil
        messagingService = nil
        mockSupabase = nil
        try await super.tearDown()
    }
    
    // MARK: - End-to-End Message Flow Tests
    
    func testEndToEndMessageSending() async throws {
        // Given
        let conversationId = UUID()
        let messageText = "Hello, integration test!"
        
        // Set up real-time subscription
        let subscription = try await realtimeService.subscribe(conversationId: conversationId)
        defer { Task { await subscription.cancel() } }
        
        // When
        let sentMessage = try await messagingService.send(text: messageText, in: conversationId)
        
        // Simulate real-time message arrival
        await simulateRealtimeMessageArrival(sentMessage)
        
        // Then
        XCTAssertEqual(sentMessage.content, messageText)
        XCTAssertEqual(sentMessage.conversationId, conversationId)
        XCTAssertEqual(sentMessage.deliveryStatus, .sent)
        
        // Verify real-time event was processed
        let events = await collectRealtimeEvents(count: 1, timeout: 1.0)
        XCTAssertEqual(events.count, 1)
        
        if case .messageAdded(let receivedMessage) = events.first {
            XCTAssertEqual(receivedMessage.id, sentMessage.id)
            XCTAssertEqual(receivedMessage.content, messageText)
        } else {
            XCTFail("Expected messageAdded event")
        }
    }
    
    func testEndToEndMessageReceiving() async throws {
        // Given
        let conversationId = UUID()
        let incomingMessage = createMockMessage(conversationId: conversationId, content: "Incoming message")
        
        // Set up real-time subscription
        let subscription = try await realtimeService.subscribe(conversationId: conversationId)
        defer { Task { await subscription.cancel() } }
        
        // When - Simulate incoming message from another user
        await simulateRealtimeMessageArrival(incomingMessage)
        
        // Then
        let events = await collectRealtimeEvents(count: 1, timeout: 1.0)
        XCTAssertEqual(events.count, 1)
        
        if case .messageAdded(let receivedMessage) = events.first {
            XCTAssertEqual(receivedMessage.id, incomingMessage.id)
            XCTAssertEqual(receivedMessage.content, "Incoming message")
        } else {
            XCTFail("Expected messageAdded event")
        }
    }
    
    func testEndToEndMessageWithAttachment() async throws {
        // Given
        let conversationId = UUID()
        let attachment = createMockAttachment()
        
        // Set up real-time subscription
        let subscription = try await realtimeService.subscribe(conversationId: conversationId)
        defer { Task { await subscription.cancel() } }
        
        // When
        let sentMessage = try await messagingService.send(attachment: attachment, in: conversationId)
        
        // Simulate real-time message arrival
        await simulateRealtimeMessageArrival(sentMessage)
        
        // Then
        XCTAssertEqual(sentMessage.attachments.count, 1)
        XCTAssertEqual(sentMessage.attachments.first?.id, attachment.id)
        
        // Verify real-time event was processed
        let events = await collectRealtimeEvents(count: 1, timeout: 1.0)
        XCTAssertEqual(events.count, 1)
        
        if case .messageAdded(let receivedMessage) = events.first {
            XCTAssertEqual(receivedMessage.attachments.count, 1)
            XCTAssertEqual(receivedMessage.attachments.first?.id, attachment.id)
        } else {
            XCTFail("Expected messageAdded event")
        }
    }
    
    // MARK: - Typing Indicator Integration Tests
    
    func testTypingIndicatorFlow() async throws {
        // Given
        let conversationId = UUID()
        let userId = UUID()
        
        // Set up real-time subscription
        let subscription = try await realtimeService.subscribe(conversationId: conversationId)
        defer { Task { await subscription.cancel() } }
        
        // When - Start typing
        await realtimeService.setTyping(conversationId: conversationId, isTyping: true)
        
        // Simulate typing event from another user
        await simulateTypingEvent(conversationId: conversationId, userId: userId, isTyping: true)
        
        // Then
        let events = await collectRealtimeEvents(count: 1, timeout: 1.0)
        XCTAssertEqual(events.count, 1)
        
        if case .typing(let receivedConversationId, let receivedUserId, let isTyping) = events.first {
            XCTAssertEqual(receivedConversationId, conversationId)
            XCTAssertEqual(receivedUserId, userId)
            XCTAssertTrue(isTyping)
        } else {
            XCTFail("Expected typing event")
        }
    }
    
    func testTypingIndicatorStopFlow() async throws {
        // Given
        let conversationId = UUID()
        let userId = UUID()
        
        // Set up real-time subscription
        let subscription = try await realtimeService.subscribe(conversationId: conversationId)
        defer { Task { await subscription.cancel() } }
        
        // Start typing first
        await simulateTypingEvent(conversationId: conversationId, userId: userId, isTyping: true)
        
        // When - Stop typing
        await simulateTypingEvent(conversationId: conversationId, userId: userId, isTyping: false)
        
        // Then
        let events = await collectRealtimeEvents(count: 2, timeout: 1.0)
        XCTAssertEqual(events.count, 2)
        
        // Check stop typing event
        if case .typing(let receivedConversationId, let receivedUserId, let isTyping) = events.last {
            XCTAssertEqual(receivedConversationId, conversationId)
            XCTAssertEqual(receivedUserId, userId)
            XCTAssertFalse(isTyping)
        } else {
            XCTFail("Expected typing stop event")
        }
    }
    
    func testMultipleUsersTyping() async throws {
        // Given
        let conversationId = UUID()
        let user1Id = UUID()
        let user2Id = UUID()
        
        // Set up real-time subscription
        let subscription = try await realtimeService.subscribe(conversationId: conversationId)
        defer { Task { await subscription.cancel() } }
        
        // When - Multiple users start typing
        await simulateTypingEvent(conversationId: conversationId, userId: user1Id, isTyping: true)
        await simulateTypingEvent(conversationId: conversationId, userId: user2Id, isTyping: true)
        
        // Then
        let events = await collectRealtimeEvents(count: 2, timeout: 1.0)
        XCTAssertEqual(events.count, 2)
        
        let typingEvents = events.compactMap { event -> (UUID, Bool)? in
            if case .typing(_, let userId, let isTyping) = event {
                return (userId, isTyping)
            }
            return nil
        }
        
        XCTAssertTrue(typingEvents.contains { $0.0 == user1Id && $0.1 == true })
        XCTAssertTrue(typingEvents.contains { $0.0 == user2Id && $0.1 == true })
    }
    
    // MARK: - Subscription Management Tests
    
    func testSubscriptionLifecycle() async throws {
        // Given
        let conversationId = UUID()
        
        // When - Create subscription
        let subscription = try await realtimeService.subscribe(conversationId: conversationId)
        
        // Then - Should be active
        XCTAssertTrue(await subscription.isActive)
        
        // When - Cancel subscription
        await subscription.cancel()
        
        // Then - Should be inactive
        XCTAssertFalse(await subscription.isActive)
    }
    
    func testMultipleSubscriptions() async throws {
        // Given
        let conversationId1 = UUID()
        let conversationId2 = UUID()
        
        // When - Create multiple subscriptions
        let subscription1 = try await realtimeService.subscribe(conversationId: conversationId1)
        let subscription2 = try await realtimeService.subscribe(conversationId: conversationId2)
        
        defer {
            Task {
                await subscription1.cancel()
                await subscription2.cancel()
            }
        }
        
        // Then - Both should be active
        XCTAssertTrue(await subscription1.isActive)
        XCTAssertTrue(await subscription2.isActive)
        
        // When - Send messages to both conversations
        let message1 = createMockMessage(conversationId: conversationId1, content: "Message 1")
        let message2 = createMockMessage(conversationId: conversationId2, content: "Message 2")
        
        await simulateRealtimeMessageArrival(message1)
        await simulateRealtimeMessageArrival(message2)
        
        // Then - Should receive events for both
        let events = await collectRealtimeEvents(count: 2, timeout: 1.0)
        XCTAssertEqual(events.count, 2)
    }
    
    func testConversationListSubscription() async throws {
        // Given
        let subscription = try await realtimeService.subscribeConversationList()
        defer { Task { await subscription.cancel() } }
        
        // When - Simulate conversation update
        let conversation = createMockConversation()
        await simulateConversationUpdate(conversation)
        
        // Then
        let events = await collectRealtimeEvents(count: 1, timeout: 1.0)
        XCTAssertEqual(events.count, 1)
        
        if case .conversationUpdated(let receivedConversation) = events.first {
            XCTAssertEqual(receivedConversation.id, conversation.id)
        } else {
            XCTFail("Expected conversationUpdated event")
        }
    }
    
    // MARK: - Reconnection Tests
    
    func testReconnectionAfterNetworkFailure() async throws {
        // Given
        let conversationId = UUID()
        let subscription = try await realtimeService.subscribe(conversationId: conversationId)
        defer { Task { await subscription.cancel() } }
        
        // When - Simulate network failure and recovery
        mockSupabase.simulateNetworkFailure()
        
        // Wait for reconnection attempt
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        mockSupabase.restoreNetwork()
        
        // Send message after recovery
        let message = createMockMessage(conversationId: conversationId, content: "After reconnection")
        await simulateRealtimeMessageArrival(message)
        
        // Then - Should still receive events after reconnection
        let events = await collectRealtimeEvents(count: 1, timeout: 2.0)
        XCTAssertEqual(events.count, 1)
        
        if case .messageAdded(let receivedMessage) = events.first {
            XCTAssertEqual(receivedMessage.content, "After reconnection")
        } else {
            XCTFail("Expected messageAdded event after reconnection")
        }
    }
    
    // MARK: - Message Delivery Status Tests
    
    func testMessageDeliveryStatusProgression() async throws {
        // Given
        let conversationId = UUID()
        let messageId = UUID()
        
        let subscription = try await realtimeService.subscribe(conversationId: conversationId)
        defer { Task { await subscription.cancel() } }
        
        // When - Simulate delivery status progression
        let sendingMessage = createMockMessage(
            id: messageId,
            conversationId: conversationId,
            deliveryStatus: .sending
        )
        await simulateRealtimeMessageArrival(sendingMessage)
        
        let sentMessage = createMockMessage(
            id: messageId,
            conversationId: conversationId,
            deliveryStatus: .sent
        )
        await simulateRealtimeMessageUpdate(sentMessage)
        
        let deliveredMessage = createMockMessage(
            id: messageId,
            conversationId: conversationId,
            deliveryStatus: .delivered
        )
        await simulateRealtimeMessageUpdate(deliveredMessage)
        
        // Then
        let events = await collectRealtimeEvents(count: 3, timeout: 1.0)
        XCTAssertEqual(events.count, 3)
        
        // Verify progression
        let messageEvents = events.compactMap { event -> DeliveryStatus? in
            switch event {
            case .messageAdded(let message):
                return message.deliveryStatus
            case .messageUpdated(let message):
                return message.deliveryStatus
            default:
                return nil
            }
        }
        
        XCTAssertEqual(messageEvents[0], .sending)
        XCTAssertEqual(messageEvents[1], .sent)
        XCTAssertEqual(messageEvents[2], .delivered)
    }
    
    func testReadReceiptFlow() async throws {
        // Given
        let conversationId = UUID()
        let messageId = UUID()
        let userId = UUID()
        
        let subscription = try await realtimeService.subscribe(conversationId: conversationId)
        defer { Task { await subscription.cancel() } }
        
        // When - Simulate read receipt
        await simulateReadReceipt(conversationId: conversationId, messageId: messageId, userId: userId)
        
        // Then
        let events = await collectRealtimeEvents(count: 1, timeout: 1.0)
        XCTAssertEqual(events.count, 1)
        
        if case .readReceipt(let receivedConversationId, let receivedMessageId, let receivedUserId) = events.first {
            XCTAssertEqual(receivedConversationId, conversationId)
            XCTAssertEqual(receivedMessageId, messageId)
            XCTAssertEqual(receivedUserId, userId)
        } else {
            XCTFail("Expected readReceipt event")
        }
    }
    
    // MARK: - Helper Methods
    
    private func createMockMessage(
        id: UUID = UUID(),
        conversationId: UUID,
        content: String = "Test message",
        deliveryStatus: DeliveryStatus = .sent
    ) -> Message {
        Message(
            id: id,
            conversationId: conversationId,
            senderId: UUID(),
            content: content,
            attachments: [],
            timestamp: Date(),
            deliveryStatus: deliveryStatus,
            replyTo: nil,
            nonce: nil,
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
    
    private func createMockConversation() -> Conversation {
        Conversation(
            id: UUID(),
            participants: [],
            lastMessage: nil,
            lastActivity: Date(),
            unreadCount: 0,
            unreadMentionsCount: 0,
            isArchived: false,
            isPinned: false,
            isMuted: false,
            lastReadMessageId: nil,
            draftText: nil,
            isGroup: false,
            title: "Test Conversation",
            avatarUrl: nil
        )
    }
    
    private func simulateRealtimeMessageArrival(_ message: Message) async {
        await observer.processRealtimeEvent(MockRealtimeEvent(
            type: "INSERT",
            table: "messages",
            payload: message
        ))
    }
    
    private func simulateRealtimeMessageUpdate(_ message: Message) async {
        await observer.processRealtimeEvent(MockRealtimeEvent(
            type: "UPDATE",
            table: "messages",
            payload: message
        ))
    }
    
    private func simulateTypingEvent(conversationId: UUID, userId: UUID, isTyping: Bool) async {
        await observer.processTypingEvent(MockTypingEvent(
            conversationId: conversationId,
            userId: userId,
            isTyping: isTyping
        ))
    }
    
    private func simulateConversationUpdate(_ conversation: Conversation) async {
        await observer.processRealtimeEvent(MockRealtimeEvent(
            type: "UPDATE",
            table: "conversations",
            payload: conversation
        ))
    }
    
    private func simulateReadReceipt(conversationId: UUID, messageId: UUID, userId: UUID) async {
        await observer.processRealtimeEvent(MockRealtimeEvent(
            type: "INSERT",
            table: "read_receipts",
            payload: [
                "conversation_id": conversationId.uuidString,
                "message_id": messageId.uuidString,
                "user_id": userId.uuidString
            ]
        ))
    }
    
    private func collectRealtimeEvents(count: Int, timeout: TimeInterval = 1.0) async -> [MessagingEvent] {
        var events: [MessagingEvent] = []
        let startTime = Date()
        
        for await event in realtimeService.events {
            events.append(event)
            if events.count >= count || Date().timeIntervalSince(startTime) > timeout {
                break
            }
        }
        
        return events
    }
}

// MARK: - Mock Extensions for Integration Testing

private struct MockRealtimeEvent {
    let type: String
    let table: String?
    let payload: Any
    
    init(type: String, table: String? = nil, payload: Any) {
        self.type = type
        self.table = table
        self.payload = payload
    }
}

private struct MockTypingEvent {
    let conversationId: UUID
    let userId: UUID
    let isTyping: Bool
}

extension MockSupabaseClient {
    func simulateNetworkFailure() {
        shouldFailSubscription = true
    }
    
    func restoreNetwork() {
        shouldFailSubscription = false
    }
}

extension MockMessagingSubscription {
    var isActive: Bool {
        return !isCancelled
    }
    
    private var isCancelled: Bool {
        // Mock implementation - would track cancellation state
        return false
    }
}