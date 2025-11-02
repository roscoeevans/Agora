import Foundation

/// Priority levels for toast notifications affecting interruption behavior
public enum ToastPriority: Comparable, Sendable {
    case normal     // Default for info/success
    case elevated   // Warnings
    case critical   // Errors, can interrupt lower priority
    
    public static func < (lhs: ToastPriority, rhs: ToastPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

private extension ToastPriority {
    var rawValue: Int {
        switch self {
        case .normal: return 0
        case .elevated: return 1
        case .critical: return 2
        }
    }
}

public extension ToastPriority {
    /// Whether this priority can interrupt the given priority
    func canInterrupt(_ other: ToastPriority) -> Bool {
        self > other
    }
    
    /// Default priority for a toast kind
    static func `default`(for kind: ToastKind) -> ToastPriority {
        switch kind {
        case .success, .info:
            return .normal
        case .warning:
            return .elevated
        case .error:
            return .critical
        case .custom:
            return .normal
        }
    }
}