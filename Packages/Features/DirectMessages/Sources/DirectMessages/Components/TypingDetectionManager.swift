import Foundation
import AppFoundation

#if canImport(UIKit)
import UIKit
#endif

/// Manager for handling typing detection and broadcasting with proper debouncing
@Observable
@MainActor
public class TypingDetectionManager {
    private let conversationId: UUID
    private let messagingRealtime: MessagingRealtimeProtocol
    
    // Typing state
    private var isCurrentlyTyping = false
    private var typingStartTask: Task<Void, Never>?
    private var typingKeepAliveTask: Task<Void, Never>?
    private var typingStopTask: Task<Void, Never>?
    
    // Configuration
    private let typingStartDelay: TimeInterval = 0.3 // 300ms delay before starting typing
    private let typingKeepAliveInterval: TimeInterval = 3.0 // 3s keepalive refresh
    private let typingAutoStopDelay: TimeInterval = 4.0 // 4s auto-stop after inactivity
    
    public init(conversationId: UUID, messagingRealtime: MessagingRealtimeProtocol) {
        self.conversationId = conversationId
        self.messagingRealtime = messagingRealtime
        
        // Listen for app lifecycle events to clean up typing state
        setupLifecycleObservers()
    }
    
    deinit {
        // Clean up typing state when manager is deallocated
        // Note: We can't call async stopTyping() in deinit.
        // The typing state will be cleaned up by the system or when
        // the conversation is closed normally.
    }
    
    /// Called when user starts or continues typing
    public func onTextChanged(_ text: String) {
        let hasContent = !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        
        if hasContent {
            handleTypingActivity()
        } else {
            // User cleared the text, stop typing immediately
            Task {
                await stopTyping()
            }
        }
    }
    
    /// Called when user sends a message
    public func onMessageSent() {
        Task {
            await stopTyping()
        }
    }
    
    /// Called when app goes to background
    public func onAppBackground() {
        Task {
            await stopTyping()
        }
    }
    
    // MARK: - Private Methods
    
    private func handleTypingActivity() {
        // Cancel any pending stop task since user is actively typing
        typingStopTask?.cancel()
        
        if !isCurrentlyTyping {
            // Start typing after delay
            typingStartTask?.cancel()
            typingStartTask = Task {
                try? await Task.sleep(nanoseconds: UInt64(typingStartDelay * 1_000_000_000))
                
                guard !Task.isCancelled else { return }
                
                await startTyping()
            }
        } else {
            // Already typing, just reset the auto-stop timer
            scheduleAutoStop()
        }
    }
    
    private func startTyping() async {
        guard !isCurrentlyTyping else { return }
        
        isCurrentlyTyping = true
        
        // Broadcast typing start
        await messagingRealtime.setTyping(conversationId: conversationId, isTyping: true)
        
        // Start keepalive task
        startKeepAlive()
        
        // Schedule auto-stop
        scheduleAutoStop()
    }
    
    private func stopTyping() async {
        guard isCurrentlyTyping else { return }
        
        // Cancel all pending tasks
        typingStartTask?.cancel()
        typingKeepAliveTask?.cancel()
        typingStopTask?.cancel()
        
        isCurrentlyTyping = false
        
        // Broadcast typing stop
        await messagingRealtime.setTyping(conversationId: conversationId, isTyping: false)
    }
    
    private func startKeepAlive() {
        typingKeepAliveTask?.cancel()
        typingKeepAliveTask = Task {
            while !Task.isCancelled && isCurrentlyTyping {
                try? await Task.sleep(nanoseconds: UInt64(typingKeepAliveInterval * 1_000_000_000))
                
                guard !Task.isCancelled && isCurrentlyTyping else { break }
                
                // Send keepalive signal
                await messagingRealtime.setTyping(conversationId: conversationId, isTyping: true)
            }
        }
    }
    
    private func scheduleAutoStop() {
        typingStopTask?.cancel()
        typingStopTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(typingAutoStopDelay * 1_000_000_000))
            
            guard !Task.isCancelled else { return }
            
            await stopTyping()
        }
    }
    
    private func setupLifecycleObservers() {
        #if canImport(UIKit)
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.onAppBackground()
        }
        #endif
    }
}

/// Simplified typing detection for use in SwiftUI views
@Observable
@MainActor
public class SimpleTypingDetector {
    private let manager: TypingDetectionManager
    
    public init(conversationId: UUID, messagingRealtime: MessagingRealtimeProtocol) {
        self.manager = TypingDetectionManager(conversationId: conversationId, messagingRealtime: messagingRealtime)
    }
    
    /// Call this from text field onChange
    public func textChanged(_ text: String) {
        manager.onTextChanged(text)
    }
    
    /// Call this when message is sent
    public func messageSent() {
        manager.onMessageSent()
    }
    
    /// Call this when app backgrounds
    public func appBackgrounded() {
        manager.onAppBackground()
    }
}