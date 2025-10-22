//
//  SupabaseClientLive.swift
//  SupabaseKit
//
//  Live implementation of SupabaseClientProtocol
//

import Foundation
@preconcurrency import Supabase

/// Live implementation of SupabaseClientProtocol using the real Supabase Swift SDK
public struct SupabaseClientLive: SupabaseClientProtocol {
    private let client: SupabaseClient
    
    public let auth: SupabaseAuthProtocol
    public let realtime: SupabaseRealtimeProtocol
    public let storage: SupabaseStorageProtocol
    public let database: SupabaseDatabaseProtocol
    
    /// Raw Supabase client for advanced usage
    public var rawClient: Any {
        return client
    }
    
    public init(url: String, key: String) {
        self.client = SupabaseClient(supabaseURL: URL(string: url)!, supabaseKey: key)
        
        // Initialize service wrappers
        self.auth = SupabaseAuthLive(client: client.auth)
        self.realtime = SupabaseRealtimeLive(client: client.realtimeV2)
        self.storage = SupabaseStorageLive(client: client.storage)
        self.database = SupabaseDatabaseLive(client: client.database)
    }
}

/// Live implementation of SupabaseAuthProtocol
public struct SupabaseAuthLive: SupabaseAuthProtocol {
    private let auth: AuthClient
    
    public init(client: AuthClient) {
        self.auth = client
    }
    
    public var session: AuthSession? {
        get async {
            guard let session = try? await auth.session else { return nil }
            return AuthSession(
                accessToken: session.accessToken,
                refreshToken: session.refreshToken,
                expiresAt: Date(timeIntervalSince1970: session.expiresAt),
                user: AuthUser(
                    id: session.user.id.uuidString,
                    email: session.user.email,
                    phone: session.user.phone,
                    userMetadata: convertUserMetadata(session.user.userMetadata)
                )
            )
        }
    }
    
    private func convertUserMetadata(_ metadata: [String: AnyJSON]) -> [String: AnyCodable] {
        metadata.mapValues { json in
            AnyCodable(convertAnyJSON(json))
        }
    }
    
    private func convertAnyJSON(_ json: AnyJSON) -> Any {
        switch json {
        case .string(let value): return value
        case .integer(let value): return value
        case .double(let value): return value
        case .bool(let value): return value
        case .null: return NSNull()
        case .array(let array): return array.map { convertAnyJSON($0) }
        case .object(let dict): return dict.mapValues { convertAnyJSON($0) }
        }
    }
    
    public func signInWithApple(idToken: String, nonce: String) async throws -> AuthSession {
        let session = try await auth.signInWithIdToken(credentials: .init(
            provider: .apple,
            idToken: idToken,
            nonce: nonce
        ))
        
        return AuthSession(
            accessToken: session.accessToken,
            refreshToken: session.refreshToken,
            expiresAt: Date(timeIntervalSince1970: session.expiresAt),
            user: AuthUser(
                id: session.user.id.uuidString,
                email: session.user.email,
                phone: session.user.phone,
                userMetadata: convertUserMetadata(session.user.userMetadata)
            )
        )
    }
    
    public func signOut() async throws {
        try await auth.signOut()
    }
    
    public func refreshSession() async throws -> AuthSession {
        let session = try await auth.refreshSession()
        return AuthSession(
            accessToken: session.accessToken,
            refreshToken: session.refreshToken,
            expiresAt: Date(timeIntervalSince1970: session.expiresAt),
            user: AuthUser(
                id: session.user.id.uuidString,
                email: session.user.email,
                phone: session.user.phone,
                userMetadata: convertUserMetadata(session.user.userMetadata)
            )
        )
    }
}

/// Live implementation of SupabaseRealtimeProtocol
public struct SupabaseRealtimeLive: SupabaseRealtimeProtocol {
    private let realtime: RealtimeClientV2
    
    public init(client: RealtimeClientV2) {
        self.realtime = client
    }
    
    public func subscribeToPostEngagement(postId: String) -> AsyncStream<RealtimeEngagementUpdate> {
        AsyncStream { continuation in
            // TODO: Implement RealtimeV2 API integration
            // The RealtimeV2 API has changed significantly from deprecated RealtimeClient
            // For now, this is a placeholder that doesn't emit updates
            continuation.finish()
        }
    }
    
    public func subscribeToUserNotifications(userId: String) -> AsyncStream<NotificationUpdate> {
        AsyncStream { continuation in
            // TODO: Implement RealtimeV2 API integration
            // The RealtimeV2 API has changed significantly from deprecated RealtimeClient
            // For now, this is a placeholder that doesn't emit updates
            continuation.finish()
        }
    }
    
    public func subscribeToTable<T: Codable>(_ table: String, filter: String?) -> AsyncStream<RealtimeChange<T>> {
        AsyncStream { continuation in
            // TODO: Implement RealtimeV2 API integration
            // The RealtimeV2 API has changed significantly from deprecated RealtimeClient
            // For now, this is a placeholder that doesn't emit updates
            continuation.finish()
        }
    }
}

/// Live implementation of SupabaseStorageProtocol
public struct SupabaseStorageLive: SupabaseStorageProtocol {
    private let storage: SupabaseStorageClient
    
    public init(client: SupabaseStorageClient) {
        self.storage = client
    }
    
    public func uploadImage(data: Data, path: String) async throws -> URL {
        _ = try await storage.from("images").upload(
            path,
            data: data,
            options: FileOptions(contentType: "image/jpeg")
        )
        return try getPublicURL(path: path)
    }
    
    public func uploadVideo(data: Data, path: String) async throws -> URL {
        _ = try await storage.from("videos").upload(
            path,
            data: data,
            options: FileOptions(contentType: "video/mp4")
        )
        return try getPublicURL(path: path)
    }
    
    public func getPublicURL(path: String) throws -> URL {
        return try storage.from("images").getPublicURL(path: path)
    }
    
    public func deleteFile(path: String) async throws {
        try await storage.from("images").remove(paths: [path])
    }
}

/// Live implementation of SupabaseDatabaseProtocol
public struct SupabaseDatabaseLive: SupabaseDatabaseProtocol {
    private let database: PostgrestClient
    
    public init(client: PostgrestClient) {
        self.database = client
    }
    
    public func fetchPosts(limit: Int, cursor: String?) async throws -> [Post] {
        // TODO: Implement cursor-based pagination when Postgrest API is properly integrated
        // For now, just fetch the latest posts without cursor support
        let query = database.from("posts")
            .select("*, author:profiles(*)")
            .order("created_at", ascending: false)
            .limit(limit)
        
        let response: [Post] = try await query.execute().value
        return response
    }
    
    public func createPost(_ post: CreatePostRequest) async throws -> Post {
        let response: Post = try await database
            .from("posts")
            .insert(post)
            .select("*, author:profiles(*)")
            .single()
            .execute()
            .value
        
        return response
    }
    
    public func updateEngagement(postId: String, engagement: EngagementUpdate) async throws {
        try await database
            .from("posts")
            .update([
                "like_count": engagement.likeCount,
                "repost_count": engagement.repostCount,
                "reply_count": engagement.replyCount
            ])
            .eq("id", value: postId)
            .execute()
    }
    
    public func execute<T: Codable, Params: Encodable & Sendable>(_ query: String, parameters: Params) async throws -> [T] {
        // Note: RPC API has changed in newer Supabase SDK
        // This is a simplified implementation that may need adjustment based on actual RPC usage
        let response: [T] = try await database.rpc(query, params: parameters).execute().value
        return response
    }
}
