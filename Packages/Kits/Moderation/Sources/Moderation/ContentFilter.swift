import Foundation

/// Content filtering configuration
public struct FilterConfig {
    public let mutedKeywords: Set<String>
    public let mutedUsers: Set<String>
    public let hideReplies: Bool
    public let hideReposts: Bool
    public let caseSensitive: Bool
    
    public init(
        mutedKeywords: Set<String> = [],
        mutedUsers: Set<String> = [],
        hideReplies: Bool = false,
        hideReposts: Bool = false,
        caseSensitive: Bool = false
    ) {
        self.mutedKeywords = mutedKeywords
        self.mutedUsers = mutedUsers
        self.hideReplies = hideReplies
        self.hideReposts = hideReposts
        self.caseSensitive = caseSensitive
    }
}

/// Content filtering result
public enum FilterResult {
    case show
    case hide(reason: FilterReason)
    case warn(reason: FilterReason)
}

/// Reasons for content filtering
public enum FilterReason {
    case mutedKeyword(String)
    case mutedUser(String)
    case hiddenReply
    case hiddenRepost
    case sensitiveContent
    case reportedContent
}

/// Content item for filtering
public protocol FilterableContent {
    var id: String { get }
    var authorId: String { get }
    var text: String { get }
    var isReply: Bool { get }
    var isRepost: Bool { get }
    var isSensitive: Bool { get }
    var isReported: Bool { get }
}

/// Keyword muting engine for content filtering
@MainActor
public final class ContentFilter: ObservableObject {
    public static let shared = ContentFilter()
    
    @Published private var config: FilterConfig
    private let userDefaults = UserDefaults.standard
    private let configKey = "agora.content_filter.config"
    
    private init() {
        self.config = ContentFilter.loadConfig()
    }
    
    /// Updates the filter configuration
    public func updateConfig(_ newConfig: FilterConfig) {
        config = newConfig
        saveConfig()
    }
    
    /// Gets the current filter configuration
    public func getConfig() -> FilterConfig {
        return config
    }
    
    /// Filters content based on current configuration
    public func filterContent<T: FilterableContent>(_ content: T) -> FilterResult {
        // Check muted users
        if config.mutedUsers.contains(content.authorId) {
            return .hide(reason: .mutedUser(content.authorId))
        }
        
        // Check reply filtering
        if config.hideReplies && content.isReply {
            return .hide(reason: .hiddenReply)
        }
        
        // Check repost filtering
        if config.hideReposts && content.isRepost {
            return .hide(reason: .hiddenRepost)
        }
        
        // Check reported content
        if content.isReported {
            return .warn(reason: .reportedContent)
        }
        
        // Check sensitive content
        if content.isSensitive {
            return .warn(reason: .sensitiveContent)
        }
        
        // Check muted keywords
        let text = config.caseSensitive ? content.text : content.text.lowercased()
        
        for keyword in config.mutedKeywords {
            let searchKeyword = config.caseSensitive ? keyword : keyword.lowercased()
            
            if text.contains(searchKeyword) {
                return .hide(reason: .mutedKeyword(keyword))
            }
        }
        
        return .show
    }
    
    /// Adds a keyword to the mute list
    public func muteKeyword(_ keyword: String) {
        var newKeywords = config.mutedKeywords
        newKeywords.insert(keyword.trimmingCharacters(in: .whitespacesAndNewlines))
        
        let newConfig = FilterConfig(
            mutedKeywords: newKeywords,
            mutedUsers: config.mutedUsers,
            hideReplies: config.hideReplies,
            hideReposts: config.hideReposts,
            caseSensitive: config.caseSensitive
        )
        
        updateConfig(newConfig)
    }
    
    /// Removes a keyword from the mute list
    public func unmuteKeyword(_ keyword: String) {
        var newKeywords = config.mutedKeywords
        newKeywords.remove(keyword)
        
        let newConfig = FilterConfig(
            mutedKeywords: newKeywords,
            mutedUsers: config.mutedUsers,
            hideReplies: config.hideReplies,
            hideReposts: config.hideReposts,
            caseSensitive: config.caseSensitive
        )
        
        updateConfig(newConfig)
    }
    
    /// Adds a user to the mute list
    public func muteUser(_ userId: String) {
        var newUsers = config.mutedUsers
        newUsers.insert(userId)
        
        let newConfig = FilterConfig(
            mutedKeywords: config.mutedKeywords,
            mutedUsers: newUsers,
            hideReplies: config.hideReplies,
            hideReposts: config.hideReposts,
            caseSensitive: config.caseSensitive
        )
        
        updateConfig(newConfig)
    }
    
    /// Removes a user from the mute list
    public func unmuteUser(_ userId: String) {
        var newUsers = config.mutedUsers
        newUsers.remove(userId)
        
        let newConfig = FilterConfig(
            mutedKeywords: config.mutedKeywords,
            mutedUsers: newUsers,
            hideReplies: config.hideReplies,
            hideReposts: config.hideReposts,
            caseSensitive: config.caseSensitive
        )
        
        updateConfig(newConfig)
    }
    
    // MARK: - Private Methods
    
    private static func loadConfig() -> FilterConfig {
        let userDefaults = UserDefaults.standard
        let configKey = "agora.content_filter.config"
        
        guard let data = userDefaults.data(forKey: configKey),
              let config = try? JSONDecoder().decode(CodableFilterConfig.self, from: data) else {
            return FilterConfig()
        }
        
        return FilterConfig(
            mutedKeywords: Set(config.mutedKeywords),
            mutedUsers: Set(config.mutedUsers),
            hideReplies: config.hideReplies,
            hideReposts: config.hideReposts,
            caseSensitive: config.caseSensitive
        )
    }
    
    private func saveConfig() {
        let codableConfig = CodableFilterConfig(
            mutedKeywords: Array(config.mutedKeywords),
            mutedUsers: Array(config.mutedUsers),
            hideReplies: config.hideReplies,
            hideReposts: config.hideReposts,
            caseSensitive: config.caseSensitive
        )
        
        if let data = try? JSONEncoder().encode(codableConfig) {
            userDefaults.set(data, forKey: configKey)
        }
    }
}

// MARK: - Codable Support

private struct CodableFilterConfig: Codable {
    let mutedKeywords: [String]
    let mutedUsers: [String]
    let hideReplies: Bool
    let hideReposts: Bool
    let caseSensitive: Bool
}