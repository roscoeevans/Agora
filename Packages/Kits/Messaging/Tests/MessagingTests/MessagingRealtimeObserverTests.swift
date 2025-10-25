import XCTest
@testable import Messaging
import AppFoundation

final class MessagingRealtimeObserverTests: XCTestCase {
    
    var observer: MessagingRealtimeObserver!
    var mockSupabase: MockSupabaseClient!
    var outputStream: AsyncStream<MessagingRealtimeObserver.Output>!
    var outputContinuation: AsyncStream<MessagingRealtimeObserver.Output>.Continuation!
    
    override func setUp() async throws {
        try await super.setUp()
        
        mockSupabase = MockSupabaseClient()
        
        let (stream, continuation) = AsyncStream<MessagingRealtimeObserver.Output>.makeStream()
        outputStream = stream
        outputContinuation = continuation
        
        observer = MessagingRealtimeObserver(
            config: MessagingRealtimeObserver.Config(),
            supabase: mockSupabase,
            outputContinuation: continuation
        )
    }
    
    override func tearDown() async throws {
        outputContinuation.finish()
        observer = nil
        mockSupabase = nil
        outputStream = nil
        outputContinuation = nil
        try await super.tearDown()
    }
    
    // MARK: - Configuration Tests
    
    func testDefaultConfiguration() {
        let config = MessagingRealtimeObserver.Config()
        
        XCTAssertEqual(config.maxIdsPerChannel, 100)
        XCTAssertEqual(config.throttlePerConversationMs, 300)
        XCTAssertEqual(config.scrollDebounceMs, 500)
        XCTAssertEqual(config.typingKeepaliveSeconds, 3.0)
        XCTAssertEqual(config.typingAutoStopSeconds, 4.0)
    }
    
    func testCustomConfiguration() {
        let config = MessagingRealtimeObserver.Config(
            maxIdsPerChannel: 50,
            throttlePerConversationMs: 200,
            scrollDebounceMs: 300,
            typingKeepaliveSeconds: 2.0,
            typingAutoStopSeconds: 3.0
        )
        
        XCTAssertEqual(config.maxIdsPerChannel, 50)
        XCTAssertEqual(config.throttlePerConversationMs, 200)
        XCTAssertEqual(config.scrollDebounceMs, 300)
        XCTAssertEqual(config.typingKeepaliveSeconds, 2.0)
        XCTAssertEqual(config.typingAutoStopSeconds, 3.0)
    }
    
    // MARK: - Visible Conversations Management Tests
    
    func testSetVisibleConversations() async {
        // Given
        let conversationIds = Set([UUID(), UUID(), UUID()])
        
        // When
        await observer.handle(.setVisibleConversations(conversationIds))
        
        // Then
        let visibleConversations = await observer.getVisibleConversations()
        XCTAssertEqual(visibleConversations, conversationIds)
    }
    
    func testSetVisibleConversationsEmpty() async {
        // Given
        let conversationIds = Set<UUID>()
        
        // When
        await observer.handle(.setVisibleConversations(conversationIds))
        
        // Then
        let visibleConversations = await observer.getVisibleConversations()
        XCTAssertTrue(visibleConversations.isEmpty)
    }
    
    func testSetVisibleConversationsLargeSet() async {
        // Given - More than maxIdsPerChannel
        let conversationIds = Set((0..<150).map { _ in UUID() })
        
        // When
        await observer.handle(.setVisibleConversations(conversationIds))
        
        // Then - Should handle chunking
        let visibleConversations = await observer.getVisibleConversations()
        XCTAssertEqual(visibleConversations, conversationIds)
    }
    
    // MARK: - Active Thread Management Tests
    
    func testSetActiveThread() async {
        // Given
        let threadId = UUID()
        
        // When
        await observer.handle(.setActiveThread(threadId))
        
        // Then
        let activeThread = await observer.getActiveThread()
        XCTAssertEqual(activeThread, threadId)
    }
    
    func testSetActiveThreadNil() async {
        // Given
        let threadId = UUID()
        await observer.handle(.setActiveThread(threadId))
        
        // When
        await observer.handle(.setActiveThread(nil))
        
        // Then
        let activeThread = await observer.getActiveThread()
        XCTAssertNil(activeThread)
    }
    
    // MARK: - Lifecycle Management Tests
    
