import XCTest
@testable import Messaging
import AppFoundation

final class MessagingTests: XCTestCase {
    
    func testMessagingServiceCreation() throws {
        // Test that we can create mock messaging services
        let services = createMockMessagingServices()
        
        XCTAssertNotNil(services.messaging)
        XCTAssertNotNil(services.realtime)
        XCTAssertNotNil(services.media)
    }
    
    func testMessageNonceCreation() throws {
        let nonce1 = MessageNonce()
        let nonce2 = MessageNonce()
        
        // Nonces should be unique
        XCTAssertNotEqual(nonce1.value, nonce2.value)
    }
    
    func testOutboundMessageDraftCreation() throws {
        let conversationId = UUID()
        let draft = OutboundMessageDraft(conversationId: conversationId, text: "Hello")
        
        XCTAssertEqual(draft.conversationId, conversationId)
        XCTAssertEqual(draft.text, "Hello")
        XCTAssertTrue(draft.attachments.isEmpty)
    }
    
    func testDeliveryStatusRawValues() throws {
        XCTAssertEqual(DeliveryStatus.sending.rawValue, "sending")
        XCTAssertEqual(DeliveryStatus.sent.rawValue, "sent")
        XCTAssertEqual(DeliveryStatus.delivered.rawValue, "delivered")
        XCTAssertEqual(DeliveryStatus.read.rawValue, "read")
        XCTAssertEqual(DeliveryStatus.failed.rawValue, "failed")
    }
    
    func testAttachmentTypeRawValues() throws {
        XCTAssertEqual(AttachmentType.image.rawValue, "image")
        XCTAssertEqual(AttachmentType.video.rawValue, "video")
        XCTAssertEqual(AttachmentType.audio.rawValue, "audio")
        XCTAssertEqual(AttachmentType.document.rawValue, "document")
    }
    
    func testSystemMessageKindRawValues() throws {
        XCTAssertEqual(SystemMessageKind.userJoined.rawValue, "userJoined")
        XCTAssertEqual(SystemMessageKind.userLeft.rawValue, "userLeft")
        XCTAssertEqual(SystemMessageKind.conversationCreated.rawValue, "conversationCreated")
        XCTAssertEqual(SystemMessageKind.titleChanged.rawValue, "titleChanged")
    }
}

// MARK: - Mock Services for Testing

public struct MockMessagingServices {
    public let messaging: MockMessagingService
    public let realtime: MockMessagingRealtime
    public let media: MockMessagingMedia
    
    public init() {
        self.messaging = MockMessagingService()
        self.realtime = MockMessagingRealtime()
        self.media = MockMessagingMedia()
    }
}

public func createMockMessagingServices() -> MockMessagingServices {
    return MockMessagingServices()
}

public class MockMessagingService: MessagingServiceProtocol {
    public var mockConversations: [Conversation] = []
    public var mockMessages: [Message] = []
    public var mockOlderMessages: [Message] = []
    public var mockSentMessage: Message?
    public var shouldFailFetchConversations = false
    public var shouldFailFetchMessages = false
    public var shouldFailSendMessage = false
    
    public var archivedConversations: Set<UUID> = []
    public var mutedConversations: Set<UUID> = []
    public var pinnedConversations: Set<UUID> = []
    
    public init() {}
    
    public func createConversation(participantIds: [UUID]) async throws -> Conversation {
        let conversation = Conversation(
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
            isGroup: participantIds.count > 1,
            title: nil,
            avatarUrl: nil
        )
        mockConversations.append(conversation)
        return conversation
    }
    
    public func leaveConversation(id: UUID) async throws {
        mockConversations.removeAll { $0.id == id }
    }
    
    public func setMuted(_ muted: Bool, for id: UUID) async throws {
        if muted {
            mutedConversations.insert(id)
        } else {
            mutedConversations.remove(id)
        }
    }
    
    public func setArchived(_ archived: Bool, for id: UUID) async throws {
        if archived {
            archivedConversations.insert(id)
        } else {
            archivedConversations.remove(id)
        }
    }
    
    public func pin(_ pinned: Bool, for id: UUID) async throws {
        if pinned {
            pinnedConversations.insert(id)
        } else {
            pinnedConversations.remove(id)
        }
    }
    
    public func fetchConversations(page: Int, pageSize: Int) async throws -> [Conversation] {
        if shouldFailFetchConversations {
            throw MessagingError.networkError("Mock fetch conversations failure")
        }
        return mockConversations
    }
    
    public func fetchMessages(conversationId: UUID, before: Date?, limit: Int) async throws -> [Message] {
        if shouldFailFetchMessages {
            throw MessagingError.networkError("Mock fetch messages failure")
        }
        
        if before != nil {
            return mockOlderMessages
        } else {
            return mockMessages
        }
    }
    
    public func send(text: String, in conversationId: UUID) async throws -> Message {
        if shouldFailSendMessage {
            throw MessagingError.networkError("Mock send message failure")
        }
        
        let message = mockSentMessage ?? Message(
            id: UUID(),
            conversationId: conversationId,
            senderId: UUID(),
            content: text,
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
        
        mockMessages.append(message)
        return message
    }
    
    public func send(attachment: Attachment, in conversationId: UUID) async throws -> Message {
        if shouldFailSendMessage {
            throw MessagingError.networkError("Mock send attachment failure")
        }
        
        let message = Message(
            id: UUID(),
            conversationId: conversationId,
            senderId: UUID(),
            content: "",
            attachments: [attachment],
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
        
        mockMessages.append(message)
        return message
    }
    
    public func markDelivered(conversationId: UUID, messageId: UUID) async throws {
        // Mock implementation
    }
    
    public func markReadRange(conversationId: UUID, upTo messageId: UUID) async throws {
        // Mock implementation
    }
}

public class MockMessagingRealtime: MessagingRealtimeProtocol {
    public var lastTypingConversationId: UUID?
    public var lastTypingState: Bool?
    public var mockSubscription: MockMessagingSubscription?
    
    public init() {}
    
    public func subscribeConversationList() async throws -> MessagingSubscription {
        let subscription = MockMessagingSubscription()
        mockSubscription = subscription
        return subscription
    }
    
    public func subscribe(conversationId: UUID) async throws -> MessagingSubscription {
        let subscription = MockMessagingSubscription()
        mockSubscription = subscription
        return subscription
    }
    
    public func setTyping(conversationId: UUID, isTyping: Bool) async {
        lastTypingConversationId = conversationId
        lastTypingState = isTyping
    }
    
    public var events: AsyncStream<MessagingEvent> {
        AsyncStream { continuation in
            // Mock implementation - can be extended for testing
            continuation.finish()
        }
    }
}

public class MockMessagingMedia: MessagingMediaProtocol {
    public var shouldFailPrepareAttachment = false
    public var mockAttachment: Attachment?
    
    public init() {}
    
    public func prepareAttachment(_ pick: MediaPick) async throws -> Attachment {
        if shouldFailPrepareAttachment {
            throw MessagingError.mediaProcessingFailed("Mock media processing failure")
        }
        
        return mockAttachment ?? Attachment(
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

public class MockMessagingSubscription: MessagingSubscription {
    public var isActive = true
    
    public init() {}
    
    public func cancel() async {
        isActive = false
    }
}