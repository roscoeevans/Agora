import Foundation
import AppFoundation
import SupabaseKit

// MARK: - Thread-Safe Wrapper

private actor Mutex<T: Sendable> {
    private var value: T
    
    init(_ value: T) {
        self.value = value
    }
    
    func withLock<R>(_ operation: (inout T) -> R) -> R {
        return operation(&value)
    }
}

/// Production implementation of MessagingRealtimeProtocol
/// Bridges the MessagingRealtimeObserver actor to the protocol interface
public final class MessagingRealtimeLive: MessagingRealtimeProtocol {
    
    private let observer: MessagingRealtimeObserver
    private let eventStream: AsyncStream<MessagingEvent>
    private let eventContinuation: AsyncStream<MessagingEvent>.Continuation
    
    public init(observer: MessagingRealtimeObserver) {
        self.observer = observer
        
        let (stream, continuation) = AsyncStream<MessagingEvent>.makeStream()
        self.eventStream = stream
        self.eventContinuation = continuation
        
        // Bridge observer output to protocol events
        Task {
            for await output in observer.outputStream {
                await self.handleObserverOutput(output)
            }
        }
    }
    
    public var events: AsyncStream<MessagingEvent> {
        eventStream
    }
    
    // MARK: - Subscription Management
    
    public func subscribeConversationList() async throws -> MessagingSubscription {
        // For conversation list, we don't need specific conversation IDs
        // The observer will handle conversation updates through its channels
        return MessagingSubscriptionLive(
            observer: observer,
            type: .conversationList
        )
    }
    
    public func subscribe(conversationId: UUID) async throws -> MessagingSubscription {
        // Add this conversation to the observer's visible set
        await observer.send(.setVisibleConversations([conversationId]))
        
        return MessagingSubscriptionLive(
            observer: observer,
            type: .conversation(conversationId)
        )
    }
    
    // MARK: - Typing Management
    
    public func setTyping(conversationId: UUID, isTyping: Bool) async {
        await observer.send(.setTyping(conversationId: conversationId, isTyping: isTyping))
    }
    
    // MARK: - Observer Output Handling
    
    private func handleObserverOutput(_ output: MessagingRealtimeObserver.Output) async {
        switch output {
        case .messageAdded(let message):
            eventContinuation.yield(.messageAdded(message))
            
        case .messageUpdated(let message):
            eventContinuation.yield(.messageUpdated(message))
            
        case .messageDeleted(let conversationId, let messageId):
            eventContinuation.yield(.messageDeleted(messageId, conversationId: conversationId))
            
        case .readReceipt(let conversationId, let messageId, let userId):
            eventContinuation.yield(.readReceipt(conversationId: conversationId, messageId: messageId, userId: userId))
            
        case .conversationUpdated(let conversation):
            eventContinuation.yield(.conversationUpdated(conversation))
            
        case .typing(let conversationId, let userId, let isTyping):
            eventContinuation.yield(.typing(conversationId: conversationId, userId: userId, isTyping: isTyping))
            
        case .error(let error):
            // Log error but don't propagate to event stream
            print("[MessagingRealtimeLive] Error: \(error)")
        }
    }
    
    deinit {
        eventContinuation.finish()
    }
}

// MARK: - Subscription Implementation

private final class MessagingSubscriptionLive: MessagingSubscription {
    
    enum SubscriptionType {
        case conversationList
        case conversation(UUID)
    }
    
    private let observer: MessagingRealtimeObserver
    private let type: SubscriptionType
    private let isActivated = Mutex(true)
    
    init(observer: MessagingRealtimeObserver, type: SubscriptionType) {
        self.observer = observer
        self.type = type
    }
    
    public func cancel() async {
        guard await isActivated.withLock({ $0 }) else { return }
        await isActivated.withLock { $0 = false }
        
        switch type {
        case .conversationList:
            // Clear all visible conversations
            await observer.send(.setVisibleConversations([]))
            
        case .conversation(_):
            // Remove this conversation from visible set
            // Note: In a real implementation, we'd need to track multiple subscriptions
            // and only remove when all subscriptions for a conversation are cancelled
            await observer.send(.setVisibleConversations([]))
        }
    }
    
    public var isActive: Bool {
        get async { await isActivated.withLock { $0 } }
    }
}

// MARK: - Lifecycle Management

extension MessagingRealtimeLive {
    
    /// Call when app enters foreground
    public func handleAppForeground() async {
        await observer.send(.lifecycleForeground)
    }
    
    /// Call when app enters background
    public func handleAppBackground() async {
        await observer.send(.lifecycleBackground)
    }
    
    /// Update the set of visible conversations (for efficient subscriptions)
    public func setVisibleConversations(_ conversationIds: Set<UUID>) async {
        await observer.send(.setVisibleConversations(conversationIds))
    }
    
    /// Set the currently active conversation thread
    public func setActiveThread(_ conversationId: UUID?) async {
        await observer.send(.setActiveThread(conversationId))
    }
}