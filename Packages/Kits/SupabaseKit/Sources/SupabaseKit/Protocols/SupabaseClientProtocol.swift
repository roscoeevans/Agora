//
//  SupabaseClientProtocol.swift
//  SupabaseKit
//
//  Protocol abstraction for Supabase client
//

import Foundation

/// Protocol abstraction for Supabase client services
/// This allows us to mock Supabase functionality for testing
public protocol SupabaseClientProtocol: Sendable {
    /// Authentication service
    var auth: SupabaseAuthProtocol { get }
    
    /// Realtime service for live updates
    var realtime: SupabaseRealtimeProtocol { get }
    
    /// Storage service for file uploads
    var storage: SupabaseStorageProtocol { get }
    
    /// Database service for direct queries
    var database: SupabaseDatabaseProtocol { get }
    
    /// Raw Supabase client for advanced usage
    /// Use this when you need access to the full Supabase API
    var rawClient: Any { get }
}

/// Authentication service protocol
public protocol SupabaseAuthProtocol: Sendable {
    /// Get current session
    var session: AuthSession? { get async }
    
    /// Sign in with Apple
    func signInWithApple(idToken: String, nonce: String) async throws -> AuthSession
    
    /// Sign out current user
    func signOut() async throws
    
    /// Refresh current session
    func refreshSession() async throws -> AuthSession
}

/// Realtime service protocol
public protocol SupabaseRealtimeProtocol: Sendable {
    /// Subscribe to post engagement updates
    func subscribeToPostEngagement(postId: String) -> AsyncStream<RealtimeEngagementUpdate>
    
    /// Subscribe to user notifications
    func subscribeToUserNotifications(userId: String) -> AsyncStream<NotificationUpdate>
    
    /// Subscribe to general table changes
    func subscribeToTable<T: Codable>(_ table: String, filter: String?) -> AsyncStream<RealtimeChange<T>>
}

/// Storage service protocol
public protocol SupabaseStorageProtocol: Sendable {
    /// Upload image to storage
    func uploadImage(data: Data, path: String) async throws -> URL
    
    /// Upload video to storage
    func uploadVideo(data: Data, path: String) async throws -> URL
    
    /// Get public URL for stored file
    func getPublicURL(path: String) throws -> URL
    
    /// Delete file from storage
    func deleteFile(path: String) async throws
}

/// Database service protocol
public protocol SupabaseDatabaseProtocol: Sendable {
    /// Fetch posts with pagination
    func fetchPosts(limit: Int, cursor: String?) async throws -> [Post]
    
    /// Create a new post
    func createPost(_ post: CreatePostRequest) async throws -> Post
    
    /// Update post engagement
    func updateEngagement(postId: String, engagement: EngagementUpdate) async throws
    
    /// Execute raw RPC function
    /// Note: Parameters must be JSON-encodable types
    func execute<T: Codable, Params: Encodable & Sendable>(_ query: String, parameters: Params) async throws -> [T]
}

// MARK: - Supporting Types

/// Authentication session
public struct AuthSession: Sendable, Codable {
    public let accessToken: String
    public let refreshToken: String
    public let expiresAt: Date
    public let user: AuthUser
    
    public init(accessToken: String, refreshToken: String, expiresAt: Date, user: AuthUser) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
        self.user = user
    }
}

/// Authenticated user
public struct AuthUser: Sendable, Codable {
    public let id: String
    public let email: String?
    public let phone: String?
    public let userMetadata: [String: AnyCodable]
    
    public init(id: String, email: String?, phone: String?, userMetadata: [String: AnyCodable] = [:]) {
        self.id = id
        self.email = email
        self.phone = phone
        self.userMetadata = userMetadata
    }
}

/// Engagement update from realtime
public struct RealtimeEngagementUpdate: Sendable, Codable {
    public let postId: String
    public let likeCount: Int
    public let repostCount: Int
    public let replyCount: Int
    public let isLiked: Bool
    public let isReposted: Bool
    
    public init(postId: String, likeCount: Int, repostCount: Int, replyCount: Int, isLiked: Bool, isReposted: Bool) {
        self.postId = postId
        self.likeCount = likeCount
        self.repostCount = repostCount
        self.replyCount = replyCount
        self.isLiked = isLiked
        self.isReposted = isReposted
    }
}

/// Notification update from realtime
public struct NotificationUpdate: Sendable, Codable {
    public let id: String
    public let type: String
    public let title: String
    public let body: String
    public let data: [String: AnyCodable]
    public let createdAt: Date
    
    public init(id: String, type: String, title: String, body: String, data: [String: AnyCodable] = [:], createdAt: Date) {
        self.id = id
        self.type = type
        self.title = title
        self.body = body
        self.data = data
        self.createdAt = createdAt
    }
}

/// Realtime change event
public struct RealtimeChange<T: Codable & Sendable>: Sendable {
    public let eventType: String
    public let table: String
    public let oldRecord: T?
    public let newRecord: T?
    
    public init(eventType: String, table: String, oldRecord: T?, newRecord: T?) {
        self.eventType = eventType
        self.table = table
        self.oldRecord = oldRecord
        self.newRecord = newRecord
    }
}

/// Create post request
public struct CreatePostRequest: Sendable, Codable {
    public let text: String
    public let mediaUrls: [String]?
    public let replyToPostId: String?
    
    public init(text: String, mediaUrls: [String]? = nil, replyToPostId: String? = nil) {
        self.text = text
        self.mediaUrls = mediaUrls
        self.replyToPostId = replyToPostId
    }
}

/// Engagement update request
public struct EngagementUpdate: Sendable, Codable {
    public let postId: String
    public let likeCount: Int
    public let repostCount: Int
    public let replyCount: Int
    
    public init(postId: String, likeCount: Int, repostCount: Int, replyCount: Int) {
        self.postId = postId
        self.likeCount = likeCount
        self.repostCount = repostCount
        self.replyCount = replyCount
    }
}

/// Database Post type for Supabase operations
/// This is a simplified version of the Post type used in the UI layer
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
    
    // Basic presentation fields
    public let authorDisplayName: String?
    public let authorAvatarUrl: String?
    public let editedAt: Date?
    public let selfDestructAt: Date?
    
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
        selfDestructAt: Date? = nil
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
    }
}

/// Post visibility levels
public enum PostVisibility: String, Sendable, Codable {
    case `public` = "public"
    case followers = "followers"
    case `private` = "private"
}

/// AnyCodable for flexible JSON handling
/// Note: Using @unchecked Sendable because we wrap Any, but usage is safe as we only support Sendable JSON types
public struct AnyCodable: Codable, @unchecked Sendable {
    public let value: Any
    
    public init(_ value: Any) {
        self.value = value
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            throw DecodingError.typeMismatch(AnyCodable.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported type"))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let string = value as? String {
            try container.encode(string)
        } else if let int = value as? Int {
            try container.encode(int)
        } else if let double = value as? Double {
            try container.encode(double)
        } else if let bool = value as? Bool {
            try container.encode(bool)
        } else if let array = value as? [Any] {
            try container.encode(array.map { AnyCodable($0) })
        } else if let dict = value as? [String: Any] {
            try container.encode(dict.mapValues { AnyCodable($0) })
        } else {
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Unsupported type"))
        }
    }
}
