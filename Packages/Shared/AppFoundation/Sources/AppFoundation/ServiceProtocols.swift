import Foundation
import AuthenticationServices
import CoreGraphics

// MARK: - Authentication Service Protocol

/// Protocol for authentication services handling Sign in with Apple and session management
public protocol AuthServiceProtocol: AuthTokenProvider {
    /// Initiates Sign in with Apple flow
    /// - Returns: Authentication result containing user information and tokens
    /// - Throws: AuthError if authentication fails
    func signInWithApple() async throws -> AuthResult
    
    /// Signs out the current user
    /// - Throws: AuthError if sign out fails
    func signOut() async throws
    
    /// Refreshes the current authentication token
    /// - Returns: New access token
    /// - Throws: AuthError if refresh fails
    func refreshToken() async throws -> String
    
    /// Gets the current access token if available
    /// - Returns: Current access token or nil if not authenticated
    /// - Throws: AuthError if token retrieval fails
    func currentAccessToken() async throws -> String?
    
    /// Whether the user is currently authenticated
    var isAuthenticated: Bool { get async }
}

// MARK: - Phone Verification Service Protocol

/// Protocol for phone verification services
public protocol PhoneVerifierProtocol: Sendable {
    /// Sends a verification code to the specified phone number
    /// - Parameter phoneNumber: The phone number to verify (E.164 format)
    /// - Returns: Verification session ID for tracking the verification
    /// - Throws: PhoneVerificationError if sending fails
    func sendVerificationCode(to phoneNumber: String) async throws -> String
    
    /// Verifies the code entered by the user
    /// - Parameters:
    ///   - code: The verification code entered by the user
    ///   - sessionId: The session ID returned from sendVerificationCode
    /// - Returns: True if verification is successful
    /// - Throws: PhoneVerificationError if verification fails
    func verifyCode(_ code: String, sessionId: String) async throws -> Bool
    
    /// Checks the current verification status
    /// - Parameter sessionId: The session ID to check
    /// - Returns: Current verification status
    /// - Throws: PhoneVerificationError if status check fails
    func getVerificationStatus(sessionId: String) async throws -> VerificationStatus
}

// MARK: - Captcha Service Protocol

/// Protocol for captcha challenge services
public protocol CaptchaServiceProtocol: Sendable {
    /// Presents a captcha challenge to the user
    /// - Returns: Captcha token if challenge is completed successfully
    /// - Throws: CaptchaError if challenge fails or is cancelled
    func presentCaptcha() async throws -> String
    
    /// Verifies a captcha token with the service
    /// - Parameter token: The captcha token to verify
    /// - Returns: True if token is valid
    /// - Throws: CaptchaError if verification fails
    func verifyCaptcha(token: String) async throws -> Bool
    
    /// Checks if captcha is required for the current context
    /// - Returns: True if captcha challenge should be presented
    func isCaptchaRequired() async -> Bool
}

// MARK: - Supporting Types

/// Authentication result containing user information and tokens
public struct AuthResult: Sendable {
    public let user: AuthenticatedUser
    public let accessToken: String
    public let refreshToken: String?
    public let expiresAt: Date?
    
    public init(
        user: AuthenticatedUser,
        accessToken: String,
        refreshToken: String? = nil,
        expiresAt: Date? = nil
    ) {
        self.user = user
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
    }
}

/// Authenticated user information
public struct AuthenticatedUser: Sendable, Codable {
    public let id: String
    public let email: String?
    public let fullName: PersonNameComponents?
    
    public init(id: String, email: String?, fullName: PersonNameComponents?) {
        self.id = id
        self.email = email
        self.fullName = fullName
    }
}

/// Phone verification status
public enum VerificationStatus: String, Sendable, CaseIterable {
    case pending = "pending"
    case approved = "approved"
    case canceled = "canceled"
    case expired = "expired"
}

// MARK: - Error Types

/// Authentication errors
public enum AuthError: LocalizedError, Sendable {
    case notAuthenticated
    case invalidCredentials
    case signInCancelled
    case signInFailed(Error)
    case sessionExpired
    case refreshFailed
    case networkError
    
    public var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User is not authenticated"
        case .invalidCredentials:
            return "Invalid authentication credentials"
        case .signInCancelled:
            return "Sign in was cancelled"
        case .signInFailed(let error):
            return "Sign in failed: \(error.localizedDescription)"
        case .sessionExpired:
            return "Authentication session has expired"
        case .refreshFailed:
            return "Failed to refresh authentication token"
        case .networkError:
            return "Network error occurred during authentication"
        }
    }
}

/// Phone verification errors
public enum PhoneVerificationError: LocalizedError, Sendable {
    case invalidPhoneNumber
    case sendFailed(Int)
    case verificationFailed(Int)
    case statusCheckFailed(Int)
    case networkError
    case invalidCode
    case sessionExpired
    case tooManyAttempts
    case serviceUnavailable
    
    public var errorDescription: String? {
        switch self {
        case .invalidPhoneNumber:
            return "Invalid phone number format"
        case .sendFailed(let code):
            return "Failed to send verification code (HTTP \(code))"
        case .verificationFailed(let code):
            return "Verification failed (HTTP \(code))"
        case .statusCheckFailed(let code):
            return "Status check failed (HTTP \(code))"
        case .networkError:
            return "Network error occurred"
        case .invalidCode:
            return "Invalid verification code"
        case .sessionExpired:
            return "Verification session has expired"
        case .tooManyAttempts:
            return "Too many verification attempts. Please try again later."
        case .serviceUnavailable:
            return "Phone verification service is currently unavailable"
        }
    }
}

