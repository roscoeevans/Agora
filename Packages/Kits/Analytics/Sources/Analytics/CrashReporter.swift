import Foundation

/// Crash reporting manager for Sentry integration
@MainActor
public final class CrashReporter {
    public static let shared = CrashReporter()
    
    private var isInitialized = false
    
    private init() {}
    
    /// Initializes crash reporting
    public func initialize(dsn: String, environment: String = "production") {
        // TODO: Initialize Sentry SDK
        isInitialized = true
        print("Crash reporting initialized with DSN: \(dsn), environment: \(environment)")
    }
    
    /// Reports a non-fatal error
    public func reportError(_ error: Error, context: [String: Any] = [:]) {
        guard isInitialized else {
            print("Crash reporter not initialized")
            return
        }
        
        // TODO: Report to Sentry
        print("Error reported: \(error.localizedDescription) with context: \(context)")
    }
    
    /// Reports a custom message
    public func reportMessage(_ message: String, level: LogLevel = .info, context: [String: Any] = [:]) {
        guard isInitialized else {
            print("Crash reporter not initialized")
            return
        }
        
        // TODO: Report to Sentry
        print("Message reported [\(level)]: \(message) with context: \(context)")
    }
    
    /// Sets user context for crash reports
    public func setUser(id: String?, email: String? = nil, username: String? = nil) {
        guard isInitialized else {
            print("Crash reporter not initialized")
            return
        }
        
        // TODO: Set user context in Sentry
        print("User context set - ID: \(id ?? "nil"), email: \(email ?? "nil"), username: \(username ?? "nil")")
    }
    
    /// Sets additional context for crash reports
    public func setContext(key: String, value: Any) {
        guard isInitialized else {
            print("Crash reporter not initialized")
            return
        }
        
        // TODO: Set context in Sentry
        print("Context set - \(key): \(value)")
    }
    
    /// Adds breadcrumb for debugging
    public func addBreadcrumb(message: String, category: String = "default", level: LogLevel = .info) {
        guard isInitialized else {
            print("Crash reporter not initialized")
            return
        }
        
        // TODO: Add breadcrumb to Sentry
        print("Breadcrumb added [\(level)] \(category): \(message)")
    }
}

/// Log levels for crash reporting
public enum LogLevel: String, CaseIterable {
    case debug = "debug"
    case info = "info"
    case warning = "warning"
    case error = "error"
    case fatal = "fatal"
}