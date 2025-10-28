import Foundation
import SupabaseKit
import Analytics

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
    
    // MARK: - Feed Operations (Extended)
    
    /// Fetch the Following feed (chronological)
    /// - Parameters:
    ///   - cursor: Pagination cursor (ISO 8601 timestamp)
    ///   - limit: Number of posts to return (default 20, max 50)
    /// - Returns: Feed response containing posts and next cursor
    func fetchFollowingFeed(cursor: String?, limit: Int?) async throws -> FollowingFeedResponse
    
    // MARK: - User Operations (Extended)
    
    /// Get user profile by ID with stats
    /// - Parameter userId: User ID (UUID string)
    /// - Returns: User profile with follower/following/post counts
    func getUserProfile(userId: String) async throws -> UserProfileWithStats
    
    /// Get posts by user ID
    /// - Parameters:
    ///   - userId: User ID (UUID string)
    ///   - cursor: Pagination cursor (ISO 8601 timestamp)
    ///   - limit: Number of posts to return (default 20, max 50)
    /// - Returns: Posts response containing user's posts
    func getUserPosts(userId: String, cursor: String?, limit: Int?) async throws -> UserPostsResponse
    
    // MARK: - Post Operations
    
    /// Create a new post
    /// - Parameters:
    ///   - text: Post text content (1-280 characters)
    ///   - mediaBundleId: Optional media bundle ID
    ///   - linkUrl: Optional link URL
    ///   - quotePostId: Optional ID of post being quoted
    ///   - replyToPostId: Optional ID of post being replied to
    ///   - selfDestructAt: Optional self-destruct timestamp
    /// - Returns: Created post
    func createPost(
        text: String,
        mediaBundleId: String?,
        linkUrl: String?,
        quotePostId: String?,
        replyToPostId: String?,
        selfDestructAt: Date?
    ) async throws -> Post
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

public struct FollowingFeedResponse: Sendable, Codable {
    public let posts: [Post]
    public let nextCursor: String?
    
    public init(posts: [Post], nextCursor: String?) {
        self.posts = posts
        self.nextCursor = nextCursor
    }
}

public struct UserProfileWithStats: Sendable, Codable {
    public let id: String
    public let handle: String
    public let displayHandle: String
    public let displayName: String
    public let bio: String?
    public let avatarUrl: String?
    public let createdAt: Date
    public let followerCount: Int
    public let followingCount: Int
    public let postCount: Int
    public let isCurrentUser: Bool
    public let isFollowing: Bool
    
    public init(
        id: String,
        handle: String,
        displayHandle: String,
        displayName: String,
        bio: String? = nil,
        avatarUrl: String? = nil,
        createdAt: Date,
        followerCount: Int,
        followingCount: Int,
        postCount: Int,
        isCurrentUser: Bool,
        isFollowing: Bool
    ) {
        self.id = id
        self.handle = handle
        self.displayHandle = displayHandle
        self.displayName = displayName
        self.bio = bio
        self.avatarUrl = avatarUrl
        self.createdAt = createdAt
        self.followerCount = followerCount
        self.followingCount = followingCount
        self.postCount = postCount
        self.isCurrentUser = isCurrentUser
        self.isFollowing = isFollowing
    }
}

public struct UserPostsResponse: Sendable, Codable {
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
    public let handle: String?
    public let displayHandle: String?
    public let displayName: String?
    public let bio: String?
    public let avatarUrl: String?
    
    public init(handle: String? = nil, displayHandle: String? = nil, displayName: String? = nil, bio: String? = nil, avatarUrl: String? = nil) {
        self.handle = handle
        self.displayHandle = displayHandle
        self.displayName = displayName
        self.bio = bio
        self.avatarUrl = avatarUrl
    }
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
    
    /// Event tracker for type-safe analytics events
    public let eventTracker: EventTracker?
    
    /// Environment configuration (build settings, feature flags)
    public let environment: any EnvironmentConfig
    
    /// Appearance preference (light/dark mode)
    public let appearance: AppearancePreference
    
    /// Engagement service (likes, reposts, shares)
    public let engagement: (any EngagementService)?
    
    /// Supabase client for real-time subscriptions and direct database access
    public let supabase: (any SupabaseClientProtocol)?
    
    /// Comment composition service for creating comment sheets
    public let commentComposition: CommentCompositionProtocol?
    
