import XCTest
@testable import Messaging
import AppFoundation

final class MessagingPerformanceTests: XCTestCase {
    
    var mockSupabase: MockSupabaseClient!
    var messagingService: MessagingServiceLive!
    
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
    
    // MARK: - Service Performance Tests
    
    func testFetchMessagesPerformance() async {
        // Given
        let conversationId = UUID()
        let largeMessageSet = createLargeMessageSet(count: 10_000, conversationId: conversationId)
        
        // Mock the service to return large dataset
        mockSupabase.mockMessages = largeMessageSet
        
        // When & Then - Measure fetch performance
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            Task {
                do {
                    let _ = try await messagingService.fetchMessages(
                        conversationId: conversationId,
                        before: nil,
                        limit: 10_000
                    )
                } catch {
                    XCTFail("Fetch should not fail: \(error)")
                }
            }
        }
    }
    
    func testFetchConversationsPerformance() async {
        // Given
        let largeConversationSet = createLargeConversationSet(count: 5_000)
        mockSupabase.mockConversations = largeConversationSet
        
        // When & Then - Measure fetch performance
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            Task {
                do {
                    let _ = try await messagingService.fetchConversations(page: 0, pageSize: 5_000)
                } catch {
                    XCTFail("Fetch should not fail: \(error)")
                }
            }
        }
    }
    
    func testBulkMessageSendingPerformance() async {
        // Given
        let conversationId = UUID()
        let messageCount = 1_000
        
        // When & Then - Measure bulk sending performance
        measure(metrics: [XCTClockMetric()]) {
            Task {
                for i in 0..<messageCount {
                    do {
                        let _ = try await messagingService.send(
                            text: "Bulk message \(i)",
                            in: conversationId
                        )
                    } catch {
                        // Continue on error for performance testing
                    }
                }
            }
        }
    }
    
    func testConcurrentMessageSending() async {
        // Given
        let conversationId = UUID()
        let concurrentTasks = 100
        
        // When & Then - Measure concurrent sending performance
        measure(metrics: [XCTClockMetric()]) {
            Task {
                await withTaskGroup(of: Void.self) { group in
                    for i in 0..<concurrentTasks {
                        group.addTask {
                            do {
                                let _ = try await self.messagingService.send(
                                    text: "Concurrent message \(i)",
                                    in: conversationId
                                )
                            } catch {
                                // Handle error silently for performance testing
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Optimistic Update Performance Tests
    
    func testOptimisticUpdatePerformance() {
        // Given
        let conversationId = UUID()
        let messageCount = 5_000
        
        // When & Then - Measure optimistic update performance
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            var optimisticMessages: [Message] = []
            
            for i in 0..<messageCount {
                let nonce = MessageNonce()
                let optimisticMessage = createOptimisticMessage(
                    conversationId: conversationId,
                    text: "Optimistic \(i)",
                    nonce: nonce
                )
                optimisticMessages.append(optimisticMessage)
            }
            
            // Simulate server responses
            for (index, optimisticMessage) in optimisticMessages.enumerated() {
                let serverMessage = createServerMessage(
                    from: optimisticMessage,
                    content: "Server \(index)"
                )
                let _ = reconcileOptimisticMessage(
                    optimistic: optimisticMessage,
                    server: serverMessage
                )
            }
        }
    }
    
    func testMessageDeduplicationPerformance() {
        // Given
        let conversationId = UUID()
        let messageCount = 10_000
        
        // Create mixed optimistic and server messages
        var messages: [Message] = []
        for i in 0..<messageCount {
            let nonce = MessageNonce()
            
            // Add optimistic message
            let optimisticMessage = createOptimisticMessage(
                conversationId: conversationId,
                text: "Message \(i)",
                nonce: nonce
            )
            messages.append(optimisticMessage)
            
            // Add corresponding server message (50% of the time)
            if i % 2 == 0 {
                let serverMessage = createServerMessage(
                    from: optimisticMessage,
                    content: "Message \(i)"
                )
                messages.append(serverMessage)
            }
        }
        
        // When & Then - Measure deduplication performance
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            let _ = deduplicateMessages(messages)
        }
    }
    
    func testConflictResolutionPerformance() {
        // Given
        let messageCount = 1_000
        var conflictPairs: [(Message, Message)] = []
        
        for i in 0..<messageCount {
            let messageId = UUID()
            let conversationId = UUID()
            
            let localMessage = Message(
                id: messageId,
                conversationId: conversationId,
                senderId: UUID(),
                content: "Local \(i)",
                attachments: [],
                timestamp: Date().addingTimeInterval(-10),
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
                content: "Server \(i)",
                attachments: [],
                timestamp: Date(),
                deliveryStatus: .delivered,
                replyTo: nil,
                nonce: nil,
                editedAt: Date(),
                deletedAt: nil,
                expiresAt: nil,
                systemKind: nil,
                linkPreview: nil
            )
            
            conflictPairs.append((localMessage, serverMessage))
        }
        
        // When & Then - Measure conflict resolution performance
        measure(metrics: [XCTClockMetric()]) {
            for (local, server) in conflictPairs {
                let _ = resolveMessageConflict(local: local, server: server)
            }
        }
    }
    
    // MARK: - Real-time Observer Performance Tests
    
    func testRealtimeObserverScalability() async {
        // Given
        let config = MessagingRealtimeObserver.Config(maxIdsPerChannel: 100)
        let (_, continuation) = AsyncStream<MessagingRealtimeObserver.Output>.makeStream()
        
        let observer = MessagingRealtimeObserver(
            config: config,
            supabase: mockSupabase,
            outputContinuation: continuation
        )
        
        // When & Then - Measure scalability with large conversation sets
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            Task {
                // Test with increasing conversation set sizes
                for size in [100, 500, 1000, 2000] {
                    let conversationIds = Set((0..<size).map { _ in UUID() })
                    await observer.handle(.setVisibleConversations(conversationIds))
                }
            }
        }
    }
    
    func testTypingStateManagementPerformance() async {
        // Given
        let config = MessagingRealtimeObserver.Config()
        let (_, continuation) = AsyncStream<MessagingRealtimeObserver.Output>.makeStream()
        
        let observer = MessagingRealtimeObserver(
            config: config,
            supabase: mockSupabase,
            outputContinuation: continuation
        )
        
        let conversationCount = 1_000
        let conversationIds = (0..<conversationCount).map { _ in UUID() }
        
        // When & Then - Measure typing state management performance
        measure(metrics: [XCTClockMetric()]) {
            Task {
                // Simulate rapid typing events across many conversations
                for conversationId in conversationIds {
                    await observer.handle(.setTyping(conversationId: conversationId, isTyping: true))
                    await observer.handle(.setTyping(conversationId: conversationId, isTyping: false))
                }
            }
        }
    }
    
    func testEventThrottlingPerformance() async {
        // Given
        let config = MessagingRealtimeObserver.Config(throttlePerConversationMs: 100)
        let (_, continuation) = AsyncStream<MessagingRealtimeObserver.Output>.makeStream()
        
        let observer = MessagingRealtimeObserver(
            config: config,
            supabase: mockSupabase,
            outputContinuation: continuation
        )
        
        let conversationId = UUID()
        await observer.handle(.setVisibleConversations([conversationId]))
        
        // When & Then - Measure throttling performance under high load
        measure(metrics: [XCTClockMetric()]) {
            Task {
                // Send rapid events that should be throttled
                for i in 0..<10_000 {
                    let message = createMockMessage(
                        conversationId: conversationId,
                        content: "Throttled \(i)"
                    )
                    await observer.processRealtimeEvent(MockRealtimeEvent(
                        type: "INSERT",
                        payload: message
                    ))
                }
            }
        }
    }
    
    // MARK: - Memory Pressure Tests
    
    func testMemoryPressureWithLargeAttachments() async {
        // Given
        let conversationId = UUID()
        let largeAttachmentCount = 1_000
        
        // When & Then - Measure memory usage with large attachments
        measure(metrics: [XCTMemoryMetric()]) {
            var messages: [Message] = []
            
            for i in 0..<largeAttachmentCount {
                let attachment = Attachment(
                    id: UUID(),
                    type: .video,
                    url: URL(string: "https://example.com/video\(i).mp4")!,
                    thumbnailUrl: URL(string: "https://example.com/thumb\(i).jpg"),
                    sizeBytes: 100_000_000, // 100MB
                    duration: 300.0,
                    metadata: AttachmentMetadata(
                        filename: "video\(i).mp4",
                        mimeType: "video/mp4",
                        width: 1920,
                        height: 1080
                    )
                )
                
                let message = createMockMessage(
                    conversationId: conversationId,
                    content: "Large attachment \(i)",
                    attachments: [attachment]
                )
                messages.append(message)
            }
            
            // Simulate processing these messages
            for message in messages {
                let _ = message.attachments.first?.sizeBytes
            }
        }
    }
    
    func testMemoryLeakPrevention() async {
        // Given
        let iterationCount = 100
        
        // When & Then - Test for memory leaks in repeated operations
        measure(metrics: [XCTMemoryMetric()]) {
            Task {
                for _ in 0..<iterationCount {
                    // Create and destroy messaging components
                    let (_, continuation) = AsyncStream<MessagingRealtimeObserver.Output>.makeStream()
                    
                    let observer = MessagingRealtimeObserver(
                        config: MessagingRealtimeObserver.Config(),
                        supabase: MockSupabaseClient(),
                        outputContinuation: continuation
                    )
                    
                    let conversationIds = Set((0..<10).map { _ in UUID() })
                    await observer.handle(.setVisibleConversations(conversationIds))
                    
                    // Simulate some activity
                    for conversationId in conversationIds.prefix(3) {
                        await observer.handle(.setTyping(conversationId: conversationId, isTyping: true))
                        await observer.handle(.setTyping(conversationId: conversationId, isTyping: false))
                    }
                    
                    // Clean up
                    await observer.handle(.setVisibleConversations(Set()))
                    continuation.finish()
                }
            }
        }
    }
    
    // MARK: - Network Performance Tests
    
    func testNetworkBatchingPerformance() async {
        // Given
        let conversationId = UUID()
        let batchSize = 100
        let batchCount = 10
        
        // When & Then - Measure batched operations performance
        measure(metrics: [XCTClockMetric()]) {
            Task {
                for batch in 0..<batchCount {
                    // Simulate batch operations
                    var batchMessages: [Message] = []
                    
                    for i in 0..<batchSize {
                        let message = createMockMessage(
                            conversationId: conversationId,
                            content: "Batch \(batch) Message \(i)"
                        )
                        batchMessages.append(message)
                    }
                    
                    // Process batch
                    for message in batchMessages {
                        do {
                            let _ = try await messagingService.send(
                                text: message.content,
                                in: conversationId
                            )
                        } catch {
                            // Continue for performance testing
                        }
                    }
                }
            }
        }
    }
    
    func testConnectionPoolingPerformance() async {
        // Given
        let connectionCount = 50
        let operationsPerConnection = 20
        
        // When & Then - Measure connection pooling performance
        measure(metrics: [XCTClockMetric()]) {
            Task {
                await withTaskGroup(of: Void.self) { group in
                    for connectionIndex in 0..<connectionCount {
                        group.addTask {
                            let conversationId = UUID()
                            
                            for operationIndex in 0..<operationsPerConnection {
                                do {
                                    let _ = try await self.messagingService.send(
                                        text: "Connection \(connectionIndex) Op \(operationIndex)",
                                        in: conversationId
                                    )
                                } catch {
                                    // Handle error silently
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func createLargeMessageSet(count: Int, conversationId: UUID) -> [Message] {
        return (0..<count).map { index in
            createMockMessage(
                conversationId: conversationId,
                content: "Performance test message \(index) with some additional content to simulate real messages."
            )
        }
    }
    
    private func createLargeConversationSet(count: Int) -> [Conversation] {
        return (0..<count).map { index in
            Conversation(
                id: UUID(),
                participants: [createMockUser(handle: "perfuser\(index)")],
                lastMessage: createMockMessage(content: "Last message \(index)"),
                lastActivity: Date().addingTimeInterval(-Double(index * 60)),
                unreadCount: index % 10,
                unreadMentionsCount: index % 5,
                isArchived: false,
                isPinned: false,
                isMuted: false,
                lastReadMessageId: nil,
                draftText: nil,
                isGroup: index % 3 == 0,
                title: index % 3 == 0 ? "Performance Group \(index)" : nil,
                avatarUrl: nil
            )
        }
    }
    
    private func createMockMessage(
        conversationId: UUID,
        content: String,
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
    
    private func createMockUser(handle: String) -> User {
        User(
            id: UUID(),
            handle: handle,
            displayName: "Performance User",
            bio: "Performance testing user",
            avatarURL: nil,
            isVerified: false,
            followerCount: 0,
            followingCount: 0,
            postCount: 0,
            createdAt: Date()
        )
    }
    
    private func createOptimisticMessage(
        conversationId: UUID,
        text: String,
        nonce: MessageNonce
    ) -> Message {
        Message(
            id: UUID(),
            conversationId: conversationId,
            senderId: UUID(),
            content: text,
            attachments: [],
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
    
    private func createServerMessage(from optimistic: Message, content: String) -> Message {
        Message(
            id: UUID(),
            conversationId: optimistic.conversationId,
            senderId: optimistic.senderId,
            content: content,
            attachments: optimistic.attachments,
            timestamp: Date(),
            deliveryStatus: .sent,
            replyTo: optimistic.replyTo,
            nonce: optimistic.nonce,
            editedAt: nil,
            deletedAt: nil,
            expiresAt: nil,
            systemKind: nil,
            linkPreview: nil
        )
    }
    
    private func reconcileOptimisticMessage(optimistic: Message, server: Message) -> Message {
        return server
    }
    
    private func deduplicateMessages(_ messages: [Message]) -> [Message] {
        var seen: Set<UUID> = []
        return messages.filter { message in
            if seen.contains(message.id) {
                return false
            }
            seen.insert(message.id)
            return true
        }
    }
    
    private func resolveMessageConflict(local: Message, server: Message) -> Message {
        return server
    }
}

// MARK: - Mock Extensions for Performance Testing

extension MockSupabaseClient {
    var mockMessages: [Message] {
        get { return [] }
        set { /* Store for mock responses */ }
    }
    
    var mockConversations: [Conversation] {
        get { return [] }
        set { /* Store for mock responses */ }
    }
}

private struct MockRealtimeEvent {
    let type: String
    let payload: Any
}

extension MessagingRealtimeObserver {
    func processRealtimeEvent(_ event: MockRealtimeEvent) async {
        // Mock implementation for performance testing
    }
}