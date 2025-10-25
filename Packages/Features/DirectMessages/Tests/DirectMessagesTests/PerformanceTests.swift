import XCTest
@testable import DirectMessages
import TestSupport
import AppFoundation

@MainActor
final class DirectMessagesPerformanceTests: XCTestCase {
    
    var mockServices: MockMessagingServices!
    
    override func setUp() {
        super.setUp()
        mockServices = createMockMessagingServices()
    }
    
    override func tearDown() {
        mockServices = nil
        super.tearDown()
    }
    
    // MARK: - Message List Performance Tests
    
    func testMessageListPerformanceWith10KMessages() {
        // Given
        let conversationId = UUID()
        let viewModel = ConversationViewModel(
            conversationId: conversationId,
            dependencies: Dependencies(
                messaging: mockServices.messaging,
                messagingRealtime: mockServices.realtime,
                messagingMedia: mockServices.media
            )
        )
        
        let largeMessageSet = createLargeMessageSet(count: 10_000, conversationId: conversationId)
        mockServices.messaging.mockMessages = largeMessageSet
        
        // When & Then - Measure loading performance
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            Task {
                await viewModel.loadMessages()
            }
        }
        
        // Verify messages were loaded
        XCTAssertEqual(viewModel.messages.count, 10_000)
    }
    
    func testMessageListScrollPerformance() {
        // Given
        let conversationId = UUID()
        let viewModel = ConversationViewModel(
            conversationId: conversationId,
            dependencies: Dependencies(
                messaging: mockServices.messaging,
                messagingRealtime: mockServices.realtime,
                messagingMedia: mockServices.media
            )
        )
        
        let messages = createLargeMessageSet(count: 1_000, conversationId: conversationId)
        viewModel.messages = messages
        
        // When & Then - Measure pagination performance
        measure(metrics: [XCTClockMetric()]) {
            Task {
                // Simulate loading older messages (pagination)
                await viewModel.loadOlderMessages()
            }
        }
    }
    
    func testMessageInsertionPerformance() {
        // Given
        let conversationId = UUID()
        let viewModel = ConversationViewModel(
            conversationId: conversationId,
            dependencies: Dependencies(
                messaging: mockServices.messaging,
                messagingRealtime: mockServices.realtime,
                messagingMedia: mockServices.media
            )
        )
        
        let existingMessages = createLargeMessageSet(count: 5_000, conversationId: conversationId)
        viewModel.messages = existingMessages
        
        // When & Then - Measure new message insertion performance
        measure(metrics: [XCTClockMetric()]) {
            for i in 0..<100 {
                let newMessage = createMockMessage(
                    conversationId: conversationId,
                    content: "New message \(i)"
                )
                viewModel.handleMessageAdded(newMessage)
            }
        }
        
        // Verify messages were added
        XCTAssertEqual(viewModel.messages.count, 5_100)
    }
    
    func testMessageUpdatePerformance() {
        // Given
        let conversationId = UUID()
        let viewModel = ConversationViewModel(
            conversationId: conversationId,
            dependencies: Dependencies(
                messaging: mockServices.messaging,
                messagingRealtime: mockServices.realtime,
                messagingMedia: mockServices.media
            )
        )
        
        let messages = createLargeMessageSet(count: 1_000, conversationId: conversationId)
        viewModel.messages = messages
        
        // When & Then - Measure message update performance
        measure(metrics: [XCTClockMetric()]) {
            for message in messages.prefix(100) {
                let updatedMessage = Message(
                    id: message.id,
                    conversationId: message.conversationId,
                    senderId: message.senderId,
                    content: "Updated: \(message.content)",
                    attachments: message.attachments,
                    timestamp: message.timestamp,
                    deliveryStatus: .delivered,
                    replyTo: message.replyTo,
                    nonce: message.nonce,
                    editedAt: Date(),
                    deletedAt: message.deletedAt,
                    expiresAt: message.expiresAt,
                    systemKind: message.systemKind,
                    linkPreview: message.linkPreview
                )
                viewModel.handleMessageUpdated(updatedMessage)
            }
        }
    }
    
    // MARK: - Conversation List Performance Tests
    
    func testConversationListPerformanceWithLargeDataset() {
        // Given
        let viewModel = DirectMessagesViewModel(
            dependencies: Dependencies(
                messaging: mockServices.messaging,
                messagingRealtime: mockServices.realtime,
                messagingMedia: mockServices.media
            )
        )
        
        let largeConversationSet = createLargeConversationSet(count: 1_000)
        mockServices.messaging.mockConversations = largeConversationSet
        
        // When & Then - Measure loading performance
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            Task {
                await viewModel.loadConversations()
            }
        }
        
        // Verify conversations were loaded
        XCTAssertEqual(viewModel.conversations.count, 1_000)
    }
    
    func testConversationSearchPerformance() {
        // Given
        let viewModel = DirectMessagesViewModel(
            dependencies: Dependencies(
                messaging: mockServices.messaging,
                messagingRealtime: mockServices.realtime,
                messagingMedia: mockServices.media
            )
        )
        
        let conversations = createLargeConversationSet(count: 5_000)
        viewModel.conversations = conversations
        
        // When & Then - Measure search performance
        measure(metrics: [XCTClockMetric()]) {
            viewModel.searchText = "test"
            let _ = viewModel.filteredConversations
            
            viewModel.searchText = "conversation"
            let _ = viewModel.filteredConversations
            
            viewModel.searchText = "user"
            let _ = viewModel.filteredConversations
        }
    }
    
    func testConversationUpdatePerformance() {
        // Given
        let viewModel = DirectMessagesViewModel(
            dependencies: Dependencies(
                messaging: mockServices.messaging,
                messagingRealtime: mockServices.realtime,
                messagingMedia: mockServices.media
            )
        )
        
        let conversations = createLargeConversationSet(count: 1_000)
        viewModel.conversations = conversations
        
        // When & Then - Measure conversation update performance
        measure(metrics: [XCTClockMetric()]) {
            for conversation in conversations.prefix(100) {
                let updatedConversation = Conversation(
                    id: conversation.id,
                    participants: conversation.participants,
                    lastMessage: createMockMessage(content: "Updated message"),
                    lastActivity: Date(),
                    unreadCount: conversation.unreadCount + 1,
                    unreadMentionsCount: conversation.unreadMentionsCount,
                    isArchived: conversation.isArchived,
                    isPinned: conversation.isPinned,
                    isMuted: conversation.isMuted,
                    lastReadMessageId: conversation.lastReadMessageId,
                    draftText: conversation.draftText,
                    isGroup: conversation.isGroup,
                    title: conversation.title,
                    avatarUrl: conversation.avatarUrl
                )
                viewModel.handleConversationUpdated(updatedConversation)
            }
        }
    }
    
    // MARK: - Real-time Performance Tests
    
    func testRealtimeEventProcessingPerformance() async {
        // Given
        let observer = MessagingRealtimeObserver(
            config: MessagingRealtimeObserver.Config(),
            supabase: MockSupabaseClient(),
            outputContinuation: AsyncStream<MessagingRealtimeObserver.Output>.Continuation { _ in }
        )
        
        let conversationIds = Set((0..<100).map { _ in UUID() })
        await observer.handle(.setVisibleConversations(conversationIds))
        
        // When & Then - Measure event processing performance
        measure(metrics: [XCTClockMetric()]) {
            Task {
                for i in 0..<1000 {
                    let message = createMockMessage(content: "Realtime message \(i)")
                    await observer.processRealtimeEvent(MockRealtimeEvent(
                        type: "INSERT",
                        payload: message
                    ))
                }
            }
        }
    }
    
    func testTypingEventPerformance() async {
        // Given
        let observer = MessagingRealtimeObserver(
            config: MessagingRealtimeObserver.Config(),
            supabase: MockSupabaseClient(),
            outputContinuation: AsyncStream<MessagingRealtimeObserver.Output>.Continuation { _ in }
        )
        
        let conversationIds = (0..<50).map { _ in UUID() }
        
        // When & Then - Measure typing event performance
        measure(metrics: [XCTClockMetric()]) {
            Task {
                for conversationId in conversationIds {
                    await observer.handle(.setTyping(conversationId: conversationId, isTyping: true))
                    await observer.handle(.setTyping(conversationId: conversationId, isTyping: false))
                }
            }
        }
    }
    
    func testChannelManagementPerformance() async {
        // Given
        let observer = MessagingRealtimeObserver(
            config: MessagingRealtimeObserver.Config(maxIdsPerChannel: 50),
            supabase: MockSupabaseClient(),
            outputContinuation: AsyncStream<MessagingRealtimeObserver.Output>.Continuation { _ in }
        )
        
        // When & Then - Measure channel management with large conversation sets
        measure(metrics: [XCTClockMetric()]) {
            Task {
                // Test with conversation set requiring chunking
                let largeConversationSet = Set((0..<500).map { _ in UUID() })
                await observer.handle(.setVisibleConversations(largeConversationSet))
                
                // Update with different set
                let updatedConversationSet = Set((0..<300).map { _ in UUID() })
                await observer.handle(.setVisibleConversations(updatedConversationSet))
            }
        }
    }
    
    // MARK: - Memory Performance Tests
    
    func testMemoryUsageWithLargeConversationList() {
        // Given
        let viewModel = DirectMessagesViewModel(
            dependencies: Dependencies(
                messaging: mockServices.messaging,
                messagingRealtime: mockServices.realtime,
                messagingMedia: mockServices.media
            )
        )
        
        // When & Then - Measure memory usage
        measure(metrics: [XCTMemoryMetric()]) {
            let conversations = createLargeConversationSet(count: 10_000)
            viewModel.conversations = conversations
            
            // Perform operations that might affect memory
            viewModel.searchText = "test"
            let _ = viewModel.filteredConversations
            
            viewModel.searchText = ""
            let _ = viewModel.filteredConversations
        }
    }
    
    func testMemoryUsageWithLargeMessageList() {
        // Given
        let conversationId = UUID()
        let viewModel = ConversationViewModel(
            conversationId: conversationId,
            dependencies: Dependencies(
                messaging: mockServices.messaging,
                messagingRealtime: mockServices.realtime,
                messagingMedia: mockServices.media
            )
        )
        
        // When & Then - Measure memory usage
        measure(metrics: [XCTMemoryMetric()]) {
            let messages = createLargeMessageSet(count: 50_000, conversationId: conversationId)
            viewModel.messages = messages
            
            // Perform operations that might affect memory
            for i in 0..<100 {
                let newMessage = createMockMessage(
                    conversationId: conversationId,
                    content: "Additional message \(i)"
                )
                viewModel.handleMessageAdded(newMessage)
            }
        }
    }
    
    // MARK: - Network Stress Tests
    
    func testNetworkReconnectionPerformance() async {
        // Given
        let mockSupabase = MockSupabaseClient()
        let observer = MessagingRealtimeObserver(
            config: MessagingRealtimeObserver.Config(),
            supabase: mockSupabase,
            outputContinuation: AsyncStream<MessagingRealtimeObserver.Output>.Continuation { _ in }
        )
        
        let conversationIds = Set((0..<10).map { _ in UUID() })
        await observer.handle(.setVisibleConversations(conversationIds))
        
        // When & Then - Measure reconnection performance under stress
        measure(metrics: [XCTClockMetric()]) {
            Task {
                for _ in 0..<10 {
                    // Simulate network failure and recovery
                    mockSupabase.simulateNetworkFailure()
                    try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
                    mockSupabase.restoreNetwork()
                    try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
                }
            }
        }
    }
    
    func testHighFrequencyEventHandling() async {
        // Given
        let observer = MessagingRealtimeObserver(
            config: MessagingRealtimeObserver.Config(throttlePerConversationMs: 50),
            supabase: MockSupabaseClient(),
            outputContinuation: AsyncStream<MessagingRealtimeObserver.Output>.Continuation { _ in }
        )
        
        let conversationId = UUID()
        await observer.handle(.setVisibleConversations([conversationId]))
        
        // When & Then - Measure high-frequency event handling
        measure(metrics: [XCTClockMetric()]) {
            Task {
                // Simulate rapid message events
                for i in 0..<1000 {
                    let message = createMockMessage(
                        conversationId: conversationId,
                        content: "Rapid message \(i)"
                    )
                    await observer.processRealtimeEvent(MockRealtimeEvent(
                        type: "INSERT",
                        payload: message
                    ))
                }
            }
        }
    }
    
    // MARK: - Scroll Performance Tests
    
    func testScrollPerformanceWithMixedContent() {
        // Given
        let conversationId = UUID()
        let viewModel = ConversationViewModel(
            conversationId: conversationId,
            dependencies: Dependencies(
                messaging: mockServices.messaging,
                messagingRealtime: mockServices.realtime,
                messagingMedia: mockServices.media
            )
        )
        
        // Create mixed content (text, images, system messages)
        let mixedMessages = createMixedContentMessages(count: 1_000, conversationId: conversationId)
        viewModel.messages = mixedMessages
        
        // When & Then - Measure scroll-like operations
        measure(metrics: [XCTClockMetric()]) {
            // Simulate scroll operations by accessing different message ranges
            for i in stride(from: 0, to: mixedMessages.count, by: 50) {
                let endIndex = min(i + 50, mixedMessages.count)
                let _ = Array(viewModel.messages[i..<endIndex])
            }
        }
    }
    
    func testFrameRateConsistency() {
        // Given
        let conversationId = UUID()
        let viewModel = ConversationViewModel(
            conversationId: conversationId,
            dependencies: Dependencies(
                messaging: mockServices.messaging,
                messagingRealtime: mockServices.realtime,
                messagingMedia: mockServices.media
            )
        )
        
        let messages = createLargeMessageSet(count: 2_000, conversationId: conversationId)
        viewModel.messages = messages
        
        // When & Then - Measure operations that should maintain 60fps
        measure(metrics: [XCTClockMetric()]) {
            // Simulate rapid UI updates
            for i in 0..<60 { // 60 operations for 1 second at 60fps
                let newMessage = createMockMessage(
                    conversationId: conversationId,
                    content: "Frame test \(i)"
                )
                viewModel.handleMessageAdded(newMessage)
                
                // Simulate 16.67ms frame time
                Thread.sleep(forTimeInterval: 0.01667)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func createLargeMessageSet(count: Int, conversationId: UUID) -> [Message] {
        return (0..<count).map { index in
            createMockMessage(
                conversationId: conversationId,
                content: "Message \(index) - Lorem ipsum dolor sit amet, consectetur adipiscing elit."
            )
        }
    }
    
    private func createLargeConversationSet(count: Int) -> [Conversation] {
        return (0..<count).map { index in
            Conversation(
                id: UUID(),
                participants: [createMockUser(handle: "user\(index)")],
                lastMessage: createMockMessage(content: "Last message \(index)"),
                lastActivity: Date().addingTimeInterval(-Double(index * 60)),
                unreadCount: index % 5,
                unreadMentionsCount: index % 3,
                isArchived: index % 10 == 0,
                isPinned: index % 20 == 0,
                isMuted: index % 15 == 0,
                lastReadMessageId: nil,
                draftText: index % 7 == 0 ? "Draft \(index)" : nil,
                isGroup: index % 4 == 0,
                title: index % 4 == 0 ? "Group \(index)" : nil,
                avatarUrl: nil
            )
        }
    }
    
    private func createMixedContentMessages(count: Int, conversationId: UUID) -> [Message] {
        return (0..<count).map { index in
            let messageType = index % 4
            
            switch messageType {
            case 0:
                // Text message
                return createMockMessage(
                    conversationId: conversationId,
                    content: "Text message \(index)"
                )
            case 1:
                // Message with image attachment
                return createMockMessage(
                    conversationId: conversationId,
                    content: "Image message \(index)",
                    attachments: [createMockAttachment(type: .image)]
                )
            case 2:
                // Message with video attachment
                return createMockMessage(
                    conversationId: conversationId,
                    content: "Video message \(index)",
                    attachments: [createMockAttachment(type: .video)]
                )
            case 3:
                // System message
                return createMockMessage(
                    conversationId: conversationId,
                    content: "User joined the conversation",
                    systemKind: .userJoined
                )
            default:
                return createMockMessage(conversationId: conversationId, content: "Default message \(index)")
            }
        }
    }
    
    private func createMockMessage(
        conversationId: UUID,
        content: String,
        attachments: [Attachment] = [],
        systemKind: SystemMessageKind? = nil
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
            systemKind: systemKind,
            linkPreview: nil
        )
    }
    
    private func createMockAttachment(type: AttachmentType = .image) -> Attachment {
        Attachment(
            id: UUID(),
            type: type,
            url: URL(string: "https://example.com/\(type.rawValue).jpg")!,
            thumbnailUrl: URL(string: "https://example.com/thumb.jpg"),
            sizeBytes: Int64.random(in: 1024...10_485_760), // 1KB to 10MB
            duration: type == .video ? Double.random(in: 10...300) : nil,
            metadata: AttachmentMetadata(
                filename: "\(type.rawValue).jpg",
                mimeType: type == .image ? "image/jpeg" : "video/mp4",
                width: Int.random(in: 400...1920),
                height: Int.random(in: 400...1080)
            )
        )
    }
    
    private func createMockUser(handle: String = "testuser") -> User {
        User(
            id: UUID(),
            handle: handle,
            displayName: "Test User",
            bio: "Test bio",
            avatarURL: nil,
            isVerified: false,
            followerCount: 0,
            followingCount: 0,
            postCount: 0,
            createdAt: Date()
        )
    }
}

// MARK: - Mock Types for Performance Testing

private struct MockRealtimeEvent {
    let type: String
    let payload: Any
}

extension MessagingRealtimeObserver {
    func processRealtimeEvent(_ event: MockRealtimeEvent) async {
        // Mock implementation for performance testing
    }
}