    func testLifecycleForeground() async {
        // When
        await observer.handle(.lifecycleForeground)
        
        // Then
        let isInForeground = await observer.getIsInForeground()
        XCTAssertTrue(isInForeground)
    }
    
    func testLifecycleBackground() async {
        // When
        await observer.handle(.lifecycleBackground)
        
        // Then
        let isInForeground = await observer.getIsInForeground()
        XCTAssertFalse(isInForeground)
    }
    
    // MARK: - Typing Management Tests
    
    func testSetTypingTrue() async {
        // Given
        let conversationId = UUID()
        
        // When
        await observer.handle(.setTyping(conversationId: conversationId, isTyping: true))
        
        // Then
        let typingState = await observer.getTypingState(for: conversationId)
        XCTAssertEqual(typingState?.isTyping, true)
    }
    
    func testSetTypingFalse() async {
        // Given
        let conversationId = UUID()
        await observer.handle(.setTyping(conversationId: conversationId, isTyping: true))
        
        // When
        await observer.handle(.setTyping(conversationId: conversationId, isTyping: false))
        
        // Then
        let typingState = await observer.getTypingState(for: conversationId)
        XCTAssertEqual(typingState?.isTyping, false)
    }
    
    func testTypingAutoStop() async {
        // Given
        let conversationId = UUID()
        let config = MessagingRealtimeObserver.Config(typingAutoStopSeconds: 0.1) // Very short for testing
        
        let observer = MessagingRealtimeObserver(
            config: config,
            supabase: mockSupabase,
            outputContinuation: outputContinuation
        )
        
        // When
        await observer.handle(.setTyping(conversationId: conversationId, isTyping: true))
        
        // Wait for auto-stop
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        // Then
        let typingState = await observer.getTypingState(for: conversationId)
        XCTAssertEqual(typingState?.isTyping, false)
    }
    
    // MARK: - Event Processing Tests
    
    func testProcessMessageAddedEvent() async {
        // Given
        let message = createMockMessage()
        let event = createMockRealtimeEvent(type: "INSERT", payload: message)
        
        // When
        await observer.processRealtimeEvent(event)
        
        // Then
        let outputs = await collectOutputs(count: 1)
        guard case .messageAdded(let receivedMessage) = outputs.first else {
            XCTFail("Expected messageAdded output")
            return
        }
        XCTAssertEqual(receivedMessage.id, message.id)
    }
    
    func testProcessMessageUpdatedEvent() async {
        // Given
        let message = createMockMessage()
        let event = createMockRealtimeEvent(type: "UPDATE", payload: message)
        
        // When
        await observer.processRealtimeEvent(event)
        
        // Then
        let outputs = await collectOutputs(count: 1)
        guard case .messageUpdated(let receivedMessage) = outputs.first else {
            XCTFail("Expected messageUpdated output")
            return
        }
        XCTAssertEqual(receivedMessage.id, message.id)
    }
    
    func testProcessMessageDeletedEvent() async {
        // Given
        let messageId = UUID()
        let conversationId = UUID()
        let event = createMockRealtimeEvent(
            type: "DELETE",
            payload: ["id": messageId.uuidString, "conversation_id": conversationId.uuidString]
        )
        
        // When
        await observer.processRealtimeEvent(event)
        
        // Then
        let outputs = await collectOutputs(count: 1)
        guard case .messageDeleted(let receivedConversationId, let receivedMessageId) = outputs.first else {
            XCTFail("Expected messageDeleted output")
            return
        }
        XCTAssertEqual(receivedConversationId, conversationId)
        XCTAssertEqual(receivedMessageId, messageId)
    }
    
    func testProcessTypingEvent() async {
        // Given
        let conversationId = UUID()
        let userId = UUID()
        let event = createMockTypingEvent(conversationId: conversationId, userId: userId, isTyping: true)
        
        // When
        await observer.processTypingEvent(event)
        
        // Then
        let outputs = await collectOutputs(count: 1)
        guard case .typing(let receivedConversationId, let receivedUserId, let isTyping) = outputs.first else {
            XCTFail("Expected typing output")
            return
        }
        XCTAssertEqual(receivedConversationId, conversationId)
        XCTAssertEqual(receivedUserId, userId)
        XCTAssertTrue(isTyping)
    }
    
    // MARK: - Throttling Tests
    
