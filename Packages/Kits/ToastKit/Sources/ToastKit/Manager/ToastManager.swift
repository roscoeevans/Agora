import SwiftUI
import Foundation

/// Actor-based toast manager providing thread-safe queue management and presentation coordination
public actor ToastManager: ToastsProviding {
    
    // MARK: - State Management
    
    /// Current presentation state for deterministic transitions
    private var presentationState: PresentationState = .idle
    
    /// FIFO queue of pending toasts
    private var queue: [ToastItem] = []
    
    /// Currently visible toast
    private var currentToast: ToastItem?
    
    /// Coalescing cache for deduplication within time windows
    private var coalescingCache: [String: CoalescingEntry] = [:]
    
    /// Last presentation timestamp for rate limiting
    private var lastPresentationTime: ContinuousClock.Instant?
    
    /// Restoration queue for critical toasts during app lifecycle
    private var restorationQueue: [ToastItem] = []
    
    /// Configuration policy
    private let policy: ToastPolicy
    
    /// Telemetry provider
    private let telemetry: ToastTelemetry
    
    /// Scene manager for multi-window support
    nonisolated(unsafe) private weak var sceneManager: ToastSceneManager?
    
    /// Performance manager for resource optimization
    private let performanceManager: ToastPerformanceManager
    

    
    // MARK: - Initialization
    
    public init(
        policy: ToastPolicy = .default,
        telemetry: ToastTelemetry? = nil,
        sceneManager: ToastSceneManager? = nil
    ) {
        self.policy = policy
        self.telemetry = telemetry ?? policy.telemetry
        self.sceneManager = sceneManager
        self.performanceManager = ToastPerformanceManager.shared
    }
    
    // MARK: - Public API
    
    public func show(_ item: ToastItem) async {
        await enqueue(item)
    }
    
    public func show(
        _ message: LocalizedStringKey,
        kind: ToastKind = .info,
        options: ToastOptions = ToastOptions(),
        action: ToastAction? = nil
    ) async {
        let item = ToastItem(
            message: message,
            kind: kind,
            options: options,
            action: action
        )
        await show(item)
    }
    
    public func dismiss(id: ToastID) async {
        await dismissSpecific(id: id)
    }
    
    public func dismissAll() async {
        await dismissAllToasts()
    }
    
    // MARK: - Queue Management
    
    /// Enqueue a toast with coalescing and priority handling
    private func enqueue(_ item: ToastItem) async {
        // Check for coalescing first
        if let dedupeKey = item.options.dedupeKey {
            if await handleCoalescing(item, dedupeKey: dedupeKey) {
                return // Item was coalesced, no need to enqueue
            }
        }
        
        // Check queue capacity with performance-aware bounds
        let effectiveMaxSize = await getEffectiveQueueSize()
        if queue.count >= effectiveMaxSize {
            await telemetry.toastDropped(reason: .queueFull)
            
            // In low power mode, be more aggressive about dropping toasts
            let performanceMode = await MainActor.run { performanceManager.performanceMode }
            if performanceMode == .lowPower {
                // Drop oldest non-critical toast to make room
                if let oldestIndex = queue.firstIndex(where: { $0.options.priority != .critical }) {
                    let _ = queue.remove(at: oldestIndex)
                    await telemetry.toastDropped(reason: .performanceOptimization)
                }
            }
            
            // If still no room, drop the toast
            if queue.count >= effectiveMaxSize {
                return
            }
        }
        
        // Handle priority interruption
        if item.options.priority.canInterrupt(currentToast?.options.priority ?? .normal) {
            await handlePriorityInterruption(item)
            return
        }
        
        // Add to queue
        queue.append(item)
        
        // Process queue if idle
        if case .idle = presentationState {
            await processQueue()
        }
    }
    
    /// Process the next item in the queue
    private func processQueue() async {
        guard !queue.isEmpty else { return }
        
        // Check rate limiting
        if await shouldRateLimit() {
            await scheduleDelayedProcessing()
            return
        }
        
        let nextItem = queue.removeFirst()
        await presentToast(nextItem)
    }
    
    /// Handle coalescing logic for duplicate toasts
    private func handleCoalescing(_ item: ToastItem, dedupeKey: String) async -> Bool {
        let now = ContinuousClock.now
        
        // Clean expired entries
        await cleanExpiredCoalescingEntries(at: now)
        
        // Check if we have a matching entry within the coalescing window
        if let existingEntry = coalescingCache[dedupeKey] {
            // Update existing item in queue or current toast
            if let queueIndex = queue.firstIndex(where: { $0.id == existingEntry.toastID }) {
                queue[queueIndex] = item
                coalescingCache[dedupeKey] = CoalescingEntry(
                    toastID: item.id,
                    timestamp: now
                )
                await telemetry.toastCoalesced(originalId: existingEntry.toastID, updatedId: item.id)
                return true
            } else if currentToast?.id == existingEntry.toastID {
                // Update currently visible toast
                currentToast = item
                coalescingCache[dedupeKey] = CoalescingEntry(
                    toastID: item.id,
                    timestamp: now
                )
                await telemetry.toastCoalesced(originalId: existingEntry.toastID, updatedId: item.id)
                
                // Notify scene manager of update
                await MainActor.run { [weak sceneManager] in
                    sceneManager?.activePresenter()?.updateCurrentToast(item)
                }
                return true
            }
        }
        
        // Add new entry to coalescing cache
        coalescingCache[dedupeKey] = CoalescingEntry(
            toastID: item.id,
            timestamp: now
        )
        
        return false
    }
    
    /// Handle priority interruption of lower priority toasts
    private func handlePriorityInterruption(_ newItem: ToastItem) async {
        guard let current = currentToast else {
            // No current toast, present immediately
            await presentToast(newItem)
            return
        }
        
        let oldState = presentationState
        let newState = PresentationState.interrupted(current: current.id, next: newItem.id)
        await transitionState(from: oldState, to: newState)
        
        // Dismiss current toast with interruption delay
        do {
            try await Task.sleep(for: policy.criticalInterruptionDelay)
        } catch {
            // Handle cancellation gracefully
            return
        }
        
        await MainActor.run { [weak sceneManager] in
            sceneManager?.activePresenter()?.dismiss(animated: true) { [weak self] in
                Task {
                    await self?.presentToast(newItem)
                }
            }
        }
    }
    
    /// Present a toast to the user
    private func presentToast(_ item: ToastItem) async {
        let oldState = presentationState
        let newState = PresentationState.presenting(item.id)
        await transitionState(from: oldState, to: newState)
        
        currentToast = item
        lastPresentationTime = ContinuousClock.now
        
        // Execute haptics coordinated with toast appearance
        Task { @MainActor in
            // Execute haptics immediately for better responsiveness
            // The haptic system will respect system settings and per-toast opt-out
            await item.options.haptics.executeWithAnimationTiming()
        }
        
        // Notify telemetry
        await telemetry.toastShown(kind: item.kind, duration: item.options.duration)
        
        // Present via scene manager
        await MainActor.run { [weak sceneManager] in
            sceneManager?.presentInActiveScene(item) { [weak self] dismissalMethod in
                Task {
                    await self?.handleToastDismissal(item.id, method: dismissalMethod)
                }
            }
        }
        
        // Schedule automatic dismissal
        await scheduleAutomaticDismissal(for: item)
    }
    
    /// Schedule automatic dismissal after duration
    private func scheduleAutomaticDismissal(for item: ToastItem) async {
        do {
            try await Task.sleep(for: item.options.duration)
        } catch {
            // Handle cancellation gracefully
            return
        }
        
        // Only dismiss if this toast is still current
        if currentToast?.id == item.id {
            await handleToastDismissal(item.id, method: .automatic)
        }
    }
    

    
    /// Handle toast dismissal and continue processing queue
    private func handleToastDismissal(_ toastID: ToastID, method: DismissalMethod) async {
        guard currentToast?.id == toastID else { return }
        
        let oldState = presentationState
        let newState = PresentationState.dismissing(toastID, reason: method)
        await transitionState(from: oldState, to: newState)
        
        await telemetry.toastDismissed(id: toastID, method: method)
        
        currentToast = nil
        presentationState = .idle
        
        // Continue processing queue
        await processQueue()
    }
    
    /// Dismiss a specific toast by ID
    private func dismissSpecific(id: ToastID) async {
        // Check if it's the current toast
        if currentToast?.id == id {
            await handleToastDismissal(id, method: .programmatic)
            return
        }
        
        // Remove from queue
        if let index = queue.firstIndex(where: { $0.id == id }) {
            queue.remove(at: index)
        }
    }
    
    /// Dismiss all toasts
    private func dismissAllToasts() async {
        // Clear queue
        queue.removeAll()
        
        // Dismiss current toast if any
        if let current = currentToast {
            await handleToastDismissal(current.id, method: .programmatic)
        }
        
        // Clear coalescing cache
        coalescingCache.removeAll()
    }
    
    // MARK: - Rate Limiting
    
    /// Check if we should rate limit the next presentation
    private func shouldRateLimit() async -> Bool {
        guard let lastTime = lastPresentationTime else { return false }
        let elapsed = ContinuousClock.now - lastTime
        return elapsed < policy.minimumInterval
    }
    
    /// Schedule delayed processing to respect rate limits
    private func scheduleDelayedProcessing() async {
        guard let lastTime = lastPresentationTime else {
            await processQueue()
            return
        }
        
        let elapsed = ContinuousClock.now - lastTime
        let remaining = policy.minimumInterval - elapsed
        
        if remaining > .zero {
            do {
                try await Task.sleep(for: remaining)
            } catch {
                // Handle cancellation gracefully
                return
            }
        }
        
        await processQueue()
    }
    
    // MARK: - State Management
    
    /// Transition between presentation states with telemetry
    private func transitionState(from oldState: PresentationState, to newState: PresentationState) async {
        presentationState = newState
        await telemetry.stateTransition(from: oldState, to: newState)
    }
    
    // MARK: - Coalescing Cache Management
    
    /// Clean expired entries from coalescing cache
    private func cleanExpiredCoalescingEntries(at currentTime: ContinuousClock.Instant) async {
        let expiredKeys = coalescingCache.compactMap { key, entry in
            let age = currentTime - entry.timestamp
            return age > policy.coalescingWindow ? key : nil
        }
        
        for key in expiredKeys {
            coalescingCache.removeValue(forKey: key)
        }
    }
    
    // MARK: - Lifecycle Management
    
    /// Set the scene manager
    nonisolated public func setSceneManager(_ manager: ToastSceneManager?) {
        self.sceneManager = manager
    }
    
    /// Handle app backgrounding
    public func handleAppDidEnterBackground() async {
        if policy.persistCriticalToasts {
            // Move critical toasts to restoration queue
            let criticalToasts = queue.filter { $0.options.priority == .critical }
            restorationQueue.append(contentsOf: criticalToasts)
            
            if let current = currentToast, current.options.priority == .critical {
                restorationQueue.append(current)
            }
        }
        
        // Clear current state
        await dismissAllToasts()
    }
    
    /// Handle app foregrounding
    public func handleAppWillEnterForeground() async {
        // Restore critical toasts
        if !restorationQueue.isEmpty {
            queue.append(contentsOf: restorationQueue)
            restorationQueue.removeAll()
            
            if case .idle = presentationState {
                await processQueue()
            }
        }
    }
    
    // MARK: - Performance Optimizations
    
    /// Get effective queue size based on performance mode
    private func getEffectiveQueueSize() async -> Int {
        let baseSize = policy.maxQueueSize
        
        let performanceMode = await MainActor.run { performanceManager.performanceMode }
        switch performanceMode {
        case .lowPower:
            return max(1, baseSize / 2) // Reduce queue size in low power mode
        case .standard:
            return baseSize
        case .highPerformance:
            return min(20, baseSize * 2) // Allow larger queue in high performance mode
        }
    }
    
    /// Clean up all active timers
    private func cleanupAllTimers() async {
        // Task-based timers are automatically cleaned up when tasks are cancelled
        // No explicit cleanup needed for the new approach
    }
    
    /// Perform memory cleanup
    public func performMemoryCleanup() async {
        // Clean up expired coalescing entries
        await cleanExpiredCoalescingEntries(at: ContinuousClock.now)
        
        // Task-based approach doesn't need timer cleanup
        
        // Trigger performance manager cleanup
        await MainActor.run { [performanceManager] in
            performanceManager.performMemoryCleanup()
        }
    }
}

// MARK: - Supporting Types

/// Entry in the coalescing cache
private struct CoalescingEntry: Sendable {
    let toastID: ToastID
    let timestamp: ContinuousClock.Instant
}



// PresentationState is defined in ToastTelemetry.swift

// MARK: - DismissalMethod Equatable

extension DismissalMethod: Equatable {
    public static func == (lhs: DismissalMethod, rhs: DismissalMethod) -> Bool {
        switch (lhs, rhs) {
        case (.automatic, .automatic),
             (.userTap, .userTap),
             (.userSwipe, .userSwipe),
             (.actionTap, .actionTap),
             (.programmatic, .programmatic),
             (.interrupted, .interrupted),
             (.sceneInactive, .sceneInactive):
            return true
        default:
            return false
        }
    }
}

