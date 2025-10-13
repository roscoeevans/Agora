import Foundation

/// Centralized application configuration loaded from Info.plist (build settings injection)
public enum AppConfig {
    // MARK: - Info.plist Key Access
    
    /// Check if we're running in a preview environment
    private static var isPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
    
    private static func value(_ key: String, previewFallback: String? = nil) -> String {
        // In preview environment, return fallback value if provided
        if isPreview, let fallback = previewFallback {
            return fallback
        }
        
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String else {
            if isPreview, let fallback = previewFallback {
                return fallback
            }
            fatalError("Missing Info.plist key: \(key). Ensure \(key) is set in your .xcconfig files.")
        }
        return value
    }
    
    // MARK: - URLs
    
    /// API base URL (e.g., https://api.agora.social or https://staging-api.agora.social)
    public static let apiBaseURL: URL = {
        let urlString = value("API_BASE_URL", previewFallback: "https://preview.example.com")
        guard let url = URL(string: urlString) else {
            fatalError("Invalid API_BASE_URL: \(urlString)")
        }
        return url
    }()
    
    /// WebSocket URL (e.g., wss://ws.agora.social)
    public static let websocketURL: URL = {
        let urlString = value("WEBSOCKET_URL", previewFallback: "wss://preview.example.com")
        guard let url = URL(string: urlString) else {
            fatalError("Invalid WEBSOCKET_URL: \(urlString)")
        }
        return url
    }()
    
    // MARK: - Universal Links
    
    /// Universal links host (e.g., app.agora.social or staging.agora.social)
    public static let linksHost: String = value("UNIVERSAL_LINKS_HOST", previewFallback: "preview.agora.social")
    
    // MARK: - App Groups & Keychain
    
    /// App Group identifier for shared containers
    public static let appGroup: String = value("APP_GROUP", previewFallback: "group.com.agoraapp.ios.preview")
    
    /// Keychain access group for shared keychain items
    public static let keychainGroup: String = value("KEYCHAIN_GROUP", previewFallback: "com.agoraapp.ios.preview")
    
    // MARK: - Analytics
    
    /// Analytics write key (PostHog, Segment, etc.)
    public static let analyticsWriteKey: String = value("ANALYTICS_WRITE_KEY", previewFallback: "preview-analytics-key")
    
    // MARK: - Supabase Configuration
    
    /// Supabase project URL
    public static let supabaseURL: URL = {
        let urlString = value("SUPABASE_URL", previewFallback: "https://preview.supabase.co")
        guard let url = URL(string: urlString) else {
            fatalError("Invalid SUPABASE_URL: \(urlString)")
        }
        return url
    }()
    
    /// Supabase anonymous key
    public static let supabaseAnonKey: String = value("SUPABASE_ANON_KEY", previewFallback: "preview-anon-key")
    
    /// Web share base URL for deep links
    public static let webShareBaseURL: URL = {
        let host = linksHost
        guard let url = URL(string: "https://\(host)") else {
            fatalError("Invalid web share URL")
        }
        return url
    }()
    
    // MARK: - Environment Detection
    
    /// Current bundle identifier
    public static let bundleIdentifier: String = Bundle.main.bundleIdentifier ?? ""
    
    /// Whether this is a development build
    public static var isDevelopment: Bool {
        bundleIdentifier.contains(".dev")
    }
    
    /// Whether this is a staging build
    public static var isStaging: Bool {
        bundleIdentifier.contains(".staging")
    }
    
    /// Whether this is a production build
    public static var isProduction: Bool {
        !isDevelopment && !isStaging
    }
    
    /// Whether debug features should be shown
    public static var showsDebugFeatures: Bool {
        #if DEBUG
        return true
        #else
        return isDevelopment || isStaging
        #endif
    }
    
    // MARK: - Validation
    
    /// Validate configuration at app startup
    public static func validate() throws {
        // Validate bundle identifier matches environment expectations
        if isProduction {
            guard bundleIdentifier == "com.agoraapp.ios" else {
                throw ConfigurationError.invalidBundleIdentifier(
                    expected: "com.agoraapp.ios",
                    actual: bundleIdentifier
                )
            }
        } else if isStaging {
            guard bundleIdentifier == "com.agoraapp.ios.staging" else {
                throw ConfigurationError.invalidBundleIdentifier(
                    expected: "com.agoraapp.ios.staging",
                    actual: bundleIdentifier
                )
            }
        } else if isDevelopment {
            guard bundleIdentifier == "com.agoraapp.ios.dev" else {
                throw ConfigurationError.invalidBundleIdentifier(
                    expected: "com.agoraapp.ios.dev",
                    actual: bundleIdentifier
                )
            }
        }
        
        // Validate URLs are well-formed
        _ = apiBaseURL
        _ = websocketURL
        
        // Validate hosts match environment
        if isProduction {
            guard linksHost == "app.agora.social" else {
                throw ConfigurationError.invalidHost(
                    key: "UNIVERSAL_LINKS_HOST",
                    expected: "app.agora.social",
                    actual: linksHost
                )
            }
        } else {
            guard linksHost == "staging.agora.social" else {
                throw ConfigurationError.invalidHost(
                    key: "UNIVERSAL_LINKS_HOST",
                    expected: "staging.agora.social",
                    actual: linksHost
                )
            }
        }
    }
}

// MARK: - Configuration Errors

public enum ConfigurationError: LocalizedError {
    case invalidBundleIdentifier(expected: String, actual: String)
    case invalidHost(key: String, expected: String, actual: String)
    case invalidURL(key: String, value: String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidBundleIdentifier(let expected, let actual):
            return "Bundle identifier mismatch: expected '\(expected)', got '\(actual)'"
        case .invalidHost(let key, let expected, let actual):
            return "Invalid \(key): expected '\(expected)', got '\(actual)'"
        case .invalidURL(let key, let value):
            return "Invalid URL for \(key): '\(value)'"
        }
    }
}
