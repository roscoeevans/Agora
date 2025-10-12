import Foundation

struct EnvironmentConfig {
    
    // MARK: - API Configuration
    static var apiBaseURL: String {
        #if DEV_ENVIRONMENT
        return "https://api-dev.agora.com"
        #elseif STAGING_ENVIRONMENT
        return "https://api-staging.agora.com"
        #else
        return "https://api.agora.com"
        #endif
    }
    
    // MARK: - Logging Configuration
    static var isLoggingEnabled: Bool {
        #if DEV_ENVIRONMENT || STAGING_ENVIRONMENT
        return true
        #else
        return false
        #endif
    }
    
    // MARK: - Analytics Configuration
    static var analyticsKey: String {
        #if DEV_ENVIRONMENT
        return "dev-analytics-key"
        #elseif STAGING_ENVIRONMENT
        return "staging-analytics-key"
        #else
        return "prod-analytics-key"
        #endif
    }
    
    // MARK: - Feature Flags
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