    /// Media bundle service for fetching and managing media bundles
    public let mediaBundle: MediaBundleServiceProtocol?
    
    /// Messaging service for conversations and messages
    public let messaging: MessagingServiceProtocol?
    
    /// Real-time messaging service for subscriptions and events
    public let messagingRealtime: MessagingRealtimeProtocol?
    
    /// Messaging media service for attachment handling
    public let messagingMedia: MessagingMediaProtocol?
    
    /// Push notification service for handling notifications
    public let pushNotifications: PushNotificationServiceProtocol?
    
    /// Image crop rendering service for avatar processing
    public let imageCropRendering: ImageCropRendering?
    
    /// Avatar upload service for profile picture management
    public let avatarUploadService: AvatarUploadService?
    
    /// User search service for searching users by handle/name
    public let userSearch: UserSearchProtocol?
    
    // MARK: - Initialization
    
    public init(
        networking: any AgoraAPIClient,
        auth: AuthServiceProtocol,
        analytics: any AnalyticsClient = NoOpAnalyticsClient(),
        environment: any EnvironmentConfig,
        appearance: AppearancePreference,
        engagement: (any EngagementService)? = nil,
        supabase: (any SupabaseClientProtocol)? = nil,
        commentComposition: CommentCompositionProtocol? = nil,
        mediaBundle: MediaBundleServiceProtocol? = nil,
        messaging: MessagingServiceProtocol? = nil,
        messagingRealtime: MessagingRealtimeProtocol? = nil,
        messagingMedia: MessagingMediaProtocol? = nil,
        eventTracker: EventTracker? = nil,
        pushNotifications: PushNotificationServiceProtocol? = nil,
        imageCropRendering: ImageCropRendering? = nil,
        avatarUploadService: AvatarUploadService? = nil,
        userSearch: UserSearchProtocol? = nil
    ) {
        self.networking = networking
        self.auth = auth
        self.analytics = analytics
        self.environment = environment
        self.appearance = appearance
        self.engagement = engagement
        self.supabase = supabase
        self.commentComposition = commentComposition
        self.mediaBundle = mediaBundle
        self.messaging = messaging
        self.messagingRealtime = messagingRealtime
        self.messagingMedia = messagingMedia
        self.eventTracker = eventTracker
        self.pushNotifications = pushNotifications
        self.imageCropRendering = imageCropRendering
        self.avatarUploadService = avatarUploadService
        self.userSearch = userSearch
    }
}


// MARK: - Factory Methods