/// Captcha errors
public enum CaptchaError: LocalizedError, Sendable {
    case challengeCancelled
    case challengeFailed
    case networkError
    case invalidToken
    case serviceUnavailable
    case configurationError
    
    public var errorDescription: String? {
        switch self {
        case .challengeCancelled:
            return "Captcha challenge was cancelled"
        case .challengeFailed:
            return "Captcha challenge failed"
        case .networkError:
            return "Network error occurred during captcha verification"
        case .invalidToken:
            return "Invalid captcha token"
        case .serviceUnavailable:
            return "Captcha service is currently unavailable"
        case .configurationError:
            return "Captcha service configuration error"
        }
    }
}

// MARK: - User Search Protocol

/// Protocol for user search functionality
public protocol UserSearchProtocol: Sendable {
    /// Search for users matching a query
    /// - Parameters:
    ///   - q: Search query string (supports "@handle" for exact matches)
    ///   - limit: Maximum number of results to return (default: 20)
    ///   - after: Cursor for pagination (handle of last result from previous page)
    /// - Returns: Array of SearchUser results sorted by relevance + popularity
    /// - Throws: UserSearchError if search fails
    func search(q: String, limit: Int, after: String?) async throws -> [SearchUser]
    
    /// Get suggested creators (popular users to follow)
    /// - Parameter limit: Maximum number of suggestions to return (default: 20)
    /// - Returns: Array of SearchUser results sorted by popularity
    /// - Throws: UserSearchError if request fails
    func suggestedCreators(limit: Int) async throws -> [SearchUser]
    
    /// Look up a user by exact handle
    /// - Parameter handle: User handle (with or without "@" prefix)
    /// - Returns: SearchUser if found, nil if not found
    /// - Throws: UserSearchError if lookup fails
    func lookupByHandle(_ handle: String) async throws -> SearchUser?
}

/// Represents a user returned from search results
public struct SearchUser: Codable, Identifiable, Sendable, Hashable {
    /// Unique user identifier
    public let userId: UUID
    
    /// Conform to Identifiable
    public var id: UUID { userId }
    
    /// Canonical lowercase handle (e.g., "rocky.evans")
    public let handle: String
    
    /// User's preferred capitalization (e.g., "Rocky.Evans")
    public let displayHandle: String
    
    /// User's display name
    public let displayName: String
    
    /// Avatar URL (Cloudflare Images variant URL)
    public let avatarUrl: String?
    
    /// Trust level (0-3)
    public let trustLevel: Int
    
    /// Verified badge
    public let verified: Bool
    
    /// Cached follower count (for popularity ranking)
    public let followersCount: Int
    
    /// Last activity timestamp
    public let lastActiveAt: Date?
    
    /// Search relevance score (internal, for sorting)
    public let score: Double
    
    /// Initialize a SearchUser
    public init(
        userId: UUID,
        handle: String,
        displayHandle: String,
        displayName: String,
        avatarUrl: String?,
        trustLevel: Int,
        verified: Bool,
        followersCount: Int,
        lastActiveAt: Date?,
        score: Double
    ) {
        self.userId = userId
        self.handle = handle
        self.displayHandle = displayHandle
        self.displayName = displayName
        self.avatarUrl = avatarUrl
        self.trustLevel = trustLevel
        self.verified = verified
        self.followersCount = followersCount
        self.lastActiveAt = lastActiveAt
        self.score = score
    }
}

// MARK: - SearchUser Preview Helpers

#if DEBUG
extension SearchUser {
    /// Sample search user for previews
    public static let preview = SearchUser(
        userId: UUID(),
        handle: "rocky.evans",
        displayHandle: "Rocky.Evans",
        displayName: "Rocky Evans",
        avatarUrl: nil,
        trustLevel: 2,
        verified: true,
        followersCount: 1234,
        lastActiveAt: Date(),
        score: 0.95
    )
    
    /// Array of sample users for previews
    public static let previewArray: [SearchUser] = [
        SearchUser(
            userId: UUID(),
            handle: "rocky.evans",
            displayHandle: "Rocky.Evans",
            displayName: "Rocky Evans",
            avatarUrl: nil,
            trustLevel: 2,
            verified: true,
            followersCount: 1234,
            lastActiveAt: Date(),
            score: 0.95
        ),
        SearchUser(
            userId: UUID(),
            handle: "jane.doe",
            displayHandle: "jane.doe",
            displayName: "Jane Doe",
            avatarUrl: nil,
            trustLevel: 1,
            verified: false,
            followersCount: 567,
            lastActiveAt: Date().addingTimeInterval(-86400),
            score: 0.75
        ),
        SearchUser(
            userId: UUID(),
            handle: "john.smith",
            displayHandle: "John.Smith",
            displayName: "John Smith",
            avatarUrl: nil,
            trustLevel: 0,
            verified: false,
            followersCount: 89,
            lastActiveAt: Date().addingTimeInterval(-86400 * 7),
            score: 0.50
        )
    ]
}
#endif

// MARK: - Comment Service Protocol

