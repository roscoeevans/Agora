import Foundation

/// Feed item types for mixing
public enum FeedItemType {
    case post(PostItem)
    case ad(AdItem)
    case suggestion(SuggestionItem)
    case separator(SeparatorItem)
}

/// Post item in feed
public struct PostItem {
    public let id: String
    public let authorId: String
    public let content: String
    public let score: Double
    public let timestamp: Date
    public let mediaCount: Int
    public let isRepost: Bool
    public let originalPostId: String?
    
    public init(
        id: String,
        authorId: String,
        content: String,
        score: Double,
        timestamp: Date,
        mediaCount: Int = 0,
        isRepost: Bool = false,
        originalPostId: String? = nil
    ) {
        self.id = id
        self.authorId = authorId
        self.content = content
        self.score = score
        self.timestamp = timestamp
        self.mediaCount = mediaCount
        self.isRepost = isRepost
        self.originalPostId = originalPostId
    }
}

/// Ad item in feed
public struct AdItem {
    public let id: String
    public let campaignId: String
    public let content: String
    public let targetingScore: Double
    public let bidAmount: Double
    
    public init(id: String, campaignId: String, content: String, targetingScore: Double, bidAmount: Double) {
        self.id = id
        self.campaignId = campaignId
        self.content = content
        self.targetingScore = targetingScore
        self.bidAmount = bidAmount
    }
}

/// Suggestion item in feed (follow suggestions, etc.)
public struct SuggestionItem {
    public let id: String
    public let type: SuggestionType
    public let userId: String?
    public let title: String
    public let description: String
    public let relevanceScore: Double
    
    public init(id: String, type: SuggestionType, userId: String? = nil, title: String, description: String, relevanceScore: Double) {
        self.id = id
        self.type = type
        self.userId = userId
        self.title = title
        self.description = description
        self.relevanceScore = relevanceScore
    }
}

/// Separator item for visual breaks
public struct SeparatorItem {
    public let id: String
    public let type: SeparatorType
    
    public init(id: String, type: SeparatorType) {
        self.id = id
        self.type = type
    }
}

/// Types of suggestions
public enum SuggestionType {
    case followUser
    case joinTopic
    case enableNotifications
    case inviteFriends
}

/// Types of separators
public enum SeparatorType {
    case timeBased
    case topicChange
    case adBreak
}

/// Feed mixing configuration
public struct FeedMixingConfig {
    public let maxAdFrequency: Int // Max ads per N posts
    public let minPostsBetweenAds: Int
    public let suggestionFrequency: Int // Suggestions per N posts
    public let diversityThreshold: Double // Minimum diversity score
    public let recencyWeight: Double // Weight for recent posts
    public let qualityThreshold: Double // Minimum quality score
    
    public init(
        maxAdFrequency: Int = 5, // 1 ad per 5 posts
        minPostsBetweenAds: Int = 3,
        suggestionFrequency: Int = 10, // 1 suggestion per 10 posts
        diversityThreshold: Double = 0.3,
        recencyWeight: Double = 0.2,
        qualityThreshold: Double = 0.1
    ) {
        self.maxAdFrequency = maxAdFrequency
        self.minPostsBetweenAds = minPostsBetweenAds
        self.suggestionFrequency = suggestionFrequency
        self.diversityThreshold = diversityThreshold
        self.recencyWeight = recencyWeight
        self.qualityThreshold = qualityThreshold
    }
    
    public static let `default` = FeedMixingConfig()
}

/// Feed mixer for UI mixing (all scoring happens server-side)
public final class FeedMixer: Sendable {
    public static let shared = FeedMixer()
    
    private let config: FeedMixingConfig
    
    private init(config: FeedMixingConfig = .default) {
        self.config = config
    }
    