extension Dependencies {
    /// Production dependencies with real implementations
    public static var production: Dependencies {
        #if DEBUG
        // Safety check: If we're in a preview environment, return test dependencies
        // This prevents crashes when previews accidentally call .production
        let env = ProcessInfo.processInfo.environment
        if env["XCODE_RUNNING_FOR_PREVIEWS"] == "1" || env["XCODE_RUNNING_FOR_PLAYGROUNDS"] == "1" {
            print("[Dependencies] ⚠️ Production dependencies requested in preview environment")
            print("[Dependencies]    Returning test dependencies instead")
            return .test()
        }
        #endif
        
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
        
        // Create comment composition service
        let commentComposition: CommentCompositionProtocol
        do {
            commentComposition = try DefaultServiceFactory.commentCompositionService()
        } catch {
            print("[Dependencies] ⚠️ Failed to create comment composition service: \(error)")
            commentComposition = NoOpCommentCompositionService()
        }
        
        // Create media bundle service
        let mediaBundle: MediaBundleServiceProtocol
        do {
            mediaBundle = try DefaultServiceFactory.mediaBundleService()
        } catch {
            print("[Dependencies] ⚠️ Failed to create media bundle service: \(error)")
            mediaBundle = NoOpMediaBundleService()
        }
        
        // Create real avatar cropper services
        let imageCropRendering: ImageCropRendering = {
            do {
                return try DefaultServiceFactory.imageCropRenderer()
            } catch {
                print("[Dependencies] ⚠️ Failed to create avatar cropper services: \(error)")
                print("[Dependencies]    Falling back to no-op implementations")
                return NoOpImageCropRenderer()
            }
        }()
        
        let avatarUploadService: AvatarUploadService = {
            do {
                return try DefaultServiceFactory.avatarUploadService()
            } catch {
                print("[Dependencies] ⚠️ Failed to create avatar upload service: \(error)")
                print("[Dependencies]    Falling back to no-op implementation")
                return NoOpAvatarUploadService()
            }
        }()
        
        return Dependencies(
            networking: networking,
            auth: auth,
            analytics: NoOpAnalyticsClient(),
            environment: EnvironmentConfigLive(),
            appearance: AppearancePreferenceLive(),
            commentComposition: commentComposition,
            mediaBundle: mediaBundle,
            eventTracker: EventTracker(analyticsClient: NoOpAnalyticsClient()),
            pushNotifications: NoOpPushNotificationService(),
            imageCropRendering: imageCropRendering,
            avatarUploadService: avatarUploadService
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
        appearance: AppearancePreference? = nil,
        commentComposition: CommentCompositionProtocol? = nil,
        mediaBundle: MediaBundleServiceProtocol? = nil,
        messaging: MessagingServiceProtocol? = nil,
        messagingRealtime: MessagingRealtimeProtocol? = nil,
        messagingMedia: MessagingMediaProtocol? = nil,
        eventTracker: EventTracker? = nil,
        pushNotifications: PushNotificationServiceProtocol? = nil,
        imageCropRendering: ImageCropRendering? = nil,
        avatarUploadService: AvatarUploadService? = nil
    ) -> Dependencies {
        return Dependencies(
            networking: networking ?? PreviewStubClient(),
            auth: auth ?? MockAuthService(),
            analytics: analytics ?? NoOpAnalyticsClient(),
            environment: environment ?? EnvironmentConfigFake(),
            appearance: appearance ?? AppearancePreferenceLive(),
            commentComposition: commentComposition ?? NoOpCommentCompositionService(),
            mediaBundle: mediaBundle ?? NoOpMediaBundleService(),
            messaging: messaging,
            messagingRealtime: messagingRealtime,
            messagingMedia: messagingMedia,
            eventTracker: eventTracker,
            pushNotifications: pushNotifications ?? NoOpPushNotificationService(),
            imageCropRendering: imageCropRendering ?? NoOpImageCropRenderer(),
            avatarUploadService: avatarUploadService ?? NoOpAvatarUploadService()
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
            appearance: self.appearance,
            engagement: self.engagement,
            supabase: self.supabase,
            commentComposition: self.commentComposition,
            mediaBundle: self.mediaBundle,
            messaging: self.messaging,
            messagingRealtime: self.messagingRealtime,
            messagingMedia: self.messagingMedia,
            eventTracker: EventTracker(analyticsClient: analytics),
            pushNotifications: self.pushNotifications,
            imageCropRendering: self.imageCropRendering,
            avatarUploadService: self.avatarUploadService
        )
    }
    
    /// Returns a copy with updated engagement service
    /// This is useful for lazy initialization after Engagement module is loaded
    public func withEngagement(_ engagement: any EngagementService) -> Dependencies {
        Dependencies(
            networking: self.networking,
            auth: self.auth,
            analytics: self.analytics,
            environment: self.environment,
            appearance: self.appearance,
            engagement: engagement,
            supabase: self.supabase,
            commentComposition: self.commentComposition,
            mediaBundle: self.mediaBundle,
            messaging: self.messaging,
            messagingRealtime: self.messagingRealtime,
            messagingMedia: self.messagingMedia,
            eventTracker: self.eventTracker,
            pushNotifications: self.pushNotifications,
            imageCropRendering: self.imageCropRendering,
            avatarUploadService: self.avatarUploadService
        )
    }
    
    /// Returns a copy with updated Supabase client
    public func withSupabase(_ supabase: any SupabaseClientProtocol) -> Dependencies {
        Dependencies(
            networking: self.networking,
            auth: self.auth,
            analytics: self.analytics,
            environment: self.environment,
            appearance: self.appearance,
            engagement: self.engagement,
            supabase: supabase,
            commentComposition: self.commentComposition,
            mediaBundle: self.mediaBundle,
            messaging: self.messaging,
            messagingRealtime: self.messagingRealtime,
            messagingMedia: self.messagingMedia,
            eventTracker: self.eventTracker,
            pushNotifications: self.pushNotifications,
            imageCropRendering: self.imageCropRendering,
            avatarUploadService: self.avatarUploadService
        )
    }
    
    /// Returns a copy with updated comment composition service
    public func withCommentComposition(_ commentComposition: CommentCompositionProtocol) -> Dependencies {
        Dependencies(
            networking: self.networking,
            auth: self.auth,
            analytics: self.analytics,
            environment: self.environment,
            appearance: self.appearance,
            engagement: self.engagement,
            supabase: self.supabase,
            commentComposition: commentComposition,
            mediaBundle: self.mediaBundle,
            messaging: self.messaging,
            messagingRealtime: self.messagingRealtime,
            messagingMedia: self.messagingMedia,
            eventTracker: self.eventTracker,
            pushNotifications: self.pushNotifications,
            imageCropRendering: self.imageCropRendering,
            avatarUploadService: self.avatarUploadService
        )
    }
    
    /// Returns a copy with updated media bundle service
    public func withMediaBundle(_ mediaBundle: MediaBundleServiceProtocol) -> Dependencies {
        Dependencies(
            networking: self.networking,
            auth: self.auth,
            analytics: self.analytics,
            environment: self.environment,
            appearance: self.appearance,
            engagement: self.engagement,
            supabase: self.supabase,
            commentComposition: self.commentComposition,
            mediaBundle: mediaBundle,
            messaging: self.messaging,
            messagingRealtime: self.messagingRealtime,
            messagingMedia: self.messagingMedia,
            eventTracker: self.eventTracker,
            pushNotifications: self.pushNotifications,
            imageCropRendering: self.imageCropRendering,
            avatarUploadService: self.avatarUploadService
        )
    }
    
    /// Returns a copy with updated messaging services
    public func withMessaging(
        messaging: MessagingServiceProtocol,
        realtime: MessagingRealtimeProtocol,
        media: MessagingMediaProtocol
    ) -> Dependencies {
        Dependencies(
            networking: self.networking,
            auth: self.auth,
            analytics: self.analytics,
            environment: self.environment,
            appearance: self.appearance,
            engagement: self.engagement,
            supabase: self.supabase,
            commentComposition: self.commentComposition,
            mediaBundle: self.mediaBundle,
            messaging: messaging,
            messagingRealtime: realtime,
            messagingMedia: media,
            eventTracker: self.eventTracker,
            pushNotifications: self.pushNotifications,
            imageCropRendering: self.imageCropRendering,
            avatarUploadService: self.avatarUploadService
        )
    }
    
    /// Returns a copy with updated image crop rendering service
    public func withImageCropRendering(_ imageCropRendering: ImageCropRendering) -> Dependencies {
        Dependencies(
            networking: self.networking,
            auth: self.auth,
            analytics: self.analytics,
            environment: self.environment,
            appearance: self.appearance,
            engagement: self.engagement,
            supabase: self.supabase,
            commentComposition: self.commentComposition,
            mediaBundle: self.mediaBundle,
            messaging: self.messaging,
            messagingRealtime: self.messagingRealtime,
            messagingMedia: self.messagingMedia,
            eventTracker: self.eventTracker,
            pushNotifications: self.pushNotifications,
            imageCropRendering: imageCropRendering,
            avatarUploadService: self.avatarUploadService
        )
    }
    
    /// Returns a copy with updated avatar upload service
    public func withAvatarUploadService(_ avatarUploadService: AvatarUploadService) -> Dependencies {
        Dependencies(
            networking: self.networking,
            auth: self.auth,
            analytics: self.analytics,
            environment: self.environment,
            appearance: self.appearance,
            engagement: self.engagement,
            supabase: self.supabase,
            commentComposition: self.commentComposition,
            mediaBundle: self.mediaBundle,
            messaging: self.messaging,
            messagingRealtime: self.messagingRealtime,
            messagingMedia: self.messagingMedia,
            eventTracker: self.eventTracker,
            pushNotifications: self.pushNotifications,
            imageCropRendering: self.imageCropRendering,
            avatarUploadService: avatarUploadService
        )
    }
    
    /// Returns a copy with updated avatar cropper services
    public func withAvatarCropper(
        imageCropRendering: ImageCropRendering,
        avatarUploadService: AvatarUploadService
    ) -> Dependencies {
        Dependencies(
            networking: self.networking,
            auth: self.auth,
            analytics: self.analytics,
            environment: self.environment,
            appearance: self.appearance,
            engagement: self.engagement,
            supabase: self.supabase,
            commentComposition: self.commentComposition,
            mediaBundle: self.mediaBundle,
            messaging: self.messaging,
            messagingRealtime: self.messagingRealtime,
            messagingMedia: self.messagingMedia,
            eventTracker: self.eventTracker,
            pushNotifications: self.pushNotifications,
            imageCropRendering: imageCropRendering,
            avatarUploadService: avatarUploadService
        )
    }
    
    /// Returns a new Dependencies container with user search service
    /// - Parameter userSearch: The user search service to inject
    /// - Returns: New Dependencies container with updated user search
    public func withUserSearch(_ userSearch: UserSearchProtocol) -> Dependencies {
        Dependencies(
            networking: self.networking,
            auth: self.auth,
            analytics: self.analytics,
            environment: self.environment,
            appearance: self.appearance,
            engagement: self.engagement,
            supabase: self.supabase,
            commentComposition: self.commentComposition,
            mediaBundle: self.mediaBundle,
            messaging: self.messaging,
            messagingRealtime: self.messagingRealtime,
            messagingMedia: self.messagingMedia,
            eventTracker: self.eventTracker,
            pushNotifications: self.pushNotifications,
            imageCropRendering: self.imageCropRendering,
            avatarUploadService: self.avatarUploadService,
            userSearch: userSearch
        )
    }
}

// MARK: - Preview Stub Client

#if DEBUG
/// Minimal stub client for SwiftUI Previews
/// This avoids circular dependencies and network initialization issues
private final class PreviewStubClient: AgoraAPIClient {
    func fetchForYouFeed(cursor: String?, limit: Int?) async throws -> FeedResponse {
        // Return minimal mock data for previews with varying post lengths
        let mockPosts = [
            Post(
                id: "preview-1",
                authorId: "user-1",
                authorDisplayHandle: "preview_user",
                text: "This is a preview post! 🫔",
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
            ),
            Post(
                id: "preview-3",
                authorId: "user-789",
                authorDisplayHandle: "dev_account",
                text: "Stub client is great for offline development! 💡",
                linkUrl: "https://example.com",
                likeCount: 28,
                repostCount: 5,
                replyCount: 8,
                createdAt: Date().addingTimeInterval(-10800)
            ),
            Post(
                id: "preview-4",
                authorId: "user-101",
                authorDisplayHandle: "swift.ui.master",
                text: """
                Really loving SwiftUI's latest updates! The declarative syntax makes building complex UIs so much more enjoyable.
                
                Can't wait to see what's next! 🎨✨
                """,
                likeCount: 89,
                repostCount: 12,
                replyCount: 15,
                createdAt: Date().addingTimeInterval(-14400),
                authorDisplayName: "Swift UI Master"
            ),
            Post(
                id: "preview-5",
                authorId: "user-202",
                authorDisplayHandle: "minimalist",
                text: "Less is more. ✨",
                likeCount: 234,
                repostCount: 45,
                replyCount: 67,
                createdAt: Date().addingTimeInterval(-18000)
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
    
    func fetchFollowingFeed(cursor: String?, limit: Int?) async throws -> FollowingFeedResponse {
        FollowingFeedResponse(posts: [], nextCursor: nil)
    }
    
    func getUserProfile(userId: String) async throws -> UserProfileWithStats {
        UserProfileWithStats(
            id: userId,
            handle: "preview",
            displayHandle: "preview_user",
            displayName: "Preview User",
            bio: "This is a preview profile",
            avatarUrl: nil,
            createdAt: Date(),
            followerCount: 42,
            followingCount: 123,
            postCount: 89,
            isCurrentUser: false,
            isFollowing: false
        )
    }
    
    func getUserPosts(userId: String, cursor: String?, limit: Int?) async throws -> UserPostsResponse {
        UserPostsResponse(posts: [], nextCursor: nil)
    }
    
    func createPost(
        text: String,
        mediaBundleId: String?,
        linkUrl: String?,
        quotePostId: String?,
        replyToPostId: String?,
        selfDestructAt: Date?
    ) async throws -> Post {
        Post(
            id: "preview-post-\(UUID().uuidString)",
            authorId: "preview-user",
            authorDisplayHandle: "preview_user",
            text: text,
            linkUrl: linkUrl,
            mediaBundleId: mediaBundleId,
            replyToPostId: replyToPostId,
            quotePostId: quotePostId,
            likeCount: 0,
            repostCount: 0,
            replyCount: 0,
            visibility: .public,
            createdAt: Date(),
            authorDisplayName: "Preview User",
            selfDestructAt: selfDestructAt
        )
    }
}
#endif