/// Protocol for comment service handling threaded comments (YouTube-style, max depth = 2)
public protocol CommentServiceProtocol: Sendable {
    /// Fetches top-level comments for a post with keyset pagination
    /// - Parameters:
    ///   - postId: The post ID
    ///   - pageSize: Number of comments to fetch (default 50)
    ///   - cursor: Optional cursor for pagination
    /// - Returns: Tuple containing comments and next cursor
    /// - Throws: CommentError if fetch fails
    func fetchTopLevelComments(
        postId: String,
        pageSize: Int,
        cursor: CommentCursor?
    ) async throws -> (items: [Comment], next: CommentCursor?)
    
    /// Fetches replies for a specific comment with keyset pagination
    /// - Parameters:
    ///   - parentId: The parent comment ID
    ///   - pageSize: Number of replies to fetch (default 25)
    ///   - cursor: Optional cursor for pagination
    /// - Returns: Tuple containing replies and next cursor
    /// - Throws: CommentError if fetch fails
    func fetchReplies(
        parentId: String,
        pageSize: Int,
        cursor: CommentCursor?
    ) async throws -> (items: [Comment], next: CommentCursor?)
    
    /// Creates a top-level comment on a post
    /// - Parameters:
    ///   - postId: The post ID
    ///   - body: Comment text (1-2000 characters)
    /// - Returns: Created comment
    /// - Throws: CommentError if creation fails
    func createComment(postId: String, body: String) async throws -> Comment
    
    /// Creates a reply to a comment (enforces max depth = 2)
    /// - Parameters:
    ///   - parentId: The parent comment ID
    ///   - body: Reply text (1-2000 characters)
    /// - Returns: Created reply
    /// - Throws: CommentError if creation fails or max depth exceeded
    func createReply(parentId: String, body: String) async throws -> Comment
}

/// Errors that can occur during comment operations
public enum CommentError: LocalizedError, Sendable {
    case commentNotFound
    case postNotFound
    case unauthorized
    case maxDepthExceeded
    case bodyTooLong
    case bodyTooShort
    case networkError
    case serverError(String)
    case rateLimited
    
    public var errorDescription: String? {
        switch self {
        case .commentNotFound:
            return "Comment not found"
        case .postNotFound:
            return "Post not found"
        case .unauthorized:
            return "You must be signed in to comment"
        case .maxDepthExceeded:
            return "Maximum reply depth exceeded"
        case .bodyTooLong:
            return "Comment is too long (maximum 2000 characters)"
        case .bodyTooShort:
            return "Comment must have at least 1 character"
        case .networkError:
            return "Network connection failed. Please try again."
        case .serverError(let message):
            return "Server error: \(message)"
        case .rateLimited:
            return "You're commenting too quickly. Please wait a moment."
        }
    }
}

// MARK: - Comment Composition Protocol

import SwiftUI

/// Protocol for comment composition functionality
/// Allows features to present comment composition without depending on PostDetail
public protocol CommentCompositionProtocol: Sendable {
    /// Creates a comment composition view for a given post
    /// - Parameters:
    ///   - post: The post to comment on
    ///   - replyToCommentId: Optional comment ID to reply to
    ///   - replyToUsername: Optional username being replied to
    /// - Returns: A SwiftUI view for comment composition
    func createCommentSheet(
        for post: Post,
        replyToCommentId: String?,
        replyToUsername: String?
    ) -> AnyView
}

// MARK: - Engagement Service Protocol

/// Service for handling post engagement actions (like, repost, share)
public protocol EngagementService: Sendable {
    /// Toggle like on a post (idempotent)
    /// - Parameter postId: The ID of the post to like/unlike
    /// - Returns: Result containing new like state and count
    /// - Throws: EngagementError if operation fails
    func toggleLike(postId: String) async throws -> LikeResult
    
    /// Toggle repost on a post (idempotent)
    /// - Parameter postId: The ID of the post to repost/unrepost
    /// - Returns: Result containing new repost state and count
    /// - Throws: EngagementError if operation fails
    func toggleRepost(postId: String) async throws -> RepostResult
    
    /// Get shareable URL for a post
    /// - Parameter postId: The ID of the post to share
    /// - Returns: Deep link URL for the post
    /// - Throws: EngagementError if operation fails
    func getShareURL(postId: String) async throws -> URL
    
    /// Record a share on a post (idempotent - only counts once per user)
    /// - Parameter postId: The ID of the post to share
    /// - Returns: Result containing updated share count
    /// - Throws: EngagementError if operation fails
    func recordShare(postId: String) async throws -> ShareResult
}

/// Result of a like toggle operation
public struct LikeResult: Sendable {
    public let isLiked: Bool
    public let likeCount: Int
    
    public init(isLiked: Bool, likeCount: Int) {
        self.isLiked = isLiked
        self.likeCount = likeCount
    }
}

/// Result of a repost toggle operation
public struct RepostResult: Sendable {
    public let isReposted: Bool
    public let repostCount: Int
    
    public init(isReposted: Bool, repostCount: Int) {
        self.isReposted = isReposted
        self.repostCount = repostCount
    }
}

/// Result of a share recording operation
public struct ShareResult: Sendable {
    public let shareCount: Int
    
    public init(shareCount: Int) {
        self.shareCount = shareCount
    }
}

