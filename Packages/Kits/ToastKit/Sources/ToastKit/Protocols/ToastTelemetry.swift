import Foundation

/// Internal presentation states for deterministic state management
public enum PresentationState: Equatable, Sendable {
    case idle
    case presenting(ToastID)
    case dismissing(ToastID, reason: DismissalMethod)
    case interrupted(current: ToastID, next: ToastID)
    
    public static func == (lhs: PresentationState, rhs: PresentationState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case (.presenting(let lhsID), .presenting(let rhsID)):
            return lhsID == rhsID
        case (.dismissing(let lhsID, let lhsReason), .dismissing(let rhsID, let rhsReason)):
            return lhsID == rhsID && lhsReason == rhsReason
        case (.interrupted(let lhsCurrent, let lhsNext), .interrupted(let rhsCurrent, let rhsNext)):
            return lhsCurrent == rhsCurrent && lhsNext == rhsNext
        default:
            return false
        }
    }
}

/// Methods for tracking toast analytics and telemetry
public protocol ToastTelemetry: Sendable {
    /// Called when a toast is shown to the user
    func toastShown(kind: ToastKind, duration: Duration) async
    
    /// Called when a toast is dismissed
    func toastDismissed(id: ToastID, method: DismissalMethod) async
    
    /// Called when toasts are coalesced (deduplicated)
    func toastCoalesced(originalId: ToastID, updatedId: ToastID) async
    
    /// Called when a toast is dropped from the queue
    func toastDropped(reason: DropReason) async
    
    /// Called to track animation performance
    func animationPerformance(frameDrops: Int, duration: Duration) async
    
    /// Called when toast manager state transitions occur
    func stateTransition(from: PresentationState, to: PresentationState) async
}

/// How a toast was dismissed
public enum DismissalMethod: Sendable {
    case automatic      // Timer expired
    case userTap        // User tapped to dismiss
    case userSwipe      // User swiped to dismiss
    case actionTap      // User tapped action button
    case programmatic   // Dismissed via API call
    case interrupted    // Dismissed by higher priority toast
    case sceneInactive  // Scene became inactive
}

/// Why a toast was dropped from the queue
public enum DropReason: Sendable {
    case queueFull      // Queue exceeded maximum size
    case rateLimited    // Too many toasts in short time
    case sceneUnavailable // No active scene to present in
    case lowMemory      // System memory pressure
    case backgrounded   // App backgrounded with non-critical toast
    case performanceOptimization // Dropped for performance reasons (low power mode, etc.)
}

// PresentationState is now defined in ToastManager.swift to avoid circular dependencies

// MARK: - Default Implementation

/// No-op implementation for testing and when telemetry is disabled
public struct NoOpToastTelemetry: ToastTelemetry, Sendable {
    public init() {}
    
    public func toastShown(kind: ToastKind, duration: Duration) async {}
    public func toastDismissed(id: ToastID, method: DismissalMethod) async {}
    public func toastCoalesced(originalId: ToastID, updatedId: ToastID) async {}
    public func toastDropped(reason: DropReason) async {}
    public func animationPerformance(frameDrops: Int, duration: Duration) async {}
    public func stateTransition(from: PresentationState, to: PresentationState) async {}
}