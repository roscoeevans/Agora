import SwiftUI

/// Semantic types for toast notifications with associated styling
public enum ToastKind: Sendable {
    case success
    case error
    case info
    case warning
    case custom(icon: Image?, accent: Color?)
}

public extension ToastKind {
    /// Default icon for the toast kind
    var defaultIcon: Image? {
        switch self {
        case .success:
            return Image(systemName: "checkmark.circle.fill")
        case .error:
            return Image(systemName: "exclamationmark.triangle.fill")
        case .info:
            return Image(systemName: "info.circle.fill")
        case .warning:
            return Image(systemName: "exclamationmark.circle.fill")
        case .custom(let icon, _):
            return icon
        }
    }
    
    /// Default accent color for the toast kind
    var defaultAccentColor: Color {
        switch self {
        case .success:
            return .green
        case .error:
            return .red
        case .info:
            return .blue
        case .warning:
            return .orange
        case .custom(_, let accent):
            return accent ?? .blue
        }
    }
    
    /// Analytics value for telemetry
    var analyticsValue: String {
        switch self {
        case .success: return "success"
        case .error: return "error"
        case .info: return "info"
        case .warning: return "warning"
        case .custom: return "custom"
        }
    }
}