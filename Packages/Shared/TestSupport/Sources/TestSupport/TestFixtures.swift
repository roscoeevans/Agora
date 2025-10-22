import Foundation

/// Sample data fixtures for testing
public struct TestFixtures: Sendable {
    
    // MARK: - User Fixtures
    
    public static let sampleUser = User(
        id: "user_123",
        handle: "johndoe",
        displayName: "John Doe",
        bio: "iOS developer and coffee enthusiast",
        avatarURL: URL(string: "https://example.com/avatar.jpg")
    )
    
    public static let sampleUsers = [
        User(
            id: "user_123",
            handle: "johndoe",
            displayName: "John Doe",
            bio: "iOS developer and coffee enthusiast",
            avatarURL: URL(string: "https://example.com/avatar1.jpg")
        ),
        User(
            id: "user_456",
            handle: "janedoe",
            displayName: "Jane Doe",
            bio: "Designer and photographer",
            avatarURL: URL(string: "https://example.com/avatar2.jpg")
        ),
        User(
            id: "user_789",
            handle: "bobsmith",
            displayName: "Bob Smith",
            bio: "Product manager",
            avatarURL: nil
        )
    ]
    
    // MARK: - Post Fixtures
    
    public static let samplePost = Post(
        id: "post_123",
        authorId: "user_123",
        authorDisplayHandle: "testuser",
        text: "Just shipped a new feature! 🚀",
        likeCount: 42,
        repostCount: 7,
        replyCount: 12,
        createdAt: Date().addingTimeInterval(-3600) // 1 hour ago
    )
    
    public static let samplePosts = [
        Post(
            id: "post_123",
            authorId: "user_123",
            authorDisplayHandle: "testuser",
            text: "Just shipped a new feature! 🚀",
            likeCount: 42,
            repostCount: 7,
            replyCount: 12,
            createdAt: Date().addingTimeInterval(-3600)
        ),
        Post(
            id: "post_456",
            authorId: "user_456",
            authorDisplayHandle: "photographer",
            text: "Beautiful sunset today 🌅",
            mediaBundleId: sampleMediaBundle.id,
            likeCount: 128,
            repostCount: 23,
            replyCount: 45,
            createdAt: Date().addingTimeInterval(-7200)
        ),
        Post(
            id: "post_789",
            authorId: "user_789",
            authorDisplayHandle: "developer",
            text: "Check out this interesting article about SwiftUI performance optimizations",
            linkUrl: "https://example.com/article",
            likeCount: 89,
            repostCount: 34,
            replyCount: 67,
            createdAt: Date().addingTimeInterval(-10800)
        )
    ]
    
    // MARK: - Media Fixtures
    
    public static let sampleMediaBundle = MediaBundle(
        id: "media_123",
        type: .image,
        url: URL(string: "https://example.com/image.jpg")!,
        thumbnailURL: URL(string: "https://example.com/thumb.jpg"),
        width: 1080,
        height: 1920
    )
    
    // MARK: - Date Fixtures
    
    public static let pastDates = [
        Date().addingTimeInterval(-60),      // 1 minute ago
        Date().addingTimeInterval(-3600),    // 1 hour ago
        Date().addingTimeInterval(-86400),   // 1 day ago
        Date().addingTimeInterval(-604800),  // 1 week ago
        Date().addingTimeInterval(-2592000)  // 1 month ago
    ]
}

// MARK: - Sample Data Models

public struct User: Identifiable, Codable, Sendable {
    public let id: String
    public let handle: String
    public let displayName: String
    public let bio: String
    public let avatarURL: URL?
    
    public init(id: String, handle: String, displayName: String, bio: String, avatarURL: URL?) {
        self.id = id
        self.handle = handle
        self.displayName = displayName
        self.bio = bio
        self.avatarURL = avatarURL
    }
}

// Note: Post is imported from AppFoundation
// We extend it with test helpers instead of creating a duplicate

extension Post {
    /// Create a sample Post for testing
    public static func sample(
        id: String = UUID().uuidString,
        authorId: String = "test-author-id",
        authorDisplayHandle: String = "test.user",
        text: String = "Sample post for testing",
        linkUrl: String? = nil,
        mediaBundleId: String? = nil,
        likeCount: Int = 0,
        repostCount: Int = 0,
        replyCount: Int = 0,
        createdAt: Date = Date(),
        authorDisplayName: String? = "Test User",
        authorAvatarUrl: String? = nil
    ) -> Post {
        Post(
            id: id,
            authorId: authorId,
            authorDisplayHandle: authorDisplayHandle,
            text: text,
            linkUrl: linkUrl,
            mediaBundleId: mediaBundleId,
            likeCount: likeCount,
            repostCount: repostCount,
            replyCount: replyCount,
            createdAt: createdAt,
            authorDisplayName: authorDisplayName,
            authorAvatarUrl: authorAvatarUrl
        )
    }
}

public struct MediaBundle: Codable, Sendable {
    public let id: String
    public let type: MediaType
    public let url: URL
    public let thumbnailURL: URL?
    public let width: Int?
    public let height: Int?
    
    public init(id: String, type: MediaType, url: URL, thumbnailURL: URL?, width: Int?, height: Int?) {
        self.id = id
        self.type = type
        self.url = url
        self.thumbnailURL = thumbnailURL
        self.width = width
        self.height = height
    }
}

public enum MediaType: String, Codable, Sendable {
    case image
    case video
}