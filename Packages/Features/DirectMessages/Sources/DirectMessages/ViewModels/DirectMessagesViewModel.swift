import SwiftUI
import AppFoundation
import Analytics

/// ViewModel for the conversation list view
@Observable
@MainActor
public class DirectMessagesViewModel {
    // MARK: - State
    var conversations: [Conversation] = []
    var isLoading = false
    var errorMessage: String?
    var searchText = ""
    
    // MARK: - Dependencies
    @ObservationIgnored
    private let messagingService: MessagingServiceProtocol?
    @ObservationIgnored
    private let messagingRealtime: MessagingRealtimeProtocol?
    @ObservationIgnored
    private let eventTracker: EventTracker?
    
    // MARK: - Navigation
    @ObservationIgnored
    private var navigationPath = NavigationPath()
    
    public init(dependencies: Dependencies? = nil) {
        self.messagingService = dependencies?.messaging
        self.messagingRealtime = dependencies?.messagingRealtime
        self.eventTracker = dependencies?.eventTracker
    }
    
    // MARK: - Public Methods
    
    /// Track that the conversation list was opened
    func trackListOpened() {
        Task {
            await eventTracker?.track(.dmOpenList)
        }
    }
    
    /// Load conversations from the messaging service
    @MainActor
    func loadConversations() async {
        guard let messagingService = messagingService else {
            // For development/preview, use mock data
            await loadMockConversations()
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedConversations = try await messagingService.fetchConversations(page: 0, pageSize: 50)
            self.conversations = fetchedConversations.sorted { $0.lastActivity > $1.lastActivity }
            self.isLoading = false
        } catch {
            self.errorMessage = "Failed to load conversations: \(error.localizedDescription)"
            self.isLoading = false
        }
    }
    
    /// Refresh conversations (for pull-to-refresh)
    @MainActor
    func refresh() async {
        await loadConversations()
    }
    
    /// Navigate to a specific route
    func navigate(to route: DMsRoute) {
        // Navigation will be handled by the parent NavigationStack
        // This method can be extended for more complex navigation logic
        print("Navigating to: \(route)")
    }
    
