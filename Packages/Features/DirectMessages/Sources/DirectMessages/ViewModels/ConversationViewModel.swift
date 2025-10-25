import SwiftUI
import AppFoundation
import Analytics

/// ViewModel for individual conversation view
@Observable
@MainActor
public class ConversationViewModel {
    let conversationId: UUID
    
    // MARK: - State
    
    /// Messages in the conversation, ordered chronologically
    var messages: [Message] = []
    
    /// Whether messages are currently being loaded
    var isLoadingMessages = false
    
    /// Whether older messages are being loaded (pagination)
    var isLoadingOlderMessages = false
    
    /// Current conversation details
    var conversation: Conversation?
    
    /// Typing indicators from other users
    var typingUsers: Set<UUID> = []
    
    /// Current draft message being composed
    var currentDraft: OutboundMessageDraft?
    
    /// Error message to display
    var errorMessage: String?
    
    /// Whether we've reached the end of message history
    var hasReachedEnd = false
    
    // MARK: - Dependencies
    
    private let messagingService: MessagingServiceProtocol
    private let messagingRealtime: MessagingRealtimeProtocol
    private let messagingMedia: MessagingMediaProtocol
    private let eventTracker: EventTracker?
    
    // MARK: - Private State
    
    private var realtimeSubscription: MessagingSubscription?
    private var optimisticMessages: [MessageNonce: Message] = [:]
    private let messagesPerPage = 30
    
    // MARK: - Initialization
    
    public init(
        conversationId: UUID,
        messagingService: MessagingServiceProtocol? = nil,
        messagingRealtime: MessagingRealtimeProtocol? = nil,
        messagingMedia: MessagingMediaProtocol? = nil,
        eventTracker: EventTracker? = nil
    ) {
        self.conversationId = conversationId
        
        // Use provided services or get from dependencies
        if let messagingService = messagingService {
            self.messagingService = messagingService
        } else {
            // TODO: Get from Dependencies when available
            self.messagingService = NoOpMessagingService()
        }
        
        if let messagingRealtime = messagingRealtime {
            self.messagingRealtime = messagingRealtime
        } else {
            // TODO: Get from Dependencies when available
            self.messagingRealtime = NoOpMessagingRealtimeService()
        }
        
        if let messagingMedia = messagingMedia {
            self.messagingMedia = messagingMedia
        } else {
            // TODO: Get from Dependencies when available
            self.messagingMedia = NoOpMessagingMediaService()
        }
        
        self.eventTracker = eventTracker
    }
    
    deinit {
        // Note: Cannot call async cancel() in deinit.
        // The subscription will be cleaned up when the view model is deallocated.
        // For proper cleanup, call stopRealtime() before the view model is released.
    }
    
    // MARK: - Public Methods
    
