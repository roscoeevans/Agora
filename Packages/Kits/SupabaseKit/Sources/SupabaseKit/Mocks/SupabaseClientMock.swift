//
//  SupabaseClientMock.swift
//  SupabaseKit
//
//  Mock implementation of SupabaseClientProtocol for testing
//

import Foundation

/// Mock implementation of SupabaseClientProtocol for testing and development
public struct SupabaseClientMock: SupabaseClientProtocol {
    public let auth: SupabaseAuthProtocol
    public let realtime: SupabaseRealtimeProtocol
    public let storage: SupabaseStorageProtocol
    public let database: SupabaseDatabaseProtocol
    
    /// Mock raw client - returns a placeholder object
    public var rawClient: Any {
        return "MockSupabaseClient"
    }
    
    public init(
        auth: SupabaseAuthProtocol? = nil,
        realtime: SupabaseRealtimeProtocol? = nil,
        storage: SupabaseStorageProtocol? = nil,
        database: SupabaseDatabaseProtocol? = nil
    ) {
        self.auth = auth ?? SupabaseAuthMock()
        self.realtime = realtime ?? SupabaseRealtimeMock()
        self.storage = storage ?? SupabaseStorageMock()
        self.database = database ?? SupabaseDatabaseMock()
    }
}

/// Mock implementation of SupabaseAuthProtocol
public struct SupabaseAuthMock: SupabaseAuthProtocol {
    public var mockSession: AuthSession?
    public var shouldSucceed: Bool = true
    public var operationDelay: TimeInterval = 0.1
    
    public init(mockSession: AuthSession? = nil) {
        self.mockSession = mockSession ?? AuthSession(
            accessToken: "mock_access_token",
            refreshToken: "mock_refresh_token",
            expiresAt: Date().addingTimeInterval(3600),
            user: AuthUser(
                id: "mock_user_123",
                email: "test@example.com",
                phone: nil,
                userMetadata: [:]
            )
        )
    }
    
    public var session: AuthSession? {
        get async {
            try? await Task.sleep(nanoseconds: UInt64(operationDelay * 1_000_000_000))
            return mockSession
        }
    }
    
    public func signInWithApple(idToken: String, nonce: String) async throws -> AuthSession {
        try await Task.sleep(nanoseconds: UInt64(operationDelay * 1_000_000_000))
        
        if !shouldSucceed {
            throw SupabaseError.authenticationFailed
        }
        
        return mockSession!
    }
    
    public func signOut() async throws {
        try await Task.sleep(nanoseconds: UInt64(operationDelay * 1_000_000_000))
        
        if !shouldSucceed {
            throw SupabaseError.authenticationFailed
        }
        
        // Mock implementation - don't actually mutate state
    }
    
    public func refreshSession() async throws -> AuthSession {
        try await Task.sleep(nanoseconds: UInt64(operationDelay * 1_000_000_000))
        
        if !shouldSucceed {
            throw SupabaseError.authenticationFailed
        }
        
        return mockSession!
    }
}

/// Mock implementation of SupabaseRealtimeProtocol
public struct SupabaseRealtimeMock: SupabaseRealtimeProtocol {
    public var mockEngagementUpdates: [RealtimeEngagementUpdate] = []
    public var mockNotifications: [NotificationUpdate] = []
    public var shouldEmitUpdates: Bool = true
    public var updateInterval: TimeInterval = 1.0
    
    public init() {}
    
    public func subscribeToPostEngagement(postId: String) -> AsyncStream<RealtimeEngagementUpdate> {
        AsyncStream { continuation in
            Task {
                while shouldEmitUpdates {
                    for update in mockEngagementUpdates {
                        if update.postId == postId {
                            continuation.yield(update)
                        }
                    }
                    try? await Task.sleep(nanoseconds: UInt64(updateInterval * 1_000_000_000))
                }
                continuation.finish()
            }
        }
    }
    
    public func subscribeToUserNotifications(userId: String) -> AsyncStream<NotificationUpdate> {
        AsyncStream { continuation in
            Task {
                while shouldEmitUpdates {
                    for notification in mockNotifications {
                        continuation.yield(notification)
                    }
                    try? await Task.sleep(nanoseconds: UInt64(updateInterval * 1_000_000_000))
                }
                continuation.finish()
            }
        }
    }
    