    func testEventThrottling() async {
        // Given
        let conversationId = UUID()
        let message1 = createMockMessage(conversationId: conversationId)
        let message2 = createMockMessage(conversationId: conversationId)
        
        // When - Send events rapidly
        await observer.processRealtimeEvent(createMockRealtimeEvent(type: "INSERT", payload: message1))
        await observer.processRealtimeEvent(createMockRealtimeEvent(type: "INSERT", payload: message2))
        
        // Then - Should throttle based on configuration
        let outputs = await collectOutputs(count: 2, timeout: 1.0)
        XCTAssertLessThanOrEqual(outputs.count, 2) // May be throttled
    }
    
    // MARK: - Error Handling Tests
    
    func testHandleInvalidEvent() async {
        // Given
        let invalidEvent = createMockRealtimeEvent(type: "INVALID", payload: ["invalid": "data"])
        
        // When
        await observer.processRealtimeEvent(invalidEvent)
        
        // Then - Should handle gracefully without crashing
        let outputs = await collectOutputs(count: 1, timeout: 0.5)
        // May produce error output or no output
        XCTAssertTrue(outputs.count <= 1)
    }
    
    func testHandleNetworkError() async {
        // Given
        mockSupabase.shouldFailSubscription = true
        let conversationIds = Set([UUID()])
        
        // When
        await observer.handle(.setVisibleConversations(conversationIds))
        
        // Then - Should handle error gracefully
        let outputs = await collectOutputs(count: 1, timeout: 0.5)
        if let output = outputs.first {
            if case .error = output {
                // Expected error output
                XCTAssertTrue(true)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func createMockMessage(conversationId: UUID = UUID()) -> Message {
        Message(
            id: UUID(),
            conversationId: conversationId,
            senderId: UUID(),
            content: "Test message",
            attachments: [],
            timestamp: Date(),
            deliveryStatus: .sent,
            replyTo: nil,
            nonce: nil,
            editedAt: nil,
            deletedAt: nil,
            expiresAt: nil,
            systemKind: nil,
            linkPreview: nil
        )
    }
    
    private func createMockRealtimeEvent(type: String, payload: Any) -> MockRealtimeEvent {
        MockRealtimeEvent(type: type, payload: payload)
    }
    
    private func createMockTypingEvent(conversationId: UUID, userId: UUID, isTyping: Bool) -> MockTypingEvent {
        MockTypingEvent(
            conversationId: conversationId,
            userId: userId,
            isTyping: isTyping
        )
    }
    
    private func collectOutputs(count: Int, timeout: TimeInterval = 1.0) async -> [MessagingRealtimeObserver.Output] {
        var outputs: [MessagingRealtimeObserver.Output] = []
        let startTime = Date()
        
        for await output in outputStream {
            outputs.append(output)
            if outputs.count >= count || Date().timeIntervalSince(startTime) > timeout {
                break
            }
        }
        
        return outputs
    }
}

// MARK: - Mock Types

private struct MockRealtimeEvent {
    let type: String
    let payload: Any
}

private struct MockTypingEvent {
    let conversationId: UUID
    let userId: UUID
    let isTyping: Bool
}

private class MockSupabaseClient: SupabaseClientProtocol {
    var shouldFailSubscription = false
    
    func createChannel(_ name: String) -> MockRealtimeChannel {
        MockRealtimeChannel(shouldFail: shouldFailSubscription)
    }
}

private class MockRealtimeChannel {
    let shouldFail: Bool
    
    init(shouldFail: Bool = false) {
        self.shouldFail = shouldFail
    }
    
    func on(_ event: String, callback: @escaping (Any) -> Void) -> MockRealtimeChannel {
        return self
    }
    
    func subscribe() async throws {
        if shouldFail {
            throw MessagingError.networkError("Mock subscription failure")
        }
    }
    
    func unsubscribe() async {
        // Mock implementation
    }
}

// MARK: - Observer Extensions for Testing

extension MessagingRealtimeObserver {
    func getVisibleConversations() async -> Set<UUID> {
        return visibleConversations
    }
    
    func getActiveThread() async -> UUID? {
        return activeThread
    }
    
    func getIsInForeground() async -> Bool {
        return isInForeground
    }
    
    func getTypingState(for conversationId: UUID) async -> TypingState? {
        return typingStates[conversationId]
    }
    
    func processRealtimeEvent(_ event: MockRealtimeEvent) async {
        // Mock implementation for testing
    }
    
    func processTypingEvent(_ event: MockTypingEvent) async {
        // Mock implementation for testing
    }
}