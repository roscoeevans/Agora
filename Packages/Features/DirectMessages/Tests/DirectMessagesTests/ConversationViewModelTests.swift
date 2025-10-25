import XCTest
@testable import DirectMessages
import TestSupport
import AppFoundation

@MainActor
final class ConversationViewModelTests: XCTestCase {
    
    var mockServices: MockMessagingServices!
    var conversationId: UUID!
    var viewModel: ConversationViewModel!
    
    override func setUp() {
        super.setUp()
        mockServices = createMockMessagingServices()
        conversationId = UUID()
        viewModel = ConversationViewModel(
            conversationId: conversationId,
            dependencies: Dependencies(
                messaging: mockServices.messaging,
                messagingRealtime: mockServices.realtime,
                messagingMedia: mockServices.media
            )
        )
    }
    
    override func tearDown() {
        viewModel = nil
        mockServices = nil
        conversationId = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        XCTAssertEqual(viewModel.conversationId, conversationId)
        XCTAssertTrue(viewModel.messages.isEmpty)
        XCTAssertFalse(viewModel.isLoadingMessages)
        XCTAssertFalse(viewModel.isLoadingOlderMessages)
        XCTAssertNil(viewModel.conversation)
        XCTAssertTrue(viewModel.typingUsers.isEmpty)
        XCTAssertNil(viewModel.currentDraft)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.hasReachedEnd)
    }
    
    // MARK: - Message Loading Tests
    
    func testLoadMessages() async {
        // Given
        let mockMessages = createMockMessages()
        mockServices.messaging.mockMessages = mockMessages
        
        // When
        await viewModel.loadMessages()
        
        // Then
        XCTAssertEqual(viewModel.messages.count, mockMessages.count)
        XCTAssertFalse(viewModel.isLoadingMessages)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testLoadMessagesWithError() async {
        // Given
        mockServices.messaging.shouldFailFetchMessages = true
        
        // When
        await viewModel.loadMessages()
        
        // Then
        XCTAssertTrue(viewModel.messages.isEmpty)
        XCTAssertFalse(viewModel.isLoadingMessages)
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    func testLoadOlderMessages() async {
        // Given
        let initialMessages = createMockMessages()
        let olderMessages = createMockMessages(count: 2, startIndex: 10)
        mockServices.messaging.mockMessages = initialMessages
        mockServices.messaging.mockOlderMessages = olderMessages
        
        // Load initial messages first
        await viewModel.loadMessages()
        let initialCount = viewModel.messages.count
        
        // When
        await viewModel.loadOlderMessages()
        
        // Then
        XCTAssertEqual(viewModel.messages.count, initialCount + olderMessages.count)
        XCTAssertFalse(viewModel.isLoadingOlderMessages)
    }
    
    // MARK: - Message Sending Tests
    
    func testSendTextMessage() async {
        // Given
        let messageText = "Hello, world!"
        let mockSentMessage = createMockMessage(content: messageText)
        mockServices.messaging.mockSentMessage = mockSentMessage
        
        // When
        await viewModel.sendMessage(text: messageText)
        
        // Then
        XCTAssertTrue(viewModel.messages.contains { $0.content == messageText })
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testSendMessageWithAttachment() async {
        // Given
        let messageText = "Check this out!"
        let mockAttachment = createMockAttachment()
        let mockSentMessage = createMockMessage(content: messageText, attachments: [mockAttachment])
        mockServices.messaging.mockSentMessage = mockSentMessage
        
        // When
        await viewModel.sendMessage(text: messageText, attachments: [mockAttachment])
        
        // Then
        XCTAssertTrue(viewModel.messages.contains { $0.content == messageText && !$0.attachments.isEmpty })
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testOptimisticMessageUpdate() async {
        // Given
        let messageText = "Optimistic message"
        let nonce = MessageNonce()
        
        // When
        await viewModel.sendMessage(text: messageText)
        
        // Then - Should have optimistic message with sending status
        let optimisticMessage = viewModel.messages.first { $0.content == messageText }
        XCTAssertNotNil(optimisticMessage)
        XCTAssertEqual(optimisticMessage?.deliveryStatus, .sending)
    }
    
    // MARK: - Typing Indicator Tests
    
    func testSetTyping() async {
        // When
        await viewModel.setTyping(true)
        
        // Then
        XCTAssertTrue(mockServices.realtime.lastTypingState ?? false)
        XCTAssertEqual(mockServices.realtime.lastTypingConversationId, conversationId)
    }
    
    func testStopTyping() async {
        // Given - Start typing first
        await viewModel.setTyping(true)
        
        // When
        await viewModel.setTyping(false)
        
        // Then
        XCTAssertFalse(mockServices.realtime.lastTypingState ?? true)
    }
    
    func testHandleTypingEvent() {
        // Given
        let userId = UUID()
        
        // When
        viewModel.handleTypingEvent(userId: userId, isTyping: true)
        
        // Then
        XCTAssertTrue(viewModel.typingUsers.contains(userId))
        
        // When - Stop typing
        viewModel.handleTypingEvent(userId: userId, isTyping: false)
        
        // Then
        XCTAssertFalse(viewModel.typingUsers.contains(userId))
    }
    
    // MARK: - Draft Management Tests
    
    func testDraftPersistence() {
        // Given
        let draftText = "Draft message"
        
        // When
        viewModel.updateDraft(text: draftText)
        
        // Then
        XCTAssertEqual(viewModel.currentDraft?.text, draftText)
        XCTAssertEqual(viewModel.currentDraft?.conversationId, conversationId)
    }
    
    func testClearDraft() {
        // Given
        viewModel.updateDraft(text: "Some draft")
        XCTAssertNotNil(viewModel.currentDraft)
        
        // When
        viewModel.clearDraft()
        
        // Then
        XCTAssertNil(viewModel.currentDraft)
    }
    
    // MARK: - Real-time Event Handling Tests
    
    func testHandleMessageAdded() {
        // Given
        let newMessage = createMockMessage()
        let initialCount = viewModel.messages.count
        
        // When
        viewModel.handleMessageAdded(newMessage)
        
        // Then
        XCTAssertEqual(viewModel.messages.count, initialCount + 1)
        XCTAssertTrue(viewModel.messages.contains { $0.id == newMessage.id })
    }
    
    func testHandleMessageUpdated() {
        // Given
        let originalMessage = createMockMessage()
        viewModel.handleMessageAdded(originalMessage)
        
        let updatedMessage = Message(
            id: originalMessage.id,
            conversationId: originalMessage.conversationId,
            senderId: originalMessage.senderId,
            content: "Updated content",
            attachments: originalMessage.attachments,
            timestamp: originalMessage.timestamp,
            deliveryStatus: .delivered,
            replyTo: originalMessage.replyTo,
            nonce: originalMessage.nonce,
            editedAt: Date(),
            deletedAt: originalMessage.deletedAt,
            expiresAt: originalMessage.expiresAt,
            systemKind: originalMessage.systemKind,
            linkPreview: originalMessage.linkPreview
        )
        
        // When
        viewModel.handleMessageUpdated(updatedMessage)
        
        // Then
        let message = viewModel.messages.first { $0.id == originalMessage.id }
        XCTAssertEqual(message?.content, "Updated content")
        XCTAssertEqual(message?.deliveryStatus, .delivered)
        XCTAssertNotNil(message?.editedAt)
    }
    
    func testHandleMessageDeleted() {
        // Given
        let message = createMockMessage()
        viewModel.handleMessageAdded(message)
        let initialCount = viewModel.messages.count
        
        // When
        viewModel.handleMessageDeleted(messageId: message.id)
        
        // Then
        XCTAssertEqual(viewModel.messages.count, initialCount - 1)
        XCTAssertFalse(viewModel.messages.contains { $0.id == message.id })
    }
    
    // MARK: - Helper Methods
    
    private func createMockMessages(count: Int = 3, startIndex: Int = 0) -> [Message] {
        return (startIndex..<startIndex + count).map { index in
            createMockMessage(content: "Message \(index)")
        }
    }
    
    private func createMockMessage(
        content: String = "Test message",
        attachments: [Attachment] = []
    ) -> Message {
        Message(
            id: UUID(),
            conversationId: conversationId,
            senderId: UUID(),
            content: content,
            attachments: attachments,
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