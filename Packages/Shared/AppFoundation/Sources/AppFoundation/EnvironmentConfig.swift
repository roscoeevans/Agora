import Foundation

/// Environment configuration protocol
/// Provides build configuration and feature flags
public protocol EnvironmentConfig: Sendable {
    var isLoggingEnabled: Bool { get }
    var isDebugMenuEnabled: Bool { get }
    var environmentName: String { get }
}

/// Live implementation using runtime environment detection
/// 
/// **Important:** Swift packages don't inherit compilation conditions from the main app,
/// so we use runtime detection via bundle identifier instead of #if directives.
/// This approach is more reliable and matches how AppConfig detects environments.
public struct EnvironmentConfigLive: EnvironmentConfig {
    public init() {}
    
    // MARK: - Logging Configuration
    public var isLoggingEnabled: Bool {
        // Enable logging for development and staging builds
        AppConfig.isDevelopment || AppConfig.isStaging
    }
    
    // MARK: - Feature Flags
    public var isDebugMenuEnabled: Bool {
        // Debug menu only in development (not staging or production)
        AppConfig.isDevelopment
    }
    
    // MARK: - Environment Info
    public var environmentName: String {
        if AppConfig.isDevelopment {
            return "Development"
        } else if AppConfig.isStaging {
            return "Staging"
        } else {
            return "Production"
        }
    }
}

/// Fake implementation for testing
public struct EnvironmentConfigFake: EnvironmentConfig {
    public var isLoggingEnabled: Bool
    public var isDebugMenuEnabled: Bool
    public var environmentName: String
    
    public init(
        isLoggingEnabled: Bool = false,
        isDebugMenuEnabled: Bool = false,
        environmentName: String = "Test"
    ) {
        self.isLoggingEnabled = isLoggingEnabled
        self.isDebugMenuEnabled = isDebugMenuEnabled
        self.environmentName = environmentName
    }
}

