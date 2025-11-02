import SwiftUI

/// Action that can be performed from a toast notification
public struct ToastAction: @unchecked Sendable {
    public let title: LocalizedStringKey
    public let role: ButtonRole?
    public let handler: @MainActor @Sendable () -> Void
    
    public init(
        title: LocalizedStringKey,
        role: ButtonRole? = nil,
        handler: @escaping @MainActor @Sendable () -> Void
    ) {
        self.title = title
        self.role = role
        self.handler = handler
    }
}

public extension ToastAction {
    /// Create a retry action
    static func retry(handler: @escaping @MainActor @Sendable () -> Void) -> ToastAction {
        ToastAction(title: "Retry", handler: handler)
    }
    
    /// Create a dismiss action
    static func dismiss(handler: @escaping @MainActor @Sendable () -> Void) -> ToastAction {
        ToastAction(title: "Dismiss", handler: handler)
    }
    
    /// Create an undo action
    static func undo(handler: @escaping @MainActor @Sendable () -> Void) -> ToastAction {
        ToastAction(title: "Undo", handler: handler)
    }
    
    /// Create a view action (e.g., "View Details")
    static func view(handler: @escaping @MainActor @Sendable () -> Void) -> ToastAction {
        ToastAction(title: "View", handler: handler)
    }
}