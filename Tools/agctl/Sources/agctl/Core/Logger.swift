import Foundation

/// Console logging with colored output
enum Logger {
    static func info(_ message: String) {
        print("ℹ️  \(message)")
    }
    
    static func success(_ message: String) {
        print("✅ \(message)")
    }
    
    static func error(_ message: String) {
        print("❌ \(message)")
    }
    
    static func warning(_ message: String) {
        print("⚠️  \(message)")
    }
    
    static func section(_ title: String) {
        print("\n\(title)")
        print(String(repeating: "=", count: title.count))
        print("")
    }
    
    static func bullet(_ message: String) {
        print("  • \(message)")
    }
    
    static func arrow(_ message: String) {
        print("  → \(message)")
    }
}

