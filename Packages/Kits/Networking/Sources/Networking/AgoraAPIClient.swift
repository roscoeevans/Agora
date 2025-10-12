import Foundation
import AppFoundation

/// Protocol defining the high-level API operations for Agora backend
public protocol AgoraAPIClient: AgoraAPIClientProtocol {
    // MARK: - Feed Operations
    
    /// Fetch the For You feed
    /// - Parameters:
    ///   - cursor: Pagination cursor for next page
    ///   - limit: Number of posts to return (default 20, max 50)
    /// - Returns: Feed response containing posts and next cursor
    func fetchForYouFeed(cursor: String?, limit: Int?) async throws -> FeedResponse
    
    // MARK: - Authentication Operations
    
    /// Begin Sign in with Apple flow
    /// - Parameter nonce: Random nonce for security
    /// - Returns: Authentication URL to present to user
    func beginSignInWithApple(nonce: String) async throws -> SWABeginResponse
    
    /// Complete Sign in with Apple flow
    /// - Parameters:
    ///   - identityToken: Apple identity token
    ///   - authorizationCode: Apple authorization code
    /// - Returns: Authentication result with tokens and user info
    func finishSignInWithApple(identityToken: String, authorizationCode: String) async throws -> AuthResponse
    
    // MARK: - User Profile Operations
    
    /// Create user profile after authentication
    /// - Parameter request: Profile creation request with handle and display name
    /// - Returns: Created user profile
    func createProfile(request: Components.Schemas.CreateProfileRequest) async throws -> Components.Schemas.User
    
    /// Check if handle is available
    /// - Parameter handle: Lowercase handle to check
    /// - Returns: Availability status and suggestions
    func checkHandle(handle: String) async throws -> Components.Schemas.CheckHandleResponse
    
    /// Get current user profile
    /// - Returns: Current user's profile
    func getCurrentUserProfile() async throws -> Components.Schemas.User
    
    /// Update current user profile
    /// - Parameter request: Profile update request
    /// - Returns: Updated user profile
    func updateProfile(request: Components.Schemas.UpdateProfileRequest) async throws -> Components.Schemas.User
}

// MARK: - Response Models
// These will be generated from OpenAPI spec, but we define them here for now
// Once generation is complete, these can be replaced with generated types

public struct FeedResponse: Sendable, Codable {
    public let posts: [Post]
    public let nextCursor: String?
    
    public init(posts: [Post], nextCursor: String?) {
        self.posts = posts
        self.nextCursor = nextCursor
    }
}

public struct Post: Sendable, Codable, Identifiable {
    public let id: String
    public let authorId: String
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
    
    public init(
        id: String,
        authorId: String,
        text: String,
        linkUrl: String? = nil,
        mediaBundleId: String? = nil,
        replyToPostId: String? = nil,
        quotePostId: String? = nil,
        likeCount: Int = 0,
        repostCount: Int = 0,
        replyCount: Int = 0,
        visibility: PostVisibility = .public,
        createdAt: Date
    ) {
        self.id = id
        self.authorId = authorId
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
    }
}

public enum PostVisibility: String, Sendable, Codable {
    case `public` = "public"
    case followers = "followers"
    case `private` = "private"
}

public struct SWABeginResponse: Sendable, Codable {
    public let authUrl: String
    
    public init(authUrl: String) {
        self.authUrl = authUrl
    }
}

public struct AuthResponse: Sendable, Codable {
    public let accessToken: String
    public let refreshToken: String
    public let user: User
    
    public init(accessToken: String, refreshToken: String, user: User) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.user = user
    }
}

public struct User: Sendable, Codable, Identifiable {
    public let id: String
    public let handle: String
    public let displayHandle: String
    public let displayName: String
    public let bio: String?
    public let avatarUrl: String?
    public let createdAt: Date
    
    public init(
        id: String,
        handle: String,
        displayHandle: String,
        displayName: String,
        bio: String? = nil,
        avatarUrl: String? = nil,
        createdAt: Date
    ) {
        self.id = id
        self.handle = handle
        self.displayHandle = displayHandle
        self.displayName = displayName
        self.bio = bio
        self.avatarUrl = avatarUrl
        self.createdAt = createdAt
    }
}

