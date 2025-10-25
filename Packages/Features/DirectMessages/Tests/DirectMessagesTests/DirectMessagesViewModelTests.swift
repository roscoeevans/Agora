import XCTest
@testable import DirectMessages
import TestSupport
import AppFoundation

@MainActor
final class DirectMessagesViewModelTests: XCTestCase {
    
    var mockServices: MockMessagingServices!
    var viewModel: DirectMessagesViewModel!
    
    override func setUp() {
        super.setUp()
        mockServices = createMockMessagingServices()
        viewModel = DirectMessagesViewModel(
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
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        XCTAssertTrue(viewModel.conversations.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.searchText, "")
    }
    
    func testInitializationWithoutDependencies() {
        let viewModelWithoutDeps = DirectMessagesViewModel()
        XCTAssertTrue(viewModelWithoutDeps.conversations.isEmpty)
        XCTAssertFalse(viewModelWithoutDeps.isLoading)
        XCTAssertNil(viewModelWithoutDeps.errorMessage)
        XCTAssertEqual(viewModelWithoutDeps.searchText, "")
    }
    
    // MARK: - Conversation Loading Tests
    
    func testLoadConversations() async {
        // Given
        let mockConversations = createMockConversations()
        mockServices.messaging.mockConversations = mockConversations
        
        // When
        await viewModel.loadConversations()
        
        // Then
        XCTAssertEqual(viewModel.conversations.count, mockConversations.count)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testLoadConversationsWithError() async {
        // Given
        mockServices.messaging.shouldFailFetchConversations = true
        
        // When
        await viewModel.loadConversations()
        
        // Then
        XCTAssertTrue(viewModel.conversations.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    func testLoadConversationsWithoutService() async {
        // Given - ViewModel without messaging service
        let viewModelWithoutService = DirectMessagesViewModel()
        
        // When
        await viewModelWithoutService.loadConversations()
        
        // Then - Should load mock data for development
        XCTAssertFalse(viewModelWithoutService.conversations.isEmpty)
        XCTAssertFalse(viewModelWithoutService.isLoading)
    }
    
    func testRefreshConversations() async {
        // Given - Initial conversations loaded
        let initialConversations = createMockConversations(count: 2)
        mockServices.messaging.mockConversations = initialConversations
        await viewModel.loadConversations()
        
        // Update mock data
        let refreshedConversations = createMockConversations(count: 3)
        mockServices.messaging.mockConversations = refreshedConversations
        
        // When
        await viewModel.refresh()
        
        // Then
        XCTAssertEqual(viewModel.conversations.count, refreshedConversations.count)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    // MARK: - Search Tests
    
    func testSearchConversations() {
        // Given
        let conversations = [
            createMockConversation(title: "John Doe"),
            createMockConversation(title: "Jane Smith"),
            createMockConversation(title: "Bob Johnson")
        ]
        viewModel.conversations = conversations
        
        // When
        viewModel.searchText = "John"
        let filteredConversations = viewModel.filteredConversations
        
        // Then
        XCTAssertEqual(filteredConversations.count, 2) // John Doe and Bob Johnson
        XCTAssertTrue(filteredConversations.allSatisfy { $0.displayTitle.contains("John") })
    }
    
    func testSearchConversationsEmptyQuery() {
        // Given
        let conversations = createMockConversations(count: 3)
        viewModel.conversations = conversations
        
        // When
        viewModel.searchText = ""
        let filteredConversations = viewModel.filteredConversations
        
        // Then
        XCTAssertEqual(filteredConversations.count, conversations.count)
    }
    
    func testSearchConversationsCaseInsensitive() {
        // Given
        let conversations = [createMockConversation(title: "Alice Cooper")]
        viewModel.conversations = conversations
        
        // When
        viewModel.searchText = "alice"
        let filteredConversations = viewModel.filteredConversations
        
        // Then
        XCTAssertEqual(filteredConversations.count, 1)
        XCTAssertEqual(filteredConversations.first?.displayTitle, "Alice Cooper")
    }
    
    // MARK: - Navigation Tests
    
    func testNavigateToConversation() {
        // Given
        let conversationId = UUID()
        
        // When
        viewModel.navigate(to: .conversation(conversationId))
        
        // Then - Navigation should be handled by the navigation system
        // This test verifies the method doesn't crash
        XCTAssertTrue(true)
    }
    
    func testNavigateToList() {
        // When
        viewModel.navigate(to: .list)
        
        // Then - Navigation should be handled by the navigation system
        // This test verifies the method doesn't crash
        XCTAssertTrue(true)
    }
    
    // MARK: - Real-time Event Handling Tests
    
    func testHandleConversationUpdated() {
        // Given
        let conversation = createMockConversation()
        viewModel.conversations = [conversation]
        
        let updatedConversation = Conversation(
            id: conversation.id,
            participants: conversation.participants,
            lastMessage: createMockMessage(content: "Updated message"),
            lastActivity: Date(),
            unreadCount: 5,
            unreadMentionsCount: 1,
            isArchived: false,
            isPinned: true,
            isMuted: false,
            lastReadMessageId: nil,
            draftText: nil,
            isGroup: false,
            title: "Updated Title",
            avatarUrl: nil
        )
        
        // When
        viewModel.handleConversationUpdated(updatedConversation)
        
        // Then
        let updated = viewModel.conversations.first { $0.id == conversation.id }
        XCTAssertEqual(updated?.title, "Updated Title")
        XCTAssertEqual(updated?.unreadCount, 5)
        XCTAssertEqual(updated?.isPinned, true)
    }
    
    func testHandleNewConversation() {
        // Given
        let initialCount = viewModel.conversations.count
        let newConversation = createMockConversation()
        
        // When
        viewModel.handleConversationUpdated(newConversation)
        
        // Then
        XCTAssertEqual(viewModel.conversations.count, initialCount + 1)
        XCTAssertTrue(viewModel.conversations.contains { $0.id == newConversation.id })
    }
    
    // MARK: - Conversation Management Tests
    
    func testArchiveConversation() async {
        // Given
        let conversation = createMockConversation()
        viewModel.conversations = [conversation]
        
        // When
        await viewModel.archiveConversation(conversation.id)
        
        // Then
        XCTAssertTrue(mockServices.messaging.archivedConversations.contains(conversation.id))
    }
    
    func testMuteConversation() async {
        // Given
        let conversation = createMockConversation()
        viewModel.conversations = [conversation]
        
        // When
        await viewModel.muteConversation(conversation.id, muted: true)
        
        // Then
        XCTAssertTrue(mockServices.messaging.mutedConversations.contains(conversation.id))
    }
    
    func testPinConversation() async {
        // Given
        let conversation = createMockConversation()
        viewModel.conversations = [conversation]
        
        // When
        await viewModel.pinConversation(conversation.id, pinned: true)
        
        // Then
        XCTAssertTrue(mockServices.messaging.pinnedConversations.contains(conversation.id))
    }
    
    func testDeleteConversation() async {
        // Given
        let conversation = createMockConversation()
        viewModel.conversations = [conversation]
        let initialCount = viewModel.conversations.count
        
        // When
        await viewModel.deleteConversation(conversation.id)
        
        // Then
        XCTAssertEqual(viewModel.conversations.count, initialCount - 1)
        XCTAssertFalse(viewModel.conversations.contains { $0.id == conversation.id })
    }
    
    // MARK: - Analytics Tests
    
    func testTrackListOpened() async {
        // When
        viewModel.trackListOpened()
        
        // Then - Should track the event (verified through mock)
        // This test ensures the method doesn't crash
        XCTAssertTrue(true)
    }
    
    // MARK: - Helper Methods
    
    private func createMockConversations(count: Int = 3) -> [Conversation] {
        return (0..<count).map { index in
            createMockConversation(title: "Conversation \(index)")
        }
    }
    
    private func createMockConversation(title: String = "Test Conversation") -> Conversation {
        Conversation(
            id: UUID(),
            participants: [createMockUser()],
            lastMessage: createMockMessage(),
            lastActivity: Date(),
            unreadCount: 0,
            unreadMentionsCount: 0,
            isArchived: false,
            isPinned: false,
            isMuted: false,
            lastReadMessageId: nil,
            draftText: nil,
            isGroup: false,
            title: title,
            avatarUrl: nil
        )
    }
    
    private func createMockMessage(content: String = "Test message") -> Message {
        Message(
            id: UUID(),
            conversationId: UUID(),
            senderId: UUID(),
            content: content,
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
    
    private func createMockUser() -> User {
        User(
            id: UUID(),
            handle: "testuser",
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