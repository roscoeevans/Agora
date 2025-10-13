import Foundation

/// Actor to guard shared mutable state for stub client
/// Follows Swift concurrency best practice: use actors to guard shared mutable state
private actor ProfileStore {
    private var profiles: [String: User] = [:]
    
    func store(_ user: User) {
        profiles[user.id] = user
    }
    
    func hasProfiles() -> Bool {
        !profiles.isEmpty
    }
    
    func firstProfile() -> User? {
        profiles.values.first
    }
}

/// Stub implementation of AgoraAPIClient for development and testing
public final class StubAgoraClient: AgoraAPIClient {
    
    // Track created profiles in memory (for stub simulation)
    // Actor provides async-safe access to mutable state
    private let profileStore = ProfileStore()
    
    public init() {}
    
    // MARK: - Feed Operations
    
    public func fetchForYouFeed(cursor: String?, limit: Int?) async throws -> FeedResponse {
        // Simulate network delay
        try await Task.sleep(for: .milliseconds(500))
        
        // Return mock feed data
        let mockPosts = [
            Post(
                id: "post-1",
                authorId: "user-123",
                authorDisplayHandle: "user_agora_team",
                text: "This is a test post from the stub client! 🚀",
                likeCount: 42,
                repostCount: 7,
                replyCount: 3,
                createdAt: Date().addingTimeInterval(-3600),
                score: 0.85,
                reasons: [
                    RecommendationReason(signal: "quality", weight: 0.45),
                    RecommendationReason(signal: "fresh", weight: 0.25),
                    RecommendationReason(signal: "relation", weight: 0.15)
                ],
                explore: false
            ),
            Post(
                id: "post-2",
                authorId: "user-456",
                authorDisplayHandle: "TestUser",
                text: "Another mock post for testing the feed UI.",
                likeCount: 15,
                repostCount: 2,
                replyCount: 1,
                createdAt: Date().addingTimeInterval(-7200),
                score: 0.62,
                reasons: [
                    RecommendationReason(signal: "fresh", weight: 0.40),
                    RecommendationReason(signal: "quality", weight: 0.22)
                ],
                explore: true
            ),
            Post(
                id: "post-3",
                authorId: "user-789",
                authorDisplayHandle: "DevAccount",
                text: "Stub client is great for offline development! 💡",
                linkUrl: "https://example.com",
                likeCount: 28,
                repostCount: 5,
                replyCount: 8,
                createdAt: Date().addingTimeInterval(-10800),
                score: 0.73,
                reasons: [
                    RecommendationReason(signal: "quality", weight: 0.35),
                    RecommendationReason(signal: "engagement", weight: 0.30),
                    RecommendationReason(signal: "relation", weight: 0.08)
                ],
                explore: false
            )
        ]
        
        // Simulate pagination
        let nextCursor = cursor == nil ? "next-page-token" : nil
        
        return FeedResponse(posts: mockPosts, nextCursor: nextCursor)
    }
    
    // MARK: - Authentication Operations
    
    public func beginSignInWithApple(nonce: String) async throws -> SWABeginResponse {
        // Simulate network delay
        try await Task.sleep(for: .milliseconds(300))
        
        // Return mock auth URL
        return SWABeginResponse(authUrl: "https://appleid.apple.com/auth/authorize?mock=true")
    }
    
    public func finishSignInWithApple(identityToken: String, authorizationCode: String) async throws -> AuthResponse {
        // Simulate network delay
        try await Task.sleep(for: .milliseconds(800))
        
        // Return mock authentication response
        let mockUser = User(
            id: "mock-user-id",
            handle: "testuser",
            displayHandle: "TestUser",
            displayName: "Test User",
            bio: "This is a mock user from the stub client",
            avatarUrl: nil,
            createdAt: Date()
        )
        
        return AuthResponse(
            accessToken: "mock-access-token-\(UUID().uuidString)",
            refreshToken: "mock-refresh-token-\(UUID().uuidString)",
            user: mockUser
        )
    }
    
    // MARK: - User Profile Operations
    
    public func createProfile(request: CreateProfileRequest) async throws -> User {
        // Simulate network delay
        try await Task.sleep(for: .milliseconds(600))
        
        // Create mock user
        let user = User(
            id: UUID().uuidString,
            handle: request.handle,
            displayHandle: request.displayHandle,
            displayName: request.displayName,
            avatarUrl: request.avatarUrl,
            createdAt: Date()
        )
        
        // Store in memory for stub simulation
        await profileStore.store(user)
        
        return user
    }
    
    public func checkHandle(handle: String) async throws -> CheckHandleResponse {
        // Simulate network delay for debounce testing
        try await Task.sleep(for: .milliseconds(400))
        
        // Mock unavailable handles
        let unavailableHandles = ["admin", "test", "agora", "system"]
        let isAvailable = !unavailableHandles.contains(handle.lowercased())
        
        // Generate suggestions if unavailable
        var suggestions: [String] = []
        if !isAvailable {
            suggestions = [
                "\(handle)123",
                "\(handle)_",
                "\(handle)\(Calendar.current.component(.year, from: Date()))",
                "_\(handle)",
                "\(handle)_official"
            ]
        }
        
        return CheckHandleResponse(
            available: isAvailable,
            suggestions: isAvailable ? nil : suggestions
        )
    }
    
    public func getCurrentUserProfile() async throws -> User {
        // Simulate network delay
        try await Task.sleep(for: .milliseconds(300))
        
        // Check if user has created a profile (actor-safe access)
        let hasProfile = await profileStore.hasProfiles()
        let profile = await profileStore.firstProfile()
        
        if hasProfile, let profile = profile {
            // Return the created profile
            return profile
        } else {
            // No profile exists - simulate 404
            // In real implementation, this would be a 404 HTTP error
            throw NetworkError.notFound(message: "Profile not found")
        }
    }
    
    public func updateProfile(request: UpdateProfileRequest) async throws -> User {
        // Simulate network delay
        try await Task.sleep(for: .milliseconds(500))
        
        // Return updated mock user
        return User(
            id: "mock-user-id",
            handle: "currentuser",
            displayHandle: request.displayHandle ?? "CurrentUser",
            displayName: request.displayName ?? "Current User",
            bio: request.bio,
            avatarUrl: request.avatarUrl,
            createdAt: Date().addingTimeInterval(-86400 * 30)
        )
    }
}