    public func subscribeToTable<T: Codable>(_ table: String, filter: String?) -> AsyncStream<RealtimeChange<T>> {
        AsyncStream { continuation in
            // Mock implementation - doesn't emit any changes
            continuation.finish()
        }
    }
}

/// Mock implementation of SupabaseStorageProtocol
public struct SupabaseStorageMock: SupabaseStorageProtocol {
    public var shouldSucceed: Bool = true
    public var operationDelay: TimeInterval = 0.5
    public var mockBaseURL: String = "https://mock.supabase.co/storage/v1/object/public"
    
    public init() {}
    
    public func uploadImage(data: Data, path: String) async throws -> URL {
        try await Task.sleep(nanoseconds: UInt64(operationDelay * 1_000_000_000))
        
        if !shouldSucceed {
            throw SupabaseError.storageError("Upload failed")
        }
        
        return URL(string: "\(mockBaseURL)/images/\(path)")!
    }
    
    public func uploadVideo(data: Data, path: String) async throws -> URL {
        try await Task.sleep(nanoseconds: UInt64(operationDelay * 1_000_000_000))
        
        if !shouldSucceed {
            throw SupabaseError.storageError("Upload failed")
        }
        
        return URL(string: "\(mockBaseURL)/videos/\(path)")!
    }
    
    public func getPublicURL(path: String) throws -> URL {
        return URL(string: "\(mockBaseURL)/images/\(path)")!
    }
    
    public func deleteFile(path: String) async throws {
        try await Task.sleep(nanoseconds: UInt64(operationDelay * 1_000_000_000))
        
        if !shouldSucceed {
            throw SupabaseError.storageError("Delete failed")
        }
    }
}

/// Mock implementation of SupabaseDatabaseProtocol
public struct SupabaseDatabaseMock: SupabaseDatabaseProtocol {
    public var mockPosts: [Post] = []
    public var shouldSucceed: Bool = true
    public var operationDelay: TimeInterval = 0.2
    
    public init() {}
    
    public func fetchPosts(limit: Int, cursor: String?) async throws -> [Post] {
        try await Task.sleep(nanoseconds: UInt64(operationDelay * 1_000_000_000))
        
        if !shouldSucceed {
            throw SupabaseError.databaseError("Fetch failed")
        }
        
        return Array(mockPosts.prefix(limit))
    }
    
    public func createPost(_ post: CreatePostRequest) async throws -> Post {
        try await Task.sleep(nanoseconds: UInt64(operationDelay * 1_000_000_000))
        
        if !shouldSucceed {
            throw SupabaseError.databaseError("Create failed")
        }
        
        let newPost = Post(
            id: UUID().uuidString,
            authorId: "mock_user_123",
            authorDisplayHandle: "testuser",
            text: post.text,
            replyToPostId: post.replyToPostId,
            createdAt: Date(),
            authorDisplayName: "Test User"
        )
        
        // Mock implementation - don't actually mutate mockPosts
        return newPost
    }
    
    public func updateEngagement(postId: String, engagement: EngagementUpdate) async throws {
        try await Task.sleep(nanoseconds: UInt64(operationDelay * 1_000_000_000))
        
        if !shouldSucceed {
            throw SupabaseError.databaseError("Update failed")
        }
        
        // Mock implementation - would update the post in mockPosts
    }
    
    public func execute<T: Codable, Params: Encodable & Sendable>(_ query: String, parameters: Params) async throws -> [T] {
        try await Task.sleep(nanoseconds: UInt64(operationDelay * 1_000_000_000))
        
        if !shouldSucceed {
            throw SupabaseError.databaseError("Execute failed")
        }
        
        return []
    }
}

// MARK: - Mock Errors

public enum SupabaseError: LocalizedError, Sendable {
    case authenticationFailed
    case storageError(String)
    case databaseError(String)
    case realtimeError(String)
    
    public var errorDescription: String? {
        switch self {
        case .authenticationFailed:
            return "Mock authentication failed"
        case .storageError(let message):
            return "Mock storage error: \(message)"
        case .databaseError(let message):
            return "Mock database error: \(message)"
        case .realtimeError(let message):
            return "Mock realtime error: \(message)"
        }
    }
}