    /// Mixes posts, ads, and suggestions into a cohesive feed
    public func mixFeed(
        posts: [PostItem],
        ads: [AdItem] = [],
        suggestions: [SuggestionItem] = []
    ) -> [FeedItemType] {
        var mixedFeed: [FeedItemType] = []
        var postIndex = 0
        var adIndex = 0
        var suggestionIndex = 0
        var postsSinceLastAd = 0
        var postsSinceLastSuggestion = 0
        
        // Sort posts by score (server-side scoring)
        let sortedPosts = posts.sorted { $0.score > $1.score }
        
        while postIndex < sortedPosts.count {
            let post = sortedPosts[postIndex]
            
            // Add post
            mixedFeed.append(.post(post))
            postIndex += 1
            postsSinceLastAd += 1
            postsSinceLastSuggestion += 1
            
            // Check if we should add an ad
            if shouldInsertAd(
                postsSinceLastAd: postsSinceLastAd,
                adIndex: adIndex,
                totalAds: ads.count
            ) {
                if adIndex < ads.count {
                    mixedFeed.append(.ad(ads[adIndex]))
                    adIndex += 1
                    postsSinceLastAd = 0
                }
            }
            
            // Check if we should add a suggestion
            if shouldInsertSuggestion(
                postsSinceLastSuggestion: postsSinceLastSuggestion,
                suggestionIndex: suggestionIndex,
                totalSuggestions: suggestions.count
            ) {
                if suggestionIndex < suggestions.count {
                    mixedFeed.append(.suggestion(suggestions[suggestionIndex]))
                    suggestionIndex += 1
                    postsSinceLastSuggestion = 0
                }
            }
            
            // Add separator if needed
            if shouldInsertSeparator(currentIndex: mixedFeed.count - 1, posts: sortedPosts) {
                let separator = SeparatorItem(
                    id: "sep_\(mixedFeed.count)",
                    type: .timeBased
                )
                mixedFeed.append(.separator(separator))
            }
        }
        
        return mixedFeed
    }
    
    /// Applies diversity filtering to ensure content variety
    public func applyDiversityFilter(posts: [PostItem]) -> [PostItem] {
        var filteredPosts: [PostItem] = []
        var recentAuthors: Set<String> = []
        let maxSameAuthor = 2 // Max consecutive posts from same author
        
        for post in posts {
            // Check author diversity
            if recentAuthors.count < maxSameAuthor || !recentAuthors.contains(post.authorId) {
                filteredPosts.append(post)
                recentAuthors.insert(post.authorId)
                
                // Keep only recent authors for diversity check
                if recentAuthors.count > maxSameAuthor {
                    recentAuthors.removeFirst()
                }
            }
        }
        
        return filteredPosts
    }
    
    /// Filters posts by quality threshold
    public func filterByQuality(posts: [PostItem]) -> [PostItem] {
        return posts.filter { $0.score >= config.qualityThreshold }
    }
    
    /// Boosts recent posts based on recency weight
    public func applyRecencyBoost(posts: [PostItem]) -> [PostItem] {
        let now = Date()
        
        return posts.map { post in
            let timeDiff = now.timeIntervalSince(post.timestamp)
            let hoursSince = timeDiff / 3600
            
            // Boost recent posts (within 24 hours)
            let recencyBoost = hoursSince < 24 ? (24 - hoursSince) / 24 * config.recencyWeight : 0
            let boostedScore = post.score + recencyBoost
            
            return PostItem(
                id: post.id,
                authorId: post.authorId,
                content: post.content,
                score: boostedScore,
                timestamp: post.timestamp,
                mediaCount: post.mediaCount,
                isRepost: post.isRepost,
                originalPostId: post.originalPostId
            )
        }
    }
    
    // MARK: - Private Methods
    
    private func shouldInsertAd(postsSinceLastAd: Int, adIndex: Int, totalAds: Int) -> Bool {
        return postsSinceLastAd >= config.maxAdFrequency &&
               postsSinceLastAd >= config.minPostsBetweenAds &&
               adIndex < totalAds
    }
    
    private func shouldInsertSuggestion(postsSinceLastSuggestion: Int, suggestionIndex: Int, totalSuggestions: Int) -> Bool {
        return postsSinceLastSuggestion >= config.suggestionFrequency &&
               suggestionIndex < totalSuggestions
    }
    
    private func shouldInsertSeparator(currentIndex: Int, posts: [PostItem]) -> Bool {
        // Add separator every 20 items for visual breaks
        return currentIndex > 0 && currentIndex % 20 == 0
    }
}