    /// Loads initial messages and sets up real-time subscription
    func loadMessages() async {
        guard !isLoadingMessages else { return }
        
        isLoadingMessages = true
        errorMessage = nil
        
        do {
            // Load initial messages
            let fetchedMessages = try await messagingService.fetchMessages(
                conversationId: conversationId,
                before: nil,
                limit: messagesPerPage
            )
            
            await MainActor.run {
                self.messages = fetchedMessages.sorted { $0.timestamp < $1.timestamp }
                self.hasReachedEnd = fetchedMessages.count < messagesPerPage
                self.isLoadingMessages = false
            }
            
            // Set up real-time subscription
            await setupRealtimeSubscription()
            
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoadingMessages = false
            }
        }
    }
    
    /// Loads older messages for pagination
    func loadOlderMessages() async {
        guard !isLoadingOlderMessages && !hasReachedEnd && !messages.isEmpty else { return }
        
        isLoadingOlderMessages = true
        
        do {
            let oldestMessage = messages.first
            let fetchedMessages = try await messagingService.fetchMessages(
                conversationId: conversationId,
                before: oldestMessage?.timestamp,
                limit: messagesPerPage
            )
            
            await MainActor.run {
                let newMessages = fetchedMessages.sorted { $0.timestamp < $1.timestamp }
                self.messages = newMessages + self.messages
                self.hasReachedEnd = fetchedMessages.count < messagesPerPage
                self.isLoadingOlderMessages = false
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoadingOlderMessages = false
            }
        }
    }
    
    /// Sends a message with text and/or attachments
    func sendMessage(_ text: String, attachments: [Attachment] = []) async {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty || !attachments.isEmpty else { return }
        
        // Track message send analytics
        await eventTracker?.track(.dmSend(
            hasMedia: !attachments.isEmpty,
            characterCount: trimmedText.count
        ))
        
        let nonce = MessageNonce()
        let optimisticMessage = Message(
            id: UUID(), // Temporary ID
            conversationId: conversationId,
            senderId: UUID(), // TODO: Get current user ID
            content: trimmedText,
            attachments: attachments,
            timestamp: Date(),
            deliveryStatus: .sending,
            nonce: nonce
        )
        
        // Add optimistic message
        await MainActor.run {
            self.messages.append(optimisticMessage)
            self.optimisticMessages[nonce] = optimisticMessage
        }
        
        do {
            let sentMessage: Message
            
            if !attachments.isEmpty {
                // Send with attachments (send first attachment for now)
                sentMessage = try await messagingService.send(attachment: attachments.first!, in: conversationId)
            } else {
                // Send text only
                sentMessage = try await messagingService.send(text: trimmedText, in: conversationId)
            }
            
            // Replace optimistic message with server response
            await MainActor.run {
                self.updateOptimisticMessage(nonce: nonce, with: sentMessage)
            }
            
        } catch {
            // Mark optimistic message as failed
            await MainActor.run {
                self.markOptimisticMessageAsFailed(nonce: nonce, error: error)
            }
        }
    }
    
    /// Sends a text message with optimistic updates (legacy method)
    func sendMessage(_ text: String) async {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let nonce = MessageNonce()
        let optimisticMessage = Message(
            id: UUID(), // Temporary ID
            conversationId: conversationId,
            senderId: UUID(), // TODO: Get current user ID
            content: text,
            timestamp: Date(),
            deliveryStatus: .sending,
            nonce: nonce
        )
        
        // Add optimistic message
        await MainActor.run {
            self.messages.append(optimisticMessage)
            self.optimisticMessages[nonce] = optimisticMessage
        }
        
        do {
            let sentMessage = try await messagingService.send(text: text, in: conversationId)
            
            // Replace optimistic message with server response
            await MainActor.run {
                self.updateOptimisticMessage(nonce: nonce, with: sentMessage)
            }
            
        } catch {
            // Mark optimistic message as failed
            await MainActor.run {
                self.markOptimisticMessageAsFailed(nonce: nonce, error: error)
            }
        }
    }
    
    /// Sends a message with media attachment
    func sendMessage(with attachment: Attachment) async {
        let nonce = MessageNonce()
        let optimisticMessage = Message(
            id: UUID(), // Temporary ID
            conversationId: conversationId,
            senderId: UUID(), // TODO: Get current user ID
            content: "",
            attachments: [attachment],
            timestamp: Date(),
            deliveryStatus: .sending,
            nonce: nonce
        )
        
        // Add optimistic message
        await MainActor.run {
            self.messages.append(optimisticMessage)
            self.optimisticMessages[nonce] = optimisticMessage
        }
        
        do {
            let sentMessage = try await messagingService.send(attachment: attachment, in: conversationId)
            
            // Replace optimistic message with server response
            await MainActor.run {
                self.updateOptimisticMessage(nonce: nonce, with: sentMessage)
            }
            
        } catch {
            // Mark optimistic message as failed
            await MainActor.run {
                self.markOptimisticMessageAsFailed(nonce: nonce, error: error)
            }
        }
    }
    
    /// Sets typing status for current user
    func setTyping(_ isTyping: Bool) async {
        await messagingRealtime.setTyping(conversationId: conversationId, isTyping: isTyping)
        
        // Track typing analytics
        if isTyping {
            await eventTracker?.track(.dmTypingStart(conversationId: conversationId.uuidString))
        } else {
            await eventTracker?.track(.dmTypingStop(conversationId: conversationId.uuidString))
        }
    }
    
    /// Retries sending a failed message
    func retryMessage(_ message: Message) async {
        guard message.deliveryStatus == .failed else { return }
        
        if !message.attachments.isEmpty {
            await sendMessage(with: message.attachments.first!)
        } else {
            await sendMessage(message.content)
        }
        
        // Remove the failed message
        await MainActor.run {
            self.messages.removeAll { $0.id == message.id }
        }
    }
    
    /// Track that a conversation was opened
    func trackConversationOpened() {
        Task {
            await eventTracker?.track(.dmOpenConversation(conversationId: conversationId.uuidString))
        }
    }
    
    // MARK: - Computed Properties
    
    /// Title for the conversation navigation bar
    var conversationTitle: String {
        if let conversation = conversation {
            if conversation.isGroup {
                return conversation.title ?? "Group Chat"
            } else {
                // For 1:1 chats, show the other participant's name
                // TODO: Get current user ID and filter participants
                return conversation.participants.first?.handle ?? "Chat"
            }
        }
        return "Chat"
    }
    
    /// Whether any users are currently typing
    var isAnyoneTyping: Bool {
        !typingUsers.isEmpty
    }
    
    /// Formatted typing indicator text
    var typingIndicatorText: String {
        let typingCount = typingUsers.count
        if typingCount == 0 {
            return ""
        } else if typingCount == 1 {
            return "Someone is typing..."
        } else if typingCount == 2 {
            return "2 people are typing..."
        } else {
            return "\(typingCount) people are typing..."
        }
    }
    
    // MARK: - Private Methods
    
    /// Sets up real-time subscription for the conversation
    private func setupRealtimeSubscription() async {
        do {
            realtimeSubscription = try await messagingRealtime.subscribe(conversationId: conversationId)
            
            // Listen for real-time events
            Task {
                for await event in messagingRealtime.events {
                    await handleRealtimeEvent(event)
                }
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to connect to real-time messaging: \(error.localizedDescription)"
            }
        }
    }
    
    /// Handles incoming real-time events
    private func handleRealtimeEvent(_ event: MessagingEvent) async {
        switch event {
        case .messageAdded(let message):
            guard message.conversationId == conversationId else { return }
            
            await MainActor.run {
                // Check if this is a duplicate of an optimistic message
                if let nonce = message.nonce,
                   let optimisticMessage = self.optimisticMessages[nonce] {
                    // Replace optimistic message with server version
                    if let index = self.messages.firstIndex(where: { $0.nonce == nonce }) {
                        self.messages[index] = message
                    }
                    self.optimisticMessages.removeValue(forKey: nonce)
                } else {
                    // Add new message if not already present (deduplication by ID)
                    if !self.messages.contains(where: { $0.id == message.id }) {
                        self.insertMessageInOrder(message)
                        
                        // Add smooth animation for new message arrival
                        withAnimation(.easeOut(duration: 0.3)) {
                            // Animation will be handled by the view layer
                        }
                    }
                }
            }
            
        case .messageUpdated(let message):
            guard message.conversationId == conversationId else { return }
            
            await MainActor.run {
                if let index = self.messages.firstIndex(where: { $0.id == message.id }) {
                    let oldMessage = self.messages[index]
                    self.messages[index] = message
                    
                    // Handle delivery status progression
                    if oldMessage.deliveryStatus != message.deliveryStatus {
                        self.handleDeliveryStatusUpdate(from: oldMessage.deliveryStatus, to: message.deliveryStatus)
                    }
                }
            }
            
        case .messageDeleted(let messageId, let conversationId):
            guard conversationId == self.conversationId else { return }
            
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.2)) {
                    self.messages.removeAll { $0.id == messageId }
                }
            }
            
        case .typing(let conversationId, let userId, let isTyping):
            guard conversationId == self.conversationId else { return }
            
            await MainActor.run {
                if isTyping {
                    self.typingUsers.insert(userId)
                } else {
                    self.typingUsers.remove(userId)
                }
            }
            
        case .readReceipt(let conversationId, let messageId, let userId):
            guard conversationId == self.conversationId else { return }
            
            await MainActor.run {
                // Update message delivery status to read
                if let index = self.messages.firstIndex(where: { $0.id == messageId }) {
                    var updatedMessage = self.messages[index]
                    
                    // Create updated message with read status
                    updatedMessage = Message(
                        id: updatedMessage.id,
                        conversationId: updatedMessage.conversationId,
                        senderId: updatedMessage.senderId,
                        content: updatedMessage.content,
                        attachments: updatedMessage.attachments,
                        timestamp: updatedMessage.timestamp,
                        deliveryStatus: .read,
                        replyTo: updatedMessage.replyTo,
                        nonce: updatedMessage.nonce,
                        editedAt: updatedMessage.editedAt,
                        deletedAt: updatedMessage.deletedAt,
                        expiresAt: updatedMessage.expiresAt,
                        systemKind: updatedMessage.systemKind,
                        linkPreview: updatedMessage.linkPreview
                    )
                    
                    self.messages[index] = updatedMessage
                }
            }
            
        case .conversationUpdated(let conversation):
            guard conversation.id == conversationId else { return }
            
            await MainActor.run {
                self.conversation = conversation
            }
        }
    }
    
    /// Inserts a message in chronological order
    private func insertMessageInOrder(_ message: Message) {
        let insertIndex = messages.firstIndex { $0.timestamp > message.timestamp } ?? messages.count
        messages.insert(message, at: insertIndex)
    }
    
    /// Handles delivery status progression with appropriate feedback
    private func handleDeliveryStatusUpdate(from oldStatus: DeliveryStatus, to newStatus: DeliveryStatus) {
        // Provide subtle haptic feedback for status changes
        switch (oldStatus, newStatus) {
        case (.sending, .sent):
            // Message successfully sent to server
            break
        case (.sent, .delivered):
            // Message delivered to recipient's device
            break
        case (.delivered, .read):
            // Message read by recipient - could provide subtle feedback
            break
        case (_, .failed):
            // Message failed - could show error state
            break
        default:
            break
        }
    }
    
    /// Updates optimistic message with server response, handling nonce deduplication
    private func updateOptimisticMessage(nonce: MessageNonce, with serverMessage: Message) {
        guard let index = messages.firstIndex(where: { $0.nonce == nonce }) else { return }
        
        // Replace optimistic message with server version
        messages[index] = serverMessage
        optimisticMessages.removeValue(forKey: nonce)
    }
    
    /// Marks an optimistic message as failed
    private func markOptimisticMessageAsFailed(nonce: MessageNonce, error: Error) {
        guard let index = messages.firstIndex(where: { $0.nonce == nonce }) else { return }
        
        var failedMessage = messages[index]
        failedMessage = Message(
            id: failedMessage.id,
            conversationId: failedMessage.conversationId,
            senderId: failedMessage.senderId,
            content: failedMessage.content,
            attachments: failedMessage.attachments,
            timestamp: failedMessage.timestamp,
            deliveryStatus: .failed,
            replyTo: failedMessage.replyTo,
            nonce: failedMessage.nonce,
            editedAt: failedMessage.editedAt,
            deletedAt: failedMessage.deletedAt,
            expiresAt: failedMessage.expiresAt,
            systemKind: failedMessage.systemKind,
            linkPreview: failedMessage.linkPreview
        )
        
        messages[index] = failedMessage
        self.errorMessage = error.localizedDescription
    }
}