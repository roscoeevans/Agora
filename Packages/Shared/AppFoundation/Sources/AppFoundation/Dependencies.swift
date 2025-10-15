import Foundation

// MARK: - API Client Protocol

/// Protocol defining the high-level API operations for Agora backend
/// This protocol is defined in AppFoundation to avoid circular dependencies.
/// The Networking Kit provides concrete implementations.
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
    func createProfile(request: CreateProfileRequest) async throws -> User
    
    /// Check if handle is available
    /// - Parameter handle: Lowercase handle to check
    /// - Returns: Availability status and suggestions
    func checkHandle(handle: String) async throws -> CheckHandleResponse
    
    /// Get current user profile
    /// - Returns: Current user's profile
    func getCurrentUserProfile() async throws -> User
    
    /// Update current user profile
    /// - Parameter request: Profile update request
    /// - Returns: Updated user profile
    func updateProfile(request: UpdateProfileRequest) async throws -> User
}

// MARK: - Response Models

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
    
    // Enhanced feed metadata (from recommendation system)
    public let score: Double?
    public let reasons: [RecommendationReason]?
    public let explore: Bool?
    
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
        score: Double? = nil,
        reasons: [RecommendationReason]? = nil,
        explore: Bool? = nil
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
        self.score = score
        self.reasons = reasons
        self.explore = explore
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

// Placeholder types for profile operations (will use Components.Schemas when available)
public struct CreateProfileRequest: Sendable, Codable {
    public let handle: String
    public let displayHandle: String
    public let displayName: String
    public let avatarUrl: String?
    
    public init(handle: String, displayHandle: String, displayName: String, avatarUrl: String? = nil) {
        self.handle = handle
        self.displayHandle = displayHandle
        self.displayName = displayName
        self.avatarUrl = avatarUrl
    }
}

public struct CheckHandleResponse: Sendable, Codable {
    public let available: Bool
    public let suggestions: [String]?
    
    public init(available: Bool, suggestions: [String]? = nil) {
        self.available = available
        self.suggestions = suggestions
    }
}

public struct UpdateProfileRequest: Sendable, Codable {
    public let displayHandle: String?
    public let displayName: String?
    public let bio: String?
    public let avatarUrl: String?
    
    public init(displayHandle: String? = nil, displayName: String? = nil, bio: String? = nil, avatarUrl: String? = nil) {
        self.displayHandle = displayHandle
        self.displayName = displayName
        self.bio = bio
        self.avatarUrl = avatarUrl
    }
}

// MARK: - Analytics Protocol

/// Protocol for analytics tracking
/// 
/// This protocol is defined in AppFoundation to avoid circular dependencies.
/// The Analytics Kit provides concrete implementations.
public protocol AnalyticsClient: Sendable {
    func track(event: String, properties: [String: Any]) async
    func identify(userId: String, properties: [String: Any]) async
    func setUserProperties(_ properties: [String: Any]) async
    func reset() async
    func flush() async
}

/// No-op analytics client for when analytics is disabled or not yet initialized
public struct NoOpAnalyticsClient: AnalyticsClient {
    public init() {}
    
    public func track(event: String, properties: [String: Any]) async {}
    public func identify(userId: String, properties: [String: Any]) async {}
    public func setUserProperties(_ properties: [String: Any]) async {}
    public func reset() async {}
    public func flush() async {}
}

// MARK: - Dependencies Container

/// Central dependency container for app-wide services
/// 
/// This container follows the DI rule pattern:
/// - Holds all app-scoped dependencies (networking, analytics, auth, etc.)
/// - Constructed once at app startup in the Composition Root
/// - Injected via SwiftUI Environment for broad access
/// - All properties are protocols, not concrete types
/// - Sendable for safe cross-actor usage
/// 
/// Usage:
/// ```swift
/// // In AgoraApp:
/// let deps = Dependencies.production
/// RootView().environment(\.deps, deps)
/// 
/// // In a view:
/// @Environment(\.deps) private var deps
/// let viewModel = ForYouViewModel(
///     networking: deps.networking,
///     analytics: deps.analytics
/// )
/// ```
public struct Dependencies: Sendable {
    // MARK: - Core Services
    
    /// Networking client for API communication
    public let networking: any AgoraAPIClient
    
    /// Authentication service
    public let auth: AuthServiceProtocol
    
    /// Analytics client (always available - uses no-op if not initialized)
    public let analytics: any AnalyticsClient
    
    /// Environment configuration (build settings, feature flags)
    public let environment: any EnvironmentConfig
    
    /// Appearance preference (light/dark mode)
    public let appearance: AppearancePreference
    
    // MARK: - Initialization
    
    public init(
        networking: any AgoraAPIClient,
        auth: AuthServiceProtocol,
        analytics: any AnalyticsClient = NoOpAnalyticsClient(),
        environment: any EnvironmentConfig,
        appearance: AppearancePreference
    ) {
        self.networking = networking
        self.auth = auth
        self.analytics = analytics
        self.environment = environment
        self.appearance = appearance
    }
}


// MARK: - Factory Methods