/// Errors that can occur during engagement operations
public enum EngagementError: LocalizedError, Sendable {
    case postNotFound
    case unauthorized
    case networkError
    case serverError(String)
    case rateLimited
    
    public var errorDescription: String? {
        switch self {
        case .postNotFound:
            return "Post not found"
        case .unauthorized:
            return "You must be signed in to perform this action"
        case .networkError:
            return "Network connection failed. Please try again."
        case .serverError(let message):
            return "Server error: \(message)"
        case .rateLimited:
            return "You're doing that too quickly. Please wait a moment."
        }
    }
}

// MARK: - Messaging Service Protocols

/// Lightweight user representation for share menu recipient suggestions
public struct ShareRecipient: Sendable, Hashable, Identifiable {
    public let id: String
    public let handle: String
    public let displayName: String
    public let avatarURL: URL?
    
    public init(id: String, handle: String, displayName: String, avatarURL: URL?) {
        self.id = id
        self.handle = handle
        self.displayName = displayName
        self.avatarURL = avatarURL
    }
}

/// Protocol for messaging service handling conversations and messages
public protocol MessagingServiceProtocol: Sendable {
    /// Creates a new conversation with specified participants
    /// - Parameter participantIds: Array of user IDs to include in conversation
    /// - Returns: Created conversation
    /// - Throws: MessagingError if creation fails
    func createConversation(participantIds: [UUID]) async throws -> Conversation
    
    /// Leaves a conversation
    /// - Parameter id: Conversation ID to leave
    /// - Throws: MessagingError if operation fails
    func leaveConversation(id: UUID) async throws
    
    /// Sets muted status for a conversation
    /// - Parameters:
    ///   - muted: Whether to mute the conversation
    ///   - id: Conversation ID
    /// - Throws: MessagingError if operation fails
    func setMuted(_ muted: Bool, for id: UUID) async throws
    
    /// Sets archived status for a conversation
    /// - Parameters:
    ///   - archived: Whether to archive the conversation
    ///   - id: Conversation ID
    /// - Throws: MessagingError if operation fails
    func setArchived(_ archived: Bool, for id: UUID) async throws
    
    /// Sets pinned status for a conversation
    /// - Parameters:
    ///   - pinned: Whether to pin the conversation
    ///   - id: Conversation ID
    /// - Throws: MessagingError if operation fails
    func pin(_ pinned: Bool, for id: UUID) async throws
    
    /// Fetches conversations with pagination
    /// - Parameters:
    ///   - page: Page number (0-based)
    ///   - pageSize: Number of conversations per page
    /// - Returns: Array of conversations
    /// - Throws: MessagingError if fetch fails
    func fetchConversations(page: Int, pageSize: Int) async throws -> [Conversation]
    
    /// Fetches messages for a conversation with pagination
    /// - Parameters:
    ///   - conversationId: Conversation ID
    ///   - before: Optional date to fetch messages before
    ///   - limit: Maximum number of messages to fetch
    /// - Returns: Array of messages
    /// - Throws: MessagingError if fetch fails
    func fetchMessages(conversationId: UUID, before: Date?, limit: Int) async throws -> [Message]
    
    /// Sends a text message
    /// - Parameters:
    ///   - text: Message text content
    ///   - conversationId: Target conversation ID
    /// - Returns: Sent message
    /// - Throws: MessagingError if send fails
    func send(text: String, in conversationId: UUID) async throws -> Message
    
    /// Sends a message with attachment
    /// - Parameters:
    ///   - attachment: Media attachment
    ///   - conversationId: Target conversation ID
    /// - Returns: Sent message
    /// - Throws: MessagingError if send fails
    func send(attachment: Attachment, in conversationId: UUID) async throws -> Message
    
    /// Marks a message as delivered
    /// - Parameters:
    ///   - conversationId: Conversation ID
    ///   - messageId: Message ID to mark as delivered
    /// - Throws: MessagingError if operation fails
    func markDelivered(conversationId: UUID, messageId: UUID) async throws
    
    /// Marks messages as read up to a specific message
    /// - Parameters:
    ///   - conversationId: Conversation ID
    ///   - messageId: Last message ID to mark as read
    /// - Throws: MessagingError if operation fails
    func markReadRange(conversationId: UUID, upTo messageId: UUID) async throws
    
    /// Fetches recent DM recipients for share menu
    /// - Parameter limit: Maximum number of recipients to fetch
    /// - Returns: Array of recent DM recipients
    /// - Throws: MessagingError if fetch fails
    func recentDMRecipients(limit: Int) async throws -> [ShareRecipient]
    
    /// Fetches recent follows for share menu fallback
    /// - Parameter limit: Maximum number of follows to fetch
    /// - Returns: Array of recent follows
    /// - Throws: MessagingError if fetch fails
    func recentFollows(limit: Int) async throws -> [ShareRecipient]
    
    /// Auto-sends a DM without UI navigation
    /// - Parameters:
    ///   - recipientID: Target user ID
    ///   - text: Message text (typically a share URL)
    /// - Throws: MessagingError if send fails
    func autoSendDM(to recipientID: String, text: String) async throws
}

/// Protocol for real-time messaging functionality
public protocol MessagingRealtimeProtocol: Sendable {
    /// Subscribes to conversation list updates
    /// - Returns: Subscription for managing the connection
    /// - Throws: MessagingError if subscription fails
    func subscribeConversationList() async throws -> MessagingSubscription
    
