import Foundation

/// Compile-time environment configuration
/// Uses #if directives to set values at compile time based on build configuration
/// 
/// For runtime configuration (URLs, API keys), use AppConfig instead
struct EnvironmentConfig {
    
    // MARK: - Logging Configuration
    static var isLoggingEnabled: Bool {
        #if DEV_ENVIRONMENT || STAGING_ENVIRONMENT
        return true
        #else
        return false
        #endif
    }
    
    // MARK: - Feature Flags (Compile-time)
    static var isDebugMenuEnabled: Bool {
        #if DEV_ENVIRONMENT
        return true
        #else
        return false
        #endif
    }
    
    // MARK: - Environment Info
    static var environmentName: String {
        #if DEV_ENVIRONMENT
        return "Development"
        #elseif STAGING_ENVIRONMENT
        return "Staging"
        #else
        return "Production"
        #endif
    }
}

