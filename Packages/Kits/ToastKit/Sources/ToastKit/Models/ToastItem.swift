import SwiftUI

/// Complete toast notification data model
public struct ToastItem: Identifiable, @unchecked Sendable {
    public let id: ToastID
    public let message: LocalizedStringKey
    public let kind: ToastKind
    public var options: ToastOptions
    public var action: ToastAction?
    
    public init(
        id: ToastID = ToastID(),
        message: LocalizedStringKey,
        kind: ToastKind,
        options: ToastOptions = ToastOptions(),
        action: ToastAction? = nil
    ) {
        self.id = id
        self.message = message
        self.kind = kind
        self.options = options
        self.action = action
        
        // Auto-configure options based on kind if not explicitly set
        if options.priority == .normal && options.haptics == .auto {
            self.options.priority = .default(for: kind)
            self.options.haptics = .default(for: kind)
        }
    }
}

public extension ToastItem {
    /// Create a success toast
    static func success(
        _ message: LocalizedStringKey,
        options: ToastOptions = .default(for: .success),
        action: ToastAction? = nil
    ) -> ToastItem {
        ToastItem(message: message, kind: .success, options: options, action: action)
    }
    
    /// Create an error toast
    static func error(
        _ message: LocalizedStringKey,
        options: ToastOptions = .default(for: .error),
        action: ToastAction? = nil
    ) -> ToastItem {
        ToastItem(message: message, kind: .error, options: options, action: action)
    }
    
    /// Create an info toast
    static func info(
        _ message: LocalizedStringKey,
        options: ToastOptions = .default(for: .info),
        action: ToastAction? = nil
    ) -> ToastItem {
        ToastItem(message: message, kind: .info, options: options, action: action)
    }
    
    /// Create a warning toast
    static func warning(
        _ message: LocalizedStringKey,
        options: ToastOptions = .default(for: .warning),
        action: ToastAction? = nil
    ) -> ToastItem {
        ToastItem(message: message, kind: .warning, options: options, action: action)
    }
    
    /// Whether this toast can be coalesced with another
    func canCoalesce(with other: ToastItem) -> Bool {
        guard let dedupeKey = options.dedupeKey,
              let otherDedupeKey = other.options.dedupeKey else {
            return false
        }
        return dedupeKey == otherDedupeKey
    }
    
    /// Update this toast with content from another (for coalescing)
    mutating func update(from other: ToastItem) {
        // Only update if they can be coalesced
        guard canCoalesce(with: other) else { return }
        
        // Update with newer content but keep original ID
        self = ToastItem(
            id: self.id, // Keep original ID
            message: other.message,
            kind: other.kind,
            options: other.options,
            action: other.action
        )
    }
}