    /// Subscribes to updates for a specific conversation
    /// - Parameter conversationId: Conversation ID to subscribe to
    /// - Returns: Subscription for managing the connection
    /// - Throws: MessagingError if subscription fails
    func subscribe(conversationId: UUID) async throws -> MessagingSubscription
    
    /// Sets typing status for a conversation
    /// - Parameters:
    ///   - conversationId: Conversation ID
    ///   - isTyping: Whether user is currently typing
    func setTyping(conversationId: UUID, isTyping: Bool) async
    
    /// Stream of real-time messaging events
    var events: AsyncStream<MessagingEvent> { get }
}

/// Protocol for messaging media handling
public protocol MessagingMediaProtocol: Sendable {
    /// Prepares a media attachment for sending
    /// - Parameter pick: Selected media from picker
    /// - Returns: Prepared attachment ready for sending
    /// - Throws: MessagingError if preparation fails
    func prepareAttachment(_ pick: MediaPick) async throws -> Attachment
}

/// Subscription handle for managing real-time connections
public protocol MessagingSubscription: Sendable {
    /// Cancels the subscription
    func cancel() async
    
    /// Whether the subscription is currently active
    var isActive: Bool { get async }
}

/// Real-time messaging events
public enum MessagingEvent: Sendable {
    case messageAdded(Message)
    case messageUpdated(Message)
    case messageDeleted(UUID, conversationId: UUID)
    case typing(conversationId: UUID, userId: UUID, isTyping: Bool)
    case readReceipt(conversationId: UUID, messageId: UUID, userId: UUID)
    case conversationUpdated(Conversation)
}

// MARK: - Messaging Data Models

/// Conversation model
public struct Conversation: Identifiable, Codable, Sendable {
    public let id: UUID
    public let participants: [User]
    public let lastMessage: Message?
    public let lastActivity: Date
    public let unreadCount: Int
    public let unreadMentionsCount: Int
    public let isArchived: Bool
    public let isPinned: Bool
    public let isMuted: Bool
    public let lastReadMessageId: UUID?
    public let draftText: String?
    public let isGroup: Bool
    public let title: String?
    public let avatarUrl: URL?
    
    public init(
        id: UUID,
        participants: [User],
        lastMessage: Message? = nil,
        lastActivity: Date,
        unreadCount: Int = 0,
        unreadMentionsCount: Int = 0,
        isArchived: Bool = false,
        isPinned: Bool = false,
        isMuted: Bool = false,
        lastReadMessageId: UUID? = nil,
        draftText: String? = nil,
        isGroup: Bool = false,
        title: String? = nil,
        avatarUrl: URL? = nil
    ) {
        self.id = id
        self.participants = participants
        self.lastMessage = lastMessage
        self.lastActivity = lastActivity
        self.unreadCount = unreadCount
        self.unreadMentionsCount = unreadMentionsCount
        self.isArchived = isArchived
        self.isPinned = isPinned
        self.isMuted = isMuted
        self.lastReadMessageId = lastReadMessageId
        self.draftText = draftText
        self.isGroup = isGroup
        self.title = title
        self.avatarUrl = avatarUrl
    }
}

/// Message model
public struct Message: Identifiable, Codable, Sendable {
    public let id: UUID
    public let conversationId: UUID
    public let senderId: UUID
    public let content: String
    public let attachments: [Attachment]
    public let timestamp: Date
    public let deliveryStatus: DeliveryStatus
    public let replyTo: UUID?
    public let nonce: MessageNonce?
    public let editedAt: Date?
    public let deletedAt: Date?
    public let expiresAt: Date?
    public let systemKind: SystemMessageKind?
    public let linkPreview: LinkPreview?
    
    public init(
        id: UUID,
        conversationId: UUID,
        senderId: UUID,
        content: String,
        attachments: [Attachment] = [],
        timestamp: Date,
        deliveryStatus: DeliveryStatus = .sent,
        replyTo: UUID? = nil,
        nonce: MessageNonce? = nil,
        editedAt: Date? = nil,
        deletedAt: Date? = nil,
        expiresAt: Date? = nil,
        systemKind: SystemMessageKind? = nil,
        linkPreview: LinkPreview? = nil
    ) {
        self.id = id
        self.conversationId = conversationId
        self.senderId = senderId
        self.content = content
        self.attachments = attachments
        self.timestamp = timestamp
        self.deliveryStatus = deliveryStatus
        self.replyTo = replyTo
        self.nonce = nonce
        self.editedAt = editedAt
        self.deletedAt = deletedAt
        self.expiresAt = expiresAt
        self.systemKind = systemKind
        self.linkPreview = linkPreview
    }
}

/// Attachment model
public struct Attachment: Identifiable, Codable, Sendable {
    public let id: UUID
    public let type: AttachmentType
    public let url: URL
    public let thumbnailUrl: URL?
    public let sizeBytes: Int64
    public let duration: TimeInterval?
    public let metadata: AttachmentMetadata
    
    public init(
        id: UUID,
        type: AttachmentType,
        url: URL,
        thumbnailUrl: URL? = nil,
        sizeBytes: Int64,
        duration: TimeInterval? = nil,
        metadata: AttachmentMetadata
    ) {
        self.id = id
        self.type = type
        self.url = url
        self.thumbnailUrl = thumbnailUrl
        self.sizeBytes = sizeBytes
        self.duration = duration
        self.metadata = metadata
    }
}

