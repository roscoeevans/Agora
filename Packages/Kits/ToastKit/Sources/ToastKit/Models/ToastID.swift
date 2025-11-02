import Foundation

/// Unique identifier for toast notifications
public struct ToastID: Hashable, Sendable {
    private let uuid = UUID()
    
    public init() {}
    
    public static func == (lhs: ToastID, rhs: ToastID) -> Bool {
        lhs.uuid == rhs.uuid
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
}

extension ToastID: CustomStringConvertible {
    public var description: String {
        "ToastID(\(uuid.uuidString.prefix(8)))"
    }
}