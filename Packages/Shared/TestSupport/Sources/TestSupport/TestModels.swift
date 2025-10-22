import Foundation

// MARK: - Test Models

/// Simplified Post model for testing
public struct Post: Sendable, Codable, Identifiable {
    public let id: String
    public let authorId: String
    public let authorDisplayHandle: String
    public let text: String
    public let linkUrl: String?
    public let mediaBundleId: String?
    public let replyToPostId: String?
    public let quotePostId: String?
    public let likeCount: Int
    public let repostCount: Int
    public let replyCount: Int
    public let visibility: PostVisibility
    public let createdAt: Date
    
    // Presentation fields (for UI display)
    public let authorDisplayName: String?
    public let authorAvatarUrl: String?
    public let editedAt: Date?
    public let selfDestructAt: Date?
    
    // Enhanced feed metadata (from recommendation system)
    public let score: Double?
    public let reasons: [RecommendationReason]?
    public let explore: Bool?
    
    // Viewer interaction state (non-optional to prevent animation glitches)
    public let isLikedByViewer: Bool
    public let isRepostedByViewer: Bool
    
    public init(
        id: String,
        authorId: String,
        authorDisplayHandle: String,
        text: String,
        linkUrl: String? = nil,
        mediaBundleId: String? = nil,
        replyToPostId: String? = nil,
        quotePostId: String? = nil,
        likeCount: Int = 0,
        repostCount: Int = 0,
        replyCount: Int = 0,
        visibility: PostVisibility = .public,
        createdAt: Date,
        authorDisplayName: String? = nil,
        authorAvatarUrl: String? = nil,
        editedAt: Date? = nil,
        selfDestructAt: Date? = nil,
        score: Double? = nil,
        reasons: [RecommendationReason]? = nil,
        explore: Bool? = nil,
        isLikedByViewer: Bool = false,
        isRepostedByViewer: Bool = false
    ) {
        self.id = id
        self.authorId = authorId
        self.authorDisplayHandle = authorDisplayHandle
        self.text = text
        self.linkUrl = linkUrl
        self.mediaBundleId = mediaBundleId
        self.replyToPostId = replyToPostId
        self.quotePostId = quotePostId
        self.likeCount = likeCount
        self.repostCount = repostCount
        self.replyCount = replyCount
        self.visibility = visibility
        self.createdAt = createdAt
        self.authorDisplayName = authorDisplayName
        self.authorAvatarUrl = authorAvatarUrl
        self.editedAt = editedAt
        self.selfDestructAt = selfDestructAt
        self.score = score
        self.reasons = reasons
        self.explore = explore
        self.isLikedByViewer = isLikedByViewer
        self.isRepostedByViewer = isRepostedByViewer
    }
}

/// Recommendation reason explaining why a post was recommended
public struct RecommendationReason: Sendable, Codable {
    public let signal: String
    public let weight: Double
    
    public init(signal: String, weight: Double) {
        self.signal = signal
        self.weight = weight
    }
}

public enum PostVisibility: String, Sendable, Codable {
    case `public` = "public"
    case followers = "followers"
    case `private` = "private"
}

// MARK: - Profile Model

/// Simplified Profile model for testing
public struct Profile: Sendable, Codable, Identifiable {
    public let id: UUID
    public let handle: String
    public let displayName: String
    public let bio: String
    public let avatarURL: URL?
    public let followerCount: Int
    public let followingCount: Int
    public let postCount: Int
    
    public init(
        id: UUID,
        handle: String,
        displayName: String,
        bio: String,
        avatarURL: URL? = nil,
        followerCount: Int = 0,
        followingCount: Int = 0,
        postCount: Int = 0
    ) {
        self.id = id
        self.handle = handle
        self.displayName = displayName
        self.bio = bio
        self.avatarURL = avatarURL
        self.followerCount = followerCount
        self.followingCount = followingCount
        self.postCount = postCount
    }
}

// MARK: - Auth Token Provider for Testing

/// Protocol for providing authentication tokens to networking components.
/// This prevents circular dependencies between Auth and Networking modules.
public protocol AuthTokenProvider: Sendable {
    /// Returns the current access token if available.
    /// - Returns: The access token string, or nil if not authenticated
    /// - Throws: AuthTokenError if token retrieval fails
    func currentAccessToken() async throws -> String?
    
    /// Returns whether the user is currently authenticated.
    var isAuthenticated: Bool { get async }
}

/// Errors that can occur during token operations
public enum AuthTokenError: LocalizedError, Sendable {
    case tokenExpired
    case tokenNotFound
    case refreshFailed
    case networkError
    
    public var errorDescription: String? {
        switch self {
        case .tokenExpired:
            return "Authentication token has expired"
        case .tokenNotFound:
            return "No authentication token found"
        case .refreshFailed:
            return "Failed to refresh authentication token"
        case .networkError:
            return "Network error during token operation"
        }
    }
}