/// Message nonce for optimistic updates
public struct MessageNonce: Hashable, Codable, Sendable {
    public let value: UUID
    
    public init(value: UUID = UUID()) {
        self.value = value
    }
}

/// Outbound message draft
public struct OutboundMessageDraft: Sendable {
    public let conversationId: UUID
    public let nonce: MessageNonce
    public var text: String
    public var attachments: [Attachment]
    
    public init(
        conversationId: UUID,
        nonce: MessageNonce = MessageNonce(),
        text: String = "",
        attachments: [Attachment] = []
    ) {
        self.conversationId = conversationId
        self.nonce = nonce
        self.text = text
        self.attachments = attachments
    }
}

/// Message delivery status
public enum DeliveryStatus: String, Codable, Sendable {
    case sending, sent, delivered, read, failed
}

/// System message types
public enum SystemMessageKind: String, Codable, Sendable {
    case userJoined, userLeft, conversationCreated, titleChanged
}

/// Attachment types
public enum AttachmentType: String, Codable, Sendable {
    case image, video, audio, document
}

/// Attachment metadata
public struct AttachmentMetadata: Codable, Sendable {
    public let filename: String?
    public let mimeType: String?
    public let width: Int?
    public let height: Int?
    
    public init(
        filename: String? = nil,
        mimeType: String? = nil,
        width: Int? = nil,
        height: Int? = nil
    ) {
        self.filename = filename
        self.mimeType = mimeType
        self.width = width
        self.height = height
    }
}

/// Link preview information
public struct LinkPreview: Codable, Sendable {
    public let url: URL
    public let title: String?
    public let description: String?
    public let imageUrl: URL?
    
    public init(url: URL, title: String? = nil, description: String? = nil, imageUrl: URL? = nil) {
        self.url = url
        self.title = title
        self.description = description
        self.imageUrl = imageUrl
    }
}

/// Media pick from photo picker
public struct MediaPick: Sendable {
    public let data: Data
    public let filename: String
    public let mimeType: String
    
    public init(data: Data, filename: String, mimeType: String) {
        self.data = data
        self.filename = filename
        self.mimeType = mimeType
    }
}

// MARK: - Push Notification Service Protocol

/// Protocol for push notification services
public protocol PushNotificationServiceProtocol: Sendable {
    /// Registers for push notifications and returns device token
    /// - Returns: Device token string if successful
    /// - Throws: NotificationError if registration fails
    func registerForNotifications() async throws -> String?
    
    /// Handles incoming notification when app is in foreground
    /// - Parameter notification: The notification payload
    func handleForegroundNotification(_ notification: [AnyHashable: Any]) async
    
    /// Handles notification tap when app is launched or brought to foreground
    /// - Parameter notification: The notification payload
    func handleNotificationTap(_ notification: [AnyHashable: Any]) async
    
    /// Sets notification categories for different types of notifications
    func setupNotificationCategories() async
    
    /// Updates notification settings for a conversation
    /// - Parameters:
    ///   - conversationId: The conversation ID
    ///   - enabled: Whether notifications are enabled for this conversation
    func updateConversationNotifications(conversationId: UUID, enabled: Bool) async throws
}

/// Push notification errors
public enum NotificationError: LocalizedError, Sendable {
    case permissionDenied
    case registrationFailed
    case invalidPayload
    case serviceUnavailable
    
    public var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Notification permission was denied"
        case .registrationFailed:
            return "Failed to register for push notifications"
        case .invalidPayload:
            return "Invalid notification payload"
        case .serviceUnavailable:
            return "Push notification service is unavailable"
        }
    }
}

/// No-op implementation of PushNotificationServiceProtocol for testing and previews
public final class NoOpPushNotificationService: PushNotificationServiceProtocol {
    public init() {}
    
    public func registerForNotifications() async throws -> String? {
        return nil
    }
    
    public func handleForegroundNotification(_ notification: [AnyHashable: Any]) async {
        // No-op
    }
    
    public func handleNotificationTap(_ notification: [AnyHashable: Any]) async {
        // No-op
    }
    
    public func setupNotificationCategories() async {
        // No-op
    }
    
    public func updateConversationNotifications(conversationId: UUID, enabled: Bool) async throws {
        // No-op
    }
}

/// Messaging errors
public enum MessagingError: LocalizedError, Sendable {
    case conversationNotFound
    case messageNotFound
    case unauthorized
    case networkError
    case serverError(String)
    case attachmentTooLarge
    case unsupportedAttachmentType
    case subscriptionFailed
    case rateLimited
    case invalidUserId
    case conversationCreationFailed
    case sendMessageFailed
    
    public var errorDescription: String? {
        switch self {
        case .conversationNotFound:
            return "Conversation not found"
        case .messageNotFound:
            return "Message not found"
        case .unauthorized:
            return "You must be signed in to send messages"
        case .networkError:
            return "Network connection failed. Please try again."
        case .serverError(let message):
            return "Server error: \(message)"
        case .attachmentTooLarge:
            return "Attachment is too large to send"
        case .unsupportedAttachmentType:
            return "This attachment type is not supported"
        case .subscriptionFailed:
            return "Failed to connect to real-time messaging"
        case .rateLimited:
            return "You're sending messages too quickly. Please wait a moment."
        case .invalidUserId:
            return "Invalid user ID"
        case .conversationCreationFailed:
            return "Failed to create conversation"
        case .sendMessageFailed:
            return "Failed to send message"
        }
    }
}

