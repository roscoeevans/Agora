import Foundation

/// Flat response structure that matches the actual Edge Function output
/// This is what get-user-profile returns - all fields at the root level
internal struct UserProfileWithStatsFlat: Codable, Sendable {
    // User fields
    let id: String
    let handle: String
    let displayHandle: String
    let displayName: String
    let bio: String?
    let avatarUrl: String?
    let createdAt: Date
    
    // Stats fields
    let followerCount: Int
    let followingCount: Int
    let postCount: Int
    let isCurrentUser: Bool
    let isFollowing: Bool
}

