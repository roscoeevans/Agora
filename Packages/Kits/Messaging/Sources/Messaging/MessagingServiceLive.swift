import Foundation
import AppFoundation
import Networking
import SupabaseKit

/// Production implementation of MessagingServiceProtocol
public final class MessagingServiceLive: MessagingServiceProtocol {
    
    private let networking: any AgoraAPIClient
    private let supabase: any SupabaseClientProtocol
    private let sessionStore: SessionStore
    
    public init(
        networking: any AgoraAPIClient,
        supabase: any SupabaseClientProtocol,
        sessionStore: SessionStore = SessionStore()
    ) {
        self.networking = networking
        self.supabase = supabase
        self.sessionStore = sessionStore
    }
    
    // MARK: - Conversation Management
    
    public func createConversation(participantIds: [UUID]) async throws -> Conversation {
        // Get current user
        let currentUser = try await sessionStore.getCurrentUser()
        guard let currentUserId = UUID(uuidString: currentUser.id) else {
            throw MessagingError.invalidUserId
        }
        
        // Create thread in database
        let threadId = UUID()
        let kind = participantIds.count > 1 ? "group" : "1:1"
        
        // Insert thread
        struct CreateThreadParams: Codable, Sendable {
            let threadId: String
            let kind: String
            let userIds: [String]
        }
        
        let allParticipantIds = [currentUserId] + participantIds
        let params = CreateThreadParams(
            threadId: threadId.uuidString,
            kind: kind,
            userIds: allParticipantIds.map { $0.uuidString }
        )
        
        // Call Supabase RPC to create thread and add participants atomically
        let result: [ConversationDB] = try await supabase.database.execute(
            "create_dm_thread",
            parameters: params
        )
        
        guard let conversationDB = result.first else {
            throw MessagingError.conversationCreationFailed
        }
        
        return conversationDB.toDomain()
    }
    
    public func leaveConversation(id: UUID) async throws {
        // In a real implementation, this would call the Supabase database
        // For now, this is a no-op
    }
    
    public func setMuted(_ muted: Bool, for id: UUID) async throws {
        // In a real implementation, this would update the database
        // For now, this is a no-op
    }
    
    public func setArchived(_ archived: Bool, for id: UUID) async throws {
        // In a real implementation, this would update the database
        // For now, this is a no-op
    }
    
    public func pin(_ pinned: Bool, for id: UUID) async throws {
        // In a real implementation, this would update the database
        // For now, this is a no-op
    }
    
    // MARK: - Data Fetching
    
    public func fetchConversations(page: Int, pageSize: Int) async throws -> [Conversation] {
        // Get current user
        let currentUser = try await sessionStore.getCurrentUser()
        guard let currentUserId = UUID(uuidString: currentUser.id) else {
            throw MessagingError.invalidUserId
        }
        
        // Fetch conversations for current user
        struct FetchConversationsParams: Codable, Sendable {
            let userId: String
            let limit: Int
            let offset: Int
        }
        
        let params = FetchConversationsParams(
            userId: currentUserId.uuidString,
            limit: pageSize,
            offset: page * pageSize
        )
        
        // Call Supabase RPC to fetch conversations with participants and last message
        let conversationsDB: [ConversationDB] = try await supabase.database.execute(
            "fetch_user_conversations",
            parameters: params
        )
        
        return conversationsDB.map { $0.toDomain() }
    }
    
    public func fetchMessages(conversationId: UUID, before: Date?, limit: Int) async throws -> [Message] {
        // Get current user (for auth check)
        let currentUser = try await sessionStore.getCurrentUser()
        guard let currentUserId = UUID(uuidString: currentUser.id) else {
            throw MessagingError.invalidUserId
        }
        
        // Fetch messages from database
        struct FetchMessagesParams: Codable, Sendable {
            let threadId: String
            let userId: String
            let beforeTimestamp: String?
            let limit: Int
        }
        
        let params = FetchMessagesParams(
            threadId: conversationId.uuidString,
            userId: currentUserId.uuidString,
            beforeTimestamp: before?.ISO8601Format(),
            limit: limit
        )
        
        // Call Supabase RPC to fetch messages
        let messagesDB: [DMMessageDB] = try await supabase.database.execute(
            "fetch_thread_messages",
            parameters: params
        )
        
        return messagesDB.map { $0.toDomain(conversationId: conversationId) }
    }
    
    // MARK: - Message Sending
    
    public func send(text: String, in conversationId: UUID) async throws -> Message {
        // Get current user
        let currentUser = try await sessionStore.getCurrentUser()
        guard let currentUserId = UUID(uuidString: currentUser.id) else {
            throw MessagingError.invalidUserId
        }
        
        let messageId = UUID()
        let now = Date()
        
        // Insert message into database
        struct SendMessageParams: Codable, Sendable {
            let messageId: String
            let threadId: String
            let authorId: String
            let text: String
        }
        
        let params = SendMessageParams(
            messageId: messageId.uuidString,
            threadId: conversationId.uuidString,
            authorId: currentUserId.uuidString,
            text: text
        )
        
        // Call Supabase RPC to insert message
        let result: [DMMessageDB] = try await supabase.database.execute(
            "send_dm_message",
            parameters: params
        )
        
        guard let messageDB = result.first else {
            throw MessagingError.sendMessageFailed
        }
        
        return messageDB.toDomain(conversationId: conversationId)
    }
    