// MARK: - No-Op Messaging Service Implementations

/// No-op implementation of MessagingServiceProtocol for testing and previews
public final class NoOpMessagingService: MessagingServiceProtocol {
    public init() {}
    
    public func createConversation(participantIds: [UUID]) async throws -> Conversation {
        throw MessagingError.serverError("Messaging service not available")
    }
    
    public func leaveConversation(id: UUID) async throws {
        throw MessagingError.serverError("Messaging service not available")
    }
    
    public func setMuted(_ muted: Bool, for id: UUID) async throws {
        throw MessagingError.serverError("Messaging service not available")
    }
    
    public func setArchived(_ archived: Bool, for id: UUID) async throws {
        throw MessagingError.serverError("Messaging service not available")
    }
    
    public func pin(_ pinned: Bool, for id: UUID) async throws {
        throw MessagingError.serverError("Messaging service not available")
    }
    
    public func fetchConversations(page: Int, pageSize: Int) async throws -> [Conversation] {
        return []
    }
    
    public func fetchMessages(conversationId: UUID, before: Date?, limit: Int) async throws -> [Message] {
        return []
    }
    
    public func send(text: String, in conversationId: UUID) async throws -> Message {
        throw MessagingError.serverError("Messaging service not available")
    }
    
    public func send(attachment: Attachment, in conversationId: UUID) async throws -> Message {
        throw MessagingError.serverError("Messaging service not available")
    }
    
    public func markDelivered(conversationId: UUID, messageId: UUID) async throws {
        throw MessagingError.serverError("Messaging service not available")
    }
    
    public func markReadRange(conversationId: UUID, upTo messageId: UUID) async throws {
        throw MessagingError.serverError("Messaging service not available")
    }
    
    public func recentDMRecipients(limit: Int) async throws -> [ShareRecipient] {
        return []
    }
    
    public func recentFollows(limit: Int) async throws -> [ShareRecipient] {
        return []
    }
    
    public func autoSendDM(to recipientID: String, text: String) async throws {
        throw MessagingError.serverError("Messaging service not available")
    }
}

/// No-op implementation of MessagingRealtimeProtocol for testing and previews
public final class NoOpMessagingRealtimeService: MessagingRealtimeProtocol {
    public init() {}
    
    public func subscribeConversationList() async throws -> MessagingSubscription {
        return NoOpMessagingSubscription()
    }
    
    public func subscribe(conversationId: UUID) async throws -> MessagingSubscription {
        return NoOpMessagingSubscription()
    }
    
    public func setTyping(conversationId: UUID, isTyping: Bool) async {
        // No-op
    }
    
    public var events: AsyncStream<MessagingEvent> {
        AsyncStream { _ in }
    }
}

/// No-op implementation of MessagingMediaProtocol for testing and previews
public final class NoOpMessagingMediaService: MessagingMediaProtocol {
    public init() {}
    
    public func prepareAttachment(_ pick: MediaPick) async throws -> Attachment {
        throw MessagingError.serverError("Messaging media service not available")
    }
}

/// No-op implementation of MessagingSubscription for testing and previews
public final class NoOpMessagingSubscription: MessagingSubscription {
    public init() {}
    
    public func cancel() async {
        // No-op
    }
    
    public var isActive: Bool {
        get async { false }
    }
}

// MARK: - Avatar Cropper Service Protocols

/// Protocol for image crop rendering functionality
public protocol ImageCropRendering: Sendable {
    /// Renders a square output (e.g., 512×512) from a source CGImage and transform
    /// - Parameters:
    ///   - source: The source CGImage to crop
    ///   - cropRectInPixels: The crop rectangle in image pixel coordinates
    ///   - outputSize: The desired output size (width and height in pixels)
    ///   - colorSpace: The color space for the output image
    /// - Returns: PNG or JPEG data of the cropped image
    /// - Throws: CropValidationError if rendering fails
    func renderSquareAvatar(
        source: CGImage,
        cropRectInPixels: CGRect,
        outputSize: Int,
        colorSpace: CGColorSpace
    ) throws -> Data
}

/// Protocol for avatar upload service
public protocol AvatarUploadService: Sendable {
    /// Uploads avatar data to storage and updates user profile
    /// - Parameters:
    ///   - data: The image data to upload (PNG or JPEG)
    ///   - mime: The MIME type of the image data
    /// - Returns: The public URL of the uploaded avatar with cache-busting version
    /// - Throws: AvatarUploadError if upload or profile update fails
    func uploadAvatar(_ data: Data, mime: String) async throws -> URL
}

// MARK: - Avatar Cropper Error Types

/// Errors that can occur during crop validation and processing
public enum CropValidationError: LocalizedError, Sendable {
    case imageTooSmall(size: CGSize, minimum: CGFloat)
    case imageDecodingFailed
    case cropProcessingFailed
    case uploadFailed(underlying: Error)
    case memoryPressure
    case invalidImageFormat
    case cropAreaTooSmall(required: CGSize, actual: CGSize)
    case qualityLimitExceeded(maxZoom: CGFloat, requestedZoom: CGFloat)
    case insufficientPixelDensity(required: CGFloat, actual: CGFloat)
    case orientationNormalizationFailed
    case colorSpaceConversionFailed
    case thumbnailGenerationFailed
    