    /// Filter conversations based on search text
    var filteredConversations: [Conversation] {
        if searchText.isEmpty {
            return conversations
        }
        
        return conversations.filter { conversation in
            // Search in conversation title or participant names
            if let title = conversation.title {
                return title.localizedCaseInsensitiveContains(searchText)
            }
            
            // For non-group conversations, search participant names
            return conversation.participants.contains { user in
                user.displayName.localizedCaseInsensitiveContains(searchText) ||
                user.handle.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    // MARK: - Real-time Subscriptions
    
    /// Subscribe to real-time conversation list updates
    @MainActor
    func subscribeToUpdates() async {
        guard let messagingRealtime = messagingRealtime else { return }
        
        do {
            _ = try await messagingRealtime.subscribeConversationList()
            
            // Handle real-time events
            for await event in messagingRealtime.events {
                await handleRealtimeEvent(event)
            }
        } catch {
            print("Failed to subscribe to conversation updates: \(error)")
        }
    }
    
    @MainActor
    private func handleRealtimeEvent(_ event: MessagingEvent) async {
        switch event {
        case .conversationUpdated(let updatedConversation):
            // Update or add conversation in the list
            if let index = conversations.firstIndex(where: { $0.id == updatedConversation.id }) {
                conversations[index] = updatedConversation
            } else {
                conversations.append(updatedConversation)
            }
            // Re-sort by last activity
            conversations.sort { $0.lastActivity > $1.lastActivity }
            
        case .messageAdded(let message):
            // Update the conversation's last message and activity
            if let index = conversations.firstIndex(where: { $0.id == message.conversationId }) {
                let updatedConversation = conversations[index]
                // Note: This is a simplified update. In a real implementation,
                // we'd need to properly update the conversation with the new message
                conversations[index] = updatedConversation
                conversations.sort { $0.lastActivity > $1.lastActivity }
            }
            
        default:
            // Handle other events as needed
            break
        }
    }
    
    // MARK: - Mock Data (for development)
    
    @MainActor
    private func loadMockConversations() async {
        self.conversations = [
                Conversation(
                    id: UUID(),
                    participants: [
                        User(id: UUID().uuidString, handle: "johndoe", displayHandle: "@johndoe", displayName: "John Doe", bio: nil, avatarUrl: nil, createdAt: Date())
                    ],
                    lastMessage: Message(
                        id: UUID(),
                        conversationId: UUID(),
                        senderId: UUID(),
                        content: "Hey, how's it going?",
                        attachments: [],
                        timestamp: Date().addingTimeInterval(-3600), // 1 hour ago
                        deliveryStatus: .delivered,
                        replyTo: nil,
                        nonce: nil,
                        editedAt: nil,
                        deletedAt: nil,
                        expiresAt: nil,
                        systemKind: nil,
                        linkPreview: nil
                    ),
                    lastActivity: Date().addingTimeInterval(-3600),
                    unreadCount: 2,
                    unreadMentionsCount: 0,
                    isArchived: false,
                    isPinned: false,
                    isMuted: false,
                    lastReadMessageId: nil,
                    draftText: nil,
                    isGroup: false,
                    title: nil,
                    avatarUrl: nil
                ),
                Conversation(
                    id: UUID(),
                    participants: [
                        User(id: UUID().uuidString, handle: "janesmith", displayHandle: "@janesmith", displayName: "Jane Smith", bio: nil, avatarUrl: nil, createdAt: Date())
                    ],
                    lastMessage: Message(
                        id: UUID(),
                        conversationId: UUID(),
                        senderId: UUID(),
                        content: "Thanks for the help earlier!",
                        attachments: [],
                        timestamp: Date().addingTimeInterval(-86400), // 1 day ago
                        deliveryStatus: .read,
                        replyTo: nil,
                        nonce: nil,
                        editedAt: nil,
                        deletedAt: nil,
                        expiresAt: nil,
                        systemKind: nil,
                        linkPreview: nil
                    ),
                    lastActivity: Date().addingTimeInterval(-86400),
                    unreadCount: 0,
                    unreadMentionsCount: 0,
                    isArchived: false,
                    isPinned: true,
                    isMuted: false,
                    lastReadMessageId: nil,
                    draftText: "I was thinking about...",
                    isGroup: false,
                    title: nil,
                    avatarUrl: nil
                ),
                Conversation(
                    id: UUID(),
                    participants: [
                        User(id: UUID().uuidString, handle: "teamchat", displayHandle: "@teamchat", displayName: "Team Chat", bio: nil, avatarUrl: nil, createdAt: Date()),
                        User(id: UUID().uuidString, handle: "alice", displayHandle: "@alice", displayName: "Alice", bio: nil, avatarUrl: nil, createdAt: Date()),
                        User(id: UUID().uuidString, handle: "bob", displayHandle: "@bob", displayName: "Bob", bio: nil, avatarUrl: nil, createdAt: Date())
                    ],
                    lastMessage: Message(
                        id: UUID(),
                        conversationId: UUID(),
                        senderId: UUID(),
                        content: "Meeting at 3 PM today",
                        attachments: [],
                        timestamp: Date().addingTimeInterval(-7200), // 2 hours ago
                        deliveryStatus: .delivered,
                        replyTo: nil,
                        nonce: nil,
                        editedAt: nil,
                        deletedAt: nil,
                        expiresAt: nil,
                        systemKind: nil,
                        linkPreview: nil
                    ),
                    lastActivity: Date().addingTimeInterval(-7200),
                    unreadCount: 5,
                    unreadMentionsCount: 1,
                    isArchived: false,
                    isPinned: false,
                    isMuted: false,
                    lastReadMessageId: nil,
                    draftText: nil,
                    isGroup: true,
                    title: "Team Chat",
                    avatarUrl: nil
                )
            ]
        self.isLoading = false
    }
}