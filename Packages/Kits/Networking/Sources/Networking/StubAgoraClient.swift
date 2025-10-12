import Foundation

/// Stub implementation of AgoraAPIClient for development and testing
public final class StubAgoraClient: AgoraAPIClient {
    
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
                text: "This is a test post from the stub client! 🚀",
                likeCount: 42,
                repostCount: 7,
                replyCount: 3,
                createdAt: Date().addingTimeInterval(-3600)
            ),
            Post(
                id: "post-2",
                authorId: "user-456",
                text: "Another mock post for testing the feed UI.",
                likeCount: 15,
                repostCount: 2,
                replyCount: 1,
                createdAt: Date().addingTimeInterval(-7200)
            ),
            Post(
                id: "post-3",
                authorId: "user-789",
                text: "Stub client is great for offline development! 💡",
                linkUrl: "https://example.com",
                likeCount: 28,
                repostCount: 5,
                replyCount: 8,
                createdAt: Date().addingTimeInterval(-10800)
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
    
    public func createProfile(request: Components.Schemas.CreateProfileRequest) async throws -> Components.Schemas.User {
        // Simulate network delay
        try await Task.sleep(for: .milliseconds(600))
        
        // Return mock created user
        return Components.Schemas.User(
            id: UUID().uuidString,
            handle: request.handle,
            displayHandle: request.displayHandle,
            displayName: request.displayName,
            createdAt: Date()
        )
    }
    
    public func checkHandle(handle: String) async throws -> Components.Schemas.CheckHandleResponse {
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
        
        return Components.Schemas.CheckHandleResponse(
            available: isAvailable,
            suggestions: isAvailable ? nil : suggestions
        )
    }
    
    public func getCurrentUserProfile() async throws -> Components.Schemas.User {
        // Simulate network delay
        try await Task.sleep(for: .milliseconds(300))
        
        // Return mock current user
        return Components.Schemas.User(
            id: "mock-user-id",
            handle: "currentuser",
            displayHandle: "CurrentUser",
            displayName: "Current User",
            bio: "This is the currently logged in mock user",
            avatarUrl: nil,
            createdAt: Date().addingTimeInterval(-86400 * 30)
        )
    }
    
    public func updateProfile(request: Components.Schemas.UpdateProfileRequest) async throws -> Components.Schemas.User {
        // Simulate network delay
        try await Task.sleep(for: .milliseconds(500))
        
        // Return updated mock user
        return Components.Schemas.User(
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