    public var errorDescription: String? {
        switch self {
        case .imageTooSmall(let size, let minimum):
            return "This photo is too small for a profile picture. Minimum size: \(Int(minimum))px, actual: \(Int(min(size.width, size.height)))px."
        case .imageDecodingFailed:
            return "Unable to process this image. Please try a different photo."
        case .cropProcessingFailed:
            return "Failed to crop image. Please try again."
        case .uploadFailed:
            return "Upload failed. Please check your connection and try again."
        case .memoryPressure:
            return "Using an optimized preview to finish the crop."
        case .invalidImageFormat:
            return "This image format is not supported. Please use JPEG, PNG, or HEIC."
        case .cropAreaTooSmall(let required, let actual):
            return "Crop area is too small. Required: \(Int(required.width))×\(Int(required.height))px, actual: \(Int(actual.width))×\(Int(actual.height))px."
        case .qualityLimitExceeded(let maxZoom, let requestedZoom):
            return "Zoom level too high for good quality. Maximum: \(String(format: "%.1f", maxZoom))×, requested: \(String(format: "%.1f", requestedZoom))×."
        case .insufficientPixelDensity(let required, let actual):
            return "Image resolution too low for crisp display. Required: \(String(format: "%.1f", required)) px/pt, actual: \(String(format: "%.1f", actual)) px/pt."
        case .orientationNormalizationFailed:
            return "Failed to correct image orientation. Please try a different photo."
        case .colorSpaceConversionFailed:
            return "Failed to process image colors. Please try a different photo."
        case .thumbnailGenerationFailed:
            return "Failed to create image preview. Please try a different photo."
        }
    }
    
    /// User-friendly recovery suggestions
    public var recoverySuggestion: String? {
        switch self {
        case .imageTooSmall:
            return "Try using a higher resolution photo from your camera or a different source."
        case .imageDecodingFailed, .invalidImageFormat:
            return "Try saving the image in a different format (JPEG or PNG) or use a different photo."
        case .cropProcessingFailed, .orientationNormalizationFailed, .colorSpaceConversionFailed:
            return "Try restarting the app or using a different photo."
        case .uploadFailed:
            return "Check your internet connection and try again."
        case .memoryPressure:
            return "Close other apps to free up memory, or try a smaller image."
        case .cropAreaTooSmall, .qualityLimitExceeded, .insufficientPixelDensity:
            return "Try zooming out or using a higher resolution photo."
        case .thumbnailGenerationFailed:
            return "Try using a different photo or restarting the app."
        }
    }
    
    /// Whether this error allows retry
    public var isRetryable: Bool {
        switch self {
        case .imageTooSmall, .imageDecodingFailed, .invalidImageFormat, .orientationNormalizationFailed:
            return false // These require a different image
        case .cropProcessingFailed, .uploadFailed, .memoryPressure, .colorSpaceConversionFailed, .thumbnailGenerationFailed:
            return true // These might succeed on retry
        case .cropAreaTooSmall, .qualityLimitExceeded, .insufficientPixelDensity:
            return false // These require user adjustment
        }
    }
    
    /// Error category for analytics and debugging
    public var category: CropErrorCategory {
        switch self {
        case .imageTooSmall, .imageDecodingFailed, .invalidImageFormat, .orientationNormalizationFailed, .thumbnailGenerationFailed:
            return .imageValidation
        case .cropProcessingFailed, .colorSpaceConversionFailed:
            return .processing
        case .uploadFailed:
            return .network
        case .memoryPressure:
            return .system
        case .cropAreaTooSmall, .qualityLimitExceeded, .insufficientPixelDensity:
            return .userInput
        }
    }
}

/// Categories of crop validation errors for analytics and handling
public enum CropErrorCategory: String, Sendable, CaseIterable {
    case imageValidation = "image_validation"
    case processing = "processing"
    case network = "network"
    case system = "system"
    case userInput = "user_input"
}

/// Errors that can occur during avatar upload
public enum AvatarUploadError: LocalizedError, Sendable {
    case notAuthenticated
    case uploadFailed(Error)
    case profileUpdateFailed(Error)
    
    public var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please sign in to update your avatar."
        case .uploadFailed:
            return "Failed to upload avatar. Please try again."
        case .profileUpdateFailed:
            return "Avatar uploaded but profile update failed. Please try again."
        }
    }
}

// MARK: - No-Op Avatar Service Implementations

/// No-op implementation of ImageCropRendering for testing and previews
public final class NoOpImageCropRenderer: ImageCropRendering {
    public init() {}
    
    public func renderSquareAvatar(
        source: CGImage,
        cropRectInPixels: CGRect,
        outputSize: Int,
        colorSpace: CGColorSpace
    ) throws -> Data {
        throw CropValidationError.cropProcessingFailed
    }
}

/// No-op implementation of AvatarUploadService for testing and previews
public final class NoOpAvatarUploadService: AvatarUploadService {
    public init() {}
    
    public func uploadAvatar(_ data: Data, mime: String) async throws -> URL {
        throw AvatarUploadError.uploadFailed(NSError(domain: "NoOpService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Avatar upload service not available"]))
    }
}