extension Dependencies {
    /// Production dependencies with real implementations
    public static var production: Dependencies {
        // Create networking client
        let networking: any AgoraAPIClient
        do {
            networking = try DefaultServiceFactory.apiClient() as! any AgoraAPIClient
        } catch {
            print("[Dependencies] ⚠️ Failed to create networking client: \(error)")
            print("[Dependencies]    Falling back to stub client")
            // This should never happen in production, but provides safety
            fatalError("Failed to create production networking client: \(error)")
        }
        
        // Create auth service
        let auth: AuthServiceProtocol
        do {
            auth = try DefaultServiceFactory.authService()
        } catch {
            print("[Dependencies] ⚠️ Failed to create auth service: \(error)")
            fatalError("Failed to create production auth service: \(error)")
        }
        
        // Analytics defaults to no-op; will be replaced with real implementation
        // when set via .with Analytics() method
        
        return Dependencies(
            networking: networking,
            auth: auth,
            analytics: NoOpAnalyticsClient(),
            environment: EnvironmentConfigLive(),
            appearance: AppearancePreferenceLive()
        )
    }
    
    #if DEBUG
    /// Test dependencies with fake implementations
    /// - Parameters:
    ///   - networking: Optional custom networking client (defaults to stub)
    ///   - auth: Optional custom auth service (defaults to mock)
    ///   - analytics: Optional custom analytics client (defaults to no-op)
    ///   - environment: Optional custom environment config (defaults to test config)
    ///   - appearance: Optional custom appearance preference (defaults to live with light mode)
    /// - Returns: Dependencies configured for testing
    public static func test(
        networking: (any AgoraAPIClient)? = nil,
        auth: AuthServiceProtocol? = nil,
        analytics: (any AnalyticsClient)? = nil,
        environment: (any EnvironmentConfig)? = nil,
        appearance: AppearancePreference? = nil
    ) -> Dependencies {
        return Dependencies(
            networking: networking ?? PreviewStubClient(),
            auth: auth ?? MockAuthService(),
            analytics: analytics ?? NoOpAnalyticsClient(),
            environment: environment ?? EnvironmentConfigFake(),
            appearance: appearance ?? AppearancePreferenceLive()
        )
    }
    #endif
}

// MARK: - Helpers

extension Dependencies {
    /// Returns a copy with updated analytics client
    /// This is useful for lazy initialization after Analytics module is loaded
    public func withAnalytics(_ analytics: any AnalyticsClient) -> Dependencies {
        Dependencies(
            networking: self.networking,
            auth: self.auth,
            analytics: analytics,
            environment: self.environment,
            appearance: self.appearance
        )
    }
}

// MARK: - Preview Stub Client

#if DEBUG
/// Minimal stub client for SwiftUI Previews
/// This avoids circular dependencies and network initialization issues
private final class PreviewStubClient: AgoraAPIClient {
    func fetchForYouFeed(cursor: String?, limit: Int?) async throws -> FeedResponse {
        // Return minimal mock data for previews
        let mockPosts = [
            Post(
                id: "preview-1",
                authorId: "user-1",
                authorDisplayHandle: "preview_user",
                text: "This is a preview post! 🎨",
                likeCount: 10,
                repostCount: 2,
                replyCount: 1,
                createdAt: Date().addingTimeInterval(-3600)
            ),
            Post(
                id: "preview-2",
                authorId: "user-2",
                authorDisplayHandle: "test_account",
                text: "SwiftUI Previews are working! ✨",
                likeCount: 5,
                repostCount: 0,
                replyCount: 0,
                createdAt: Date().addingTimeInterval(-7200)
            )
        ]
        return FeedResponse(posts: mockPosts, nextCursor: nil)
    }
    
    func beginSignInWithApple(nonce: String) async throws -> SWABeginResponse {
        SWABeginResponse(authUrl: "https://preview.example.com")
    }
    
    func finishSignInWithApple(identityToken: String, authorizationCode: String) async throws -> AuthResponse {
        let user = User(
            id: "preview-user",
            handle: "preview",
            displayHandle: "preview_user",
            displayName: "Preview User",
            createdAt: Date()
        )
        return AuthResponse(
            accessToken: "preview-token",
            refreshToken: "preview-refresh",
            user: user
        )
    }
    
    func createProfile(request: CreateProfileRequest) async throws -> User {
        User(
            id: "preview-user",
            handle: request.handle,
            displayHandle: request.displayHandle,
            displayName: request.displayName,
            avatarUrl: request.avatarUrl,
            createdAt: Date()
        )
    }
    
    func checkHandle(handle: String) async throws -> CheckHandleResponse {
        CheckHandleResponse(available: true, suggestions: nil)
    }
    
    func getCurrentUserProfile() async throws -> User {
        User(
            id: "preview-user",
            handle: "preview",
            displayHandle: "preview_user",
            displayName: "Preview User",
            createdAt: Date()
        )
    }
    
    func updateProfile(request: UpdateProfileRequest) async throws -> User {
        User(
            id: "preview-user",
            handle: "preview",
            displayHandle: request.displayHandle ?? "preview_user",
            displayName: request.displayName ?? "Preview User",
            bio: request.bio,
            avatarUrl: request.avatarUrl,
            createdAt: Date()
        )
    }
}
#endif

