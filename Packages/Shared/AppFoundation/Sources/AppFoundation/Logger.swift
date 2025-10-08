import Foundation
import os.log

/// Structured logging utility for the Agora app
public struct Logger: Sendable {
    private let category: String
    
    public init(subsystem: String = "com.agora.app", category: String) {
        self.category = category
    }
    
    /// Log a debug message
    public func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let logMessage = "[\(category)] DEBUG: \(message) [\(URL(fileURLWithPath: file).lastPathComponent):\(line) \(function)]"
        print(logMessage)
    }
    
    /// Log an info message
    public func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let logMessage = "[\(category)] INFO: \(message) [\(URL(fileURLWithPath: file).lastPathComponent):\(line) \(function)]"
        print(logMessage)
    }
    
    /// Log a warning message
    public func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let logMessage = "[\(category)] WARNING: \(message) [\(URL(fileURLWithPath: file).lastPathComponent):\(line) \(function)]"
        print(logMessage)
    }
    
    /// Log an error message
    public func error(_ message: String, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        let errorInfo = error.map { " Error: \($0)" } ?? ""
        let logMessage = "[\(category)] ERROR: \(message)\(errorInfo) [\(URL(fileURLWithPath: file).lastPathComponent):\(line) \(function)]"
        print(logMessage)
    }
    
    /// Log a critical error
    public func critical(_ message: String, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        let errorInfo = error.map { " Error: \($0)" } ?? ""
        let logMessage = "[\(category)] CRITICAL: \(message)\(errorInfo) [\(URL(fileURLWithPath: file).lastPathComponent):\(line) \(function)]"
        print(logMessage)
    }
}

/// Convenience loggers for common categories
public extension Logger {
    static let networking = Logger(category: "Networking")
    static let auth = Logger(category: "Authentication")
    static let ui = Logger(category: "UI")
    static let persistence = Logger(category: "Persistence")
    static let analytics = Logger(category: "Analytics")
}