    public func send(attachment: Attachment, in conversationId: UUID) async throws -> Message {
        // Get current user
        let currentUser = try await sessionStore.getCurrentUser()
        guard let currentUserId = UUID(uuidString: currentUser.id) else {
            throw MessagingError.invalidUserId
        }
        
        let messageId = UUID()
        
        // Upload attachment first (placeholder - implement media upload)
        // For MVP, we'll just send a text message with attachment metadata
        let attachmentText = "[Attachment: \(attachment.type.rawValue)]"
        
        // Insert message into database
        struct SendMessageWithAttachmentParams: Codable, Sendable {
            let messageId: String
            let threadId: String
            let authorId: String
            let text: String
            let mediaBundleId: String?
        }
        
        let params = SendMessageWithAttachmentParams(
            messageId: messageId.uuidString,
            threadId: conversationId.uuidString,
            authorId: currentUserId.uuidString,
            text: attachmentText,
            mediaBundleId: nil // TODO: Upload to media service and get ID
        )
        
        // Call Supabase RPC to insert message
        let result: [DMMessageDB] = try await supabase.database.execute(
            "send_dm_message",
            parameters: params
        )
        
        guard let messageDB = result.first else {
            throw MessagingError.sendMessageFailed
        }
        
        return messageDB.toDomain(conversationId: conversationId)
    }
    
    // MARK: - Message Status
    
    public func markDelivered(conversationId: UUID, messageId: UUID) async throws {
        // In a real implementation, this would update the database
        // For now, this is a no-op
    }
    
    public func markReadRange(conversationId: UUID, upTo messageId: UUID) async throws {
        // In a real implementation, this would update the database
        // For now, this is a no-op
    }
    
    // MARK: - Share Recipients
    
    public func recentDMRecipients(limit: Int) async throws -> [ShareRecipient] {
        // Get current user
        let currentUser = try await sessionStore.getCurrentUser()
        guard let currentUserId = UUID(uuidString: currentUser.id) else {
            throw MessagingError.invalidUserId
        }
        
        // Query for distinct peer users from recent conversations
        struct FetchRecentDMRecipientsParams: Codable, Sendable {
            let userId: String
            let limit: Int
        }
        
        let params = FetchRecentDMRecipientsParams(
            userId: currentUserId.uuidString,
            limit: limit
        )
        
        // Call Supabase RPC to fetch recent DM recipients
        struct RecipientRow: Codable, Sendable {
            let id: String
            let handle: String
            let displayName: String
            let avatarUrl: String?
        }
        
        let recipients: [RecipientRow] = try await supabase.database.execute(
            "fetch_recent_dm_recipients",
            parameters: params
        )
        
        return recipients.map { row in
            ShareRecipient(
                id: row.id,
                handle: row.handle,
                displayName: row.displayName,
                avatarURL: row.avatarUrl.flatMap { URL(string: $0) }
            )
        }
    }
    
    public func recentFollows(limit: Int) async throws -> [ShareRecipient] {
        // Get current user
        let currentUser = try await sessionStore.getCurrentUser()
        guard let currentUserId = UUID(uuidString: currentUser.id) else {
            throw MessagingError.invalidUserId
        }
        
        // Query for recent follows
        struct FetchRecentFollowsParams: Codable, Sendable {
            let userId: String
            let limit: Int
        }
        
        let params = FetchRecentFollowsParams(
            userId: currentUserId.uuidString,
            limit: limit
        )
        
        // Call Supabase RPC to fetch recent follows
        struct FollowRow: Codable, Sendable {
            let id: String
            let handle: String
            let displayName: String
            let avatarUrl: String?
        }
        
        let follows: [FollowRow] = try await supabase.database.execute(
            "fetch_recent_follows",
            parameters: params
        )
        
        return follows.map { row in
            ShareRecipient(
                id: row.id,
                handle: row.handle,
                displayName: row.displayName,
                avatarURL: row.avatarUrl.flatMap { URL(string: $0) }
            )
        }
    }
    
    public func autoSendDM(to recipientID: String, text: String) async throws {
        // Get current user
        let currentUser = try await sessionStore.getCurrentUser()
        guard let currentUserId = UUID(uuidString: currentUser.id) else {
            throw MessagingError.invalidUserId
        }
        
        guard let recipientUUID = UUID(uuidString: recipientID) else {
            throw MessagingError.invalidUserId
        }
        
        // Find or create 1:1 conversation with recipient
        struct FindOrCreateConversationParams: Codable, Sendable {
            let userId: String
            let recipientId: String
        }
        
        let findParams = FindOrCreateConversationParams(
            userId: currentUserId.uuidString,
            recipientId: recipientID
        )
        
        // Call Supabase RPC to find or create 1:1 conversation
        let conversations: [ConversationDB] = try await supabase.database.execute(
            "find_or_create_1to1_conversation",
            parameters: findParams
        )
        
        guard let conversation = conversations.first else {
            // Fallback: create new conversation
            let newConversation = try await createConversation(participantIds: [recipientUUID])
            // Send message in new conversation
            _ = try await send(text: text, in: newConversation.id)
            return
        }
        
        // Send message in existing conversation
        _ = try await send(text: text, in: conversation.thread.id)
    }
}