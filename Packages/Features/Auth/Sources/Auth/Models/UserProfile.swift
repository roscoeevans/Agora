import Foundation
import Networking

/// User profile model
public struct UserProfile: Sendable, Codable, Identifiable, Equatable {
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

// MARK: - Convenience Initializers

extension UserProfile {
    /// Create from OpenAPI generated User type
    public init(from apiUser: Components.Schemas.User) {
        self.id = apiUser.id
        self.handle = apiUser.handle
        self.displayHandle = apiUser.displayHandle
        self.displayName = apiUser.displayName
        self.bio = apiUser.bio
        self.avatarUrl = apiUser.avatarUrl
        self.createdAt = apiUser.createdAt
    }
}

