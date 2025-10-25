import Foundation
import AppFoundation
import SupabaseKit

/// Actor-based real-time observer for messaging events
/// Manages Supabase subscriptions and lifecycle for efficient real-time messaging
public actor MessagingRealtimeObserver {
    
    // MARK: - Configuration
    
    public struct Config: Sendable {
        /// Maximum conversation IDs per subscription
        public let maxIdsPerChannel: Int
        /// Throttle time for per-conversation events in milliseconds
        public let throttlePerConversationMs: Int
        /// Debounce time for scroll events in milliseconds
        public let scrollDebounceMs: Int
        /// Keepalive interval for typing signals in seconds
        public let typingKeepaliveSeconds: TimeInterval
        /// Auto-stop timeout for typing signals in seconds
        public let typingAutoStopSeconds: TimeInterval
        
        public init(
            maxIdsPerChannel: Int = 100,
            throttlePerConversationMs: Int = 300,
            scrollDebounceMs: Int = 500,
            typingKeepaliveSeconds: TimeInterval = 3.0,
            typingAutoStopSeconds: TimeInterval = 4.0
        ) {
            self.maxIdsPerChannel = maxIdsPerChannel
            self.throttlePerConversationMs = throttlePerConversationMs
            self.scrollDebounceMs = scrollDebounceMs
            self.typingKeepaliveSeconds = typingKeepaliveSeconds
            self.typingAutoStopSeconds = typingAutoStopSeconds
        }
    }
    
    // MARK: - Input/Output Types
    
    public enum Input: Sendable {
        case setVisibleConversations(Set<UUID>)
        case setActiveThread(UUID?)
        case lifecycleForeground
        case lifecycleBackground
        case setTyping(conversationId: UUID, isTyping: Bool)
    }
    
    public enum Output: Sendable {
        case messageAdded(Message)
        case messageUpdated(Message)
        case messageDeleted(conversationId: UUID, messageId: UUID)
        case readReceipt(conversationId: UUID, messageId: UUID, userId: UUID)
        case conversationUpdated(Conversation)
        case typing(conversationId: UUID, userId: UUID, isTyping: Bool)
        case error(MessagingError)
    }
    
    // MARK: - Private State
    
    private let config: Config
    private let supabase: any SupabaseClientProtocol
    private let outputContinuation: AsyncStream<Output>.Continuation
    
    private var visibleConversations: Set<UUID> = []
    private var activeThread: UUID?
    private var isInForeground = true
    private var subscriptionTasks: [Task<Void, Never>] = []
    private var typingStates: [UUID: TypingState] = [:]
    private var lastThrottleTime: [UUID: Date] = [:]
    
    // MARK: - Typing State Management
    
    private struct TypingState {
        var isTyping: Bool
        var lastKeepAlive: Date
        var autoStopTask: Task<Void, Never>?
        
        init(isTyping: Bool) {
            self.isTyping = isTyping
            self.lastKeepAlive = Date()
            self.autoStopTask = nil
        }
    }
    
    // MARK: - Initialization
    
    public init(
        config: Config = Config(),
        supabase: any SupabaseClientProtocol
    ) {
        self.config = config
        self.supabase = supabase
        
        let (stream, continuation) = AsyncStream<Output>.makeStream()
        self.outputContinuation = continuation
        self.outputStream = stream
    }
    
    public let outputStream: AsyncStream<Output>
    
    // MARK: - Public Interface
    
    public func send(_ input: Input) {
        Task {
            await handleInput(input)
        }
    }
    
    // MARK: - Input Handling
    
    private func handleInput(_ input: Input) async {
        switch input {
        case .setVisibleConversations(let conversations):
            await setVisibleConversations(conversations)
            
        case .setActiveThread(let threadId):
            activeThread = threadId
            
        case .lifecycleForeground:
            isInForeground = true
            await reconnectSubscriptions()
            
        case .lifecycleBackground:
            isInForeground = false
            await cleanupTypingStates()
            
        case .setTyping(let conversationId, let isTyping):
            await handleTypingInput(conversationId: conversationId, isTyping: isTyping)
        }
    }
    
    // MARK: - Subscription Management
    
    private func setVisibleConversations(_ conversations: Set<UUID>) async {
        // Debounce rapid changes to visible conversations
        try? await Task.sleep(for: .milliseconds(config.scrollDebounceMs))
        
        guard visibleConversations != conversations else { return }
        
        visibleConversations = conversations
        await updateSubscriptions()
    }
    
    private func updateSubscriptions() async {
        // Cancel existing subscriptions
        for task in subscriptionTasks {
            task.cancel()
        }
        subscriptionTasks.removeAll()
        
        guard !visibleConversations.isEmpty else { return }
        
        // Create new subscriptions using the available SupabaseKit API
        // For now, we'll use a simplified approach that subscribes to general table changes
        let task = Task { [weak self] in
            guard let self = self else { return }
            
            // Subscribe to message changes - specify the type explicitly
            let messageStream: AsyncStream<RealtimeChange<Message>> = await self.supabase.realtime.subscribeToTable("messages", filter: nil)
            for await change in messageStream {
                await self.handleMessageTableChange(change)
            }
        }
        
        subscriptionTasks.append(task)
    }
    
    private func reconnectSubscriptions() async {
        guard isInForeground else { return }
        await updateSubscriptions()
    }
    
    // MARK: - Message Event Handling
    
    private func handleMessageTableChange(_ change: RealtimeChange<Message>) async {
        // This is a simplified implementation using the available SupabaseKit API
        // In a real implementation, we would need to properly decode the message data
        // and filter by conversation IDs
        
        // For now, we'll emit a placeholder event
        if change.eventType == "INSERT", let newRecord = change.newRecord {
            // Filter by visible conversations
            if visibleConversations.contains(newRecord.conversationId) {
                outputContinuation.yield(.messageAdded(newRecord))
            }
        } else if change.eventType == "UPDATE", let newRecord = change.newRecord {
            if visibleConversations.contains(newRecord.conversationId) {
                outputContinuation.yield(.messageUpdated(newRecord))
            }
        } else if change.eventType == "DELETE", let oldRecord = change.oldRecord {
            if visibleConversations.contains(oldRecord.conversationId) {
                outputContinuation.yield(.messageDeleted(conversationId: oldRecord.conversationId, messageId: oldRecord.id))
            }
        }
    }
    
    private func shouldThrottleMessage(for conversationId: UUID) async -> Bool {
        let now = Date()
        let throttleInterval = TimeInterval(config.throttlePerConversationMs) / 1000.0
        
        if let lastTime = lastThrottleTime[conversationId],
           now.timeIntervalSince(lastTime) < throttleInterval {
            return true
        }
        
        lastThrottleTime[conversationId] = now
        return false
    }
    
    // MARK: - Typing Management
    
    private func handleTypingInput(conversationId: UUID, isTyping: Bool) async {
        if isTyping {
            await startTyping(conversationId: conversationId)
        } else {
            await stopTyping(conversationId: conversationId)
        }
    }
    
    private func startTyping(conversationId: UUID) async {
        // Cancel existing auto-stop task
        typingStates[conversationId]?.autoStopTask?.cancel()
        
        // Create or update typing state
        let autoStopTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(self?.config.typingAutoStopSeconds ?? 4.0))
            await self?.stopTyping(conversationId: conversationId)
        }
        
        typingStates[conversationId] = TypingState(isTyping: true)
        typingStates[conversationId]?.autoStopTask = autoStopTask
        
        // Broadcast typing signal
        await broadcastTypingSignal(conversationId: conversationId, isTyping: true)
        
        // Schedule keepalive
        await scheduleTypingKeepalive(conversationId: conversationId)
    }
    
    private func stopTyping(conversationId: UUID) async {
        guard let state = typingStates[conversationId], state.isTyping else { return }
        
        // Cancel auto-stop task
        state.autoStopTask?.cancel()
        
        // Update state
        typingStates[conversationId]?.isTyping = false
        
        // Broadcast stop typing signal
        await broadcastTypingSignal(conversationId: conversationId, isTyping: false)
        
        // Clean up state after delay
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(1))
            await self?.cleanupTypingState(conversationId: conversationId)
        }
    }
    
    private func scheduleTypingKeepalive(conversationId: UUID) async {
        Task { [weak self] in
            guard let self = self else { return }
            
            try? await Task.sleep(for: .seconds(self.config.typingKeepaliveSeconds))
            
            let state = await self.typingStates[conversationId]
            if state?.isTyping == true {
                // Send keepalive signal
                await self.broadcastTypingSignal(conversationId: conversationId, isTyping: true)
                await self.scheduleTypingKeepalive(conversationId: conversationId)
            }
        }
    }
    
    private func broadcastTypingSignal(conversationId: UUID, isTyping: Bool) async {
        // Use Supabase broadcast for ephemeral typing signals
        let channelName = "typing:\(conversationId.uuidString)"
        
        // Create typing payload
        let payload: [String: Any] = [
            "user_id": "current_user_id", // TODO: Get actual current user ID
            "is_typing": isTyping,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        // Broadcast the typing signal
        // Note: This is a simplified implementation
        // In a real implementation, we would use the Supabase broadcast API
        do {
            // For now, we'll emit the typing event locally for testing
            // In production, this would be sent via Supabase broadcast
            let currentUserId = UUID() // TODO: Get actual current user ID
            outputContinuation.yield(.typing(conversationId: conversationId, userId: currentUserId, isTyping: isTyping))
        } catch {
            outputContinuation.yield(.error(.subscriptionFailed))
        }
    }
    
    private func cleanupTypingStates() async {
        for (conversationId, state) in typingStates {
            if state.isTyping {
                await stopTyping(conversationId: conversationId)
            }
        }
    }
    
    private func cleanupTypingState(conversationId: UUID) async {
        guard let state = typingStates[conversationId], !state.isTyping else { return }
        typingStates.removeValue(forKey: conversationId)
    }
    
    deinit {
        outputContinuation.finish()
        for task in subscriptionTasks {
            task.cancel()
        }
    }
}

// MARK: - Helper Types

private struct ReadReceipt: Codable {
    let conversationId: UUID
    let messageId: UUID
    let userId: UUID
    
    enum CodingKeys: String, CodingKey {
        case conversationId = "conversation_id"
        case messageId = "message_id"
        case userId = "user_id"
    }
}

// MARK: - Array Extension

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}