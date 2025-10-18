import Foundation
import OpenAPIRuntime
import OpenAPIURLSession
import AppFoundation
import HTTPTypes

/// Main API client for Agora backend communication
/// 
/// This is a concrete implementation that conforms to AgoraAPIClient protocol.
/// Use the protocol for dependency injection, not this concrete class.
/// 
/// **Dependency Injection**: This class should be instantiated via the Dependencies
/// container and injected through initializers. Do not create instances directly
/// in production code.
/// 
/// Example usage:
/// ```swift
/// // In a ViewModel init:
/// public init(networking: any AgoraAPIClient) {
///     self.networking = networking
/// }
/// 
/// // In a View with environment:
/// @Environment(\.deps) private var deps
/// let viewModel = MyViewModel(networking: deps.networking)
/// ```
public final class APIClient: AgoraAPIClient, Sendable {
    private let client: Client
    private let authTokenProvider: AuthTokenProvider?
    private let baseURL: URL
    
    /// Initialize API client with optional authentication
    /// - Parameters:
    ///   - baseURL: Base URL for the API (defaults to environment-specific URL from AppConfig)
    ///   - authTokenProvider: Provider for authentication tokens
    public init(
        baseURL: URL = AppConfig.apiBaseURL,
        authTokenProvider: AuthTokenProvider? = nil
    ) {
        self.baseURL = baseURL
        self.authTokenProvider = authTokenProvider
        
        // Create URLSession with custom configuration
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        
        // Add Supabase anon key header for Edge Functions
        configuration.httpAdditionalHeaders = [
            "apikey": AppConfig.supabaseAnonKey
        ]
        
        let urlSession = URLSession(configuration: configuration)
        let transport = URLSessionTransport(configuration: .init(session: urlSession))
        
        // Configure lenient ISO8601 date decoding (handles fractional seconds)
        var converterConfig = Configuration()
        converterConfig.dateTranscoder = .iso8601WithFractionalSeconds
        
        // Create OpenAPI client with Supabase authentication
        self.client = Client(
            serverURL: baseURL,
            configuration: converterConfig,
            transport: transport,
            middlewares: [SupabaseAuthMiddleware(tokenProvider: authTokenProvider)]
        )
    }
    
    /// Get the underlying OpenAPI client for direct access
    public var openAPIClient: Client {
        client
    }
}

// MARK: - Convenience Methods

extension APIClient {
    /// Perform authenticated request with automatic token injection
    public func performRequest<T: Sendable>(
        _ operation: @Sendable @escaping (Client) async throws -> T
    ) async throws -> T {
        do {
            return try await operation(client)
        } catch let error as ClientError {
            throw mapClientError(error)
        } catch {
            throw NetworkError.unknownError(error)
        }
    }
    
    /// Map OpenAPI client errors to NetworkError
    private func mapClientError(_ error: ClientError) -> NetworkError {
        // For now, map all client errors to unknown error
        // This can be expanded as we understand the actual error types better
        return .unknownError(error)
    }
}

// MARK: - Supabase Auth Middleware

/// Middleware to add Supabase authentication headers
struct SupabaseAuthMiddleware: ClientMiddleware {
    let tokenProvider: AuthTokenProvider?
    
    func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        var request = request
        
        // Add user's access token if available, otherwise use anon key
        // Supabase Edge Functions need the user's session token for auth
        if let token = try? await tokenProvider?.currentAccessToken() {
            request.headerFields[.authorization] = "Bearer \(token)"
        } else {
            // Fallback to anon key for unauthenticated requests
            request.headerFields[.authorization] = "Bearer \(AppConfig.supabaseAnonKey)"
        }
        
        return try await next(request, body, baseURL)
    }
}
// MARK: - Feed Operations

extension APIClient {
    /// Get the For You feed
    /// - Parameters:
    ///   - cursor: Pagination cursor for next page
    ///   - limit: Number of posts to fetch (default: 20, max: 50)
    /// - Returns: Feed response with posts and next cursor
    public func getForYouFeed(cursor: String? = nil, limit: Int = 20) async throws -> Components.Schemas.FeedResponse {
        return try await performRequest { client in
            let response = try await client.get_sol_feed_sol_for_hyphen_you(
                query: .init(
                    cursor: cursor,
                    limit: limit
                )
            )
            
            switch response {
            case .ok(let okResponse):
                switch okResponse.body {
                case .json(let feedResponse):
                    return feedResponse
                }
            case .unauthorized:
                throw NetworkError.authenticationRequired
            case .internalServerError:
                throw NetworkError.serverError(message: "Internal server error")
            case .undocumented(let statusCode, _):
                throw NetworkError.httpError(statusCode: statusCode, data: nil)
            }
        }
    }
}

// MARK: - AgoraAPIClient Protocol Conformance

extension APIClient {
    /// Fetch For You feed (protocol method)
    /// Bridges to internal getForYouFeed implementation
    public func fetchForYouFeed(cursor: String?, limit: Int?) async throws -> FeedResponse {
        let response = try await getForYouFeed(cursor: cursor, limit: limit ?? 20)
        // Convert from generated Components.Schemas.FeedResponse to protocol FeedResponse
        let posts = response.posts.map { enhancedPost in
            let post = enhancedPost.value1
            let enhanced = enhancedPost.value2
            
            // Map recommendation reasons from generated types to protocol types
            let reasons = enhanced.reasons?.map { reason in
                RecommendationReason(
                    signal: reason.signal,
                    weight: Double(reason.weight)
                )
            }
            
            return Post(
                id: post.id,
                authorId: post.authorId,
                authorDisplayHandle: post.authorDisplayHandle,
                text: post.text,
                linkUrl: post.linkUrl,
                mediaBundleId: post.mediaBundleId,
                replyToPostId: post.replyToPostId,
                quotePostId: post.quotePostId,
                likeCount: post.likeCount ?? 0,
                repostCount: post.repostCount ?? 0,
                replyCount: post.replyCount ?? 0,
                visibility: post.visibility.flatMap { PostVisibility(rawValue: $0.rawValue) } ?? .public,
                createdAt: post.createdAt,
                score: enhanced.score.map(Double.init),
                reasons: reasons,
                explore: enhanced.explore
            )
        }
        return FeedResponse(posts: posts, nextCursor: response.nextCursor)
    }
    
    public func beginSignInWithApple(nonce: String) async throws -> SWABeginResponse {
        let response = try await beginSignInWithAppleInternal(nonce: nonce)
        return SWABeginResponse(authUrl: response.authUrl ?? "")
    }
    
    public func finishSignInWithApple(identityToken: String, authorizationCode: String) async throws -> AuthResponse {
        let response = try await finishSignInWithAppleInternal(identityToken: identityToken, authorizationCode: authorizationCode)
        return AuthResponse(
            accessToken: response.accessToken ?? "",
            refreshToken: response.refreshToken ?? "",
            user: User(
                id: response.user.id ?? "",
                handle: response.user.handle ?? "",
                displayHandle: response.user.displayHandle ?? "",
                displayName: response.user.displayName ?? "",
                bio: response.user.bio,
                avatarUrl: response.user.avatarUrl,
                createdAt: response.user.createdAt ?? Date()
            )
        )
    }
    
    public func createProfile(request: CreateProfileRequest) async throws -> User {
        return try await performRequest { client in
            let response = try await client.post_sol_create_hyphen_profile(
                body: .json(request.toComponentsSchemas())
            )
            
            switch response {
            case .created(let createdResponse):
                switch createdResponse.body {
                case .json(let user):
                    return user.toAppFoundation()
                }
            case .badRequest:
                throw NetworkError.serverError(message: "Bad request")
            case .unauthorized:
                throw NetworkError.authenticationRequired
            case .conflict:
                throw NetworkError.serverError(message: "Handle already taken")
            case .internalServerError:
                throw NetworkError.serverError(message: "Internal server error")
            case .undocumented(let statusCode, _):
                throw NetworkError.httpError(statusCode: statusCode, data: nil)
            }
        }
    }
    
    public func checkHandle(handle: String) async throws -> CheckHandleResponse {
        return try await performRequest { client in
            let response = try await client.get_sol_check_hyphen_handle(
                query: .init(handle: handle)
            )
            
            switch response {
            case .ok(let okResponse):
                switch okResponse.body {
                case .json(let checkResponse):
                    return checkResponse.toAppFoundation()
                }
            case .badRequest:
                throw NetworkError.serverError(message: "Bad request")
            case .internalServerError:
                throw NetworkError.serverError(message: "Internal server error")
            case .undocumented(let statusCode, _):
                throw NetworkError.httpError(statusCode: statusCode, data: nil)
            }
        }
    }
    
    public func getCurrentUserProfile() async throws -> User {
        return try await performRequest { client in
            let response = try await client.get_sol_get_hyphen_current_hyphen_profile()
            
            switch response {
            case .ok(let okResponse):
                switch okResponse.body {
                case .json(let user):
                    return user.toAppFoundation()
                }
            case .unauthorized:
                throw NetworkError.authenticationRequired
            case .notFound:
                throw NetworkError.serverError(message: "Profile not found")
            case .internalServerError:
                throw NetworkError.serverError(message: "Internal server error")
            case .undocumented(let statusCode, _):
                throw NetworkError.httpError(statusCode: statusCode, data: nil)
            }
        }
    }
    
    public func updateProfile(request: UpdateProfileRequest) async throws -> User {
        return try await performRequest { client in
            let response = try await client.patch_sol_update_hyphen_profile(
                body: .json(request.toComponentsSchemas())
            )
            
            switch response {
            case .ok(let okResponse):
                switch okResponse.body {
                case .json(let user):
                    return user.toAppFoundation()
                }
            case .badRequest:
                throw NetworkError.serverError(message: "Bad request")
            case .unauthorized:
                throw NetworkError.authenticationRequired
            case .internalServerError:
                throw NetworkError.serverError(message: "Internal server error")
            case .undocumented(let statusCode, _):
                throw NetworkError.httpError(statusCode: statusCode, data: nil)
            }
        }
    }
    
    // MARK: - Extended Feed Operations
    
    public func fetchFollowingFeed(cursor: String?, limit: Int?) async throws -> FollowingFeedResponse {
        // Direct HTTP call until OpenAPI regeneration
        guard let token = try? await authTokenProvider?.currentAccessToken() else {
            throw NetworkError.authenticationRequired
        }
        
        var components = URLComponents(url: baseURL.appending(path: "/feed-following"), resolvingAgainstBaseURL: false)!
        var queryItems: [URLQueryItem] = []
        if let cursor = cursor {
            queryItems.append(URLQueryItem(name: "cursor", value: cursor))
        }
        if let limit = limit {
            queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        }
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        
        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(AppConfig.supabaseAnonKey, forHTTPHeaderField: "apikey")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.serverError(message: "Invalid response")
        }
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 {
                throw NetworkError.authenticationRequired
            }
            throw NetworkError.httpError(statusCode: httpResponse.statusCode, data: data)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(FollowingFeedResponse.self, from: data)
    }
    
    public func getUserProfile(userId: String) async throws -> UserProfileWithStats {
        // Direct HTTP call until OpenAPI regeneration
        let url = baseURL.appending(path: "/get-user-profile/\(userId)")
        
        var request = URLRequest(url: url)
        if let token = try? await authTokenProvider?.currentAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(AppConfig.supabaseAnonKey, forHTTPHeaderField: "apikey")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.serverError(message: "Invalid response")
        }
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 404 {
                throw NetworkError.notFound(message: "User not found")
            }
            throw NetworkError.httpError(statusCode: httpResponse.statusCode, data: data)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(UserProfileWithStats.self, from: data)
    }
    
    public func getUserPosts(userId: String, cursor: String?, limit: Int?) async throws -> UserPostsResponse {
        // Direct HTTP call until OpenAPI regeneration
        guard let token = try? await authTokenProvider?.currentAccessToken() else {
            throw NetworkError.authenticationRequired
        }
        
        var components = URLComponents(url: baseURL.appending(path: "/get-user-posts/\(userId)"), resolvingAgainstBaseURL: false)!
        var queryItems: [URLQueryItem] = []
        if let cursor = cursor {
            queryItems.append(URLQueryItem(name: "cursor", value: cursor))
        }
        if let limit = limit {
            queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        }
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        
        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(AppConfig.supabaseAnonKey, forHTTPHeaderField: "apikey")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.serverError(message: "Invalid response")
        }
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 {
                throw NetworkError.authenticationRequired
            }
            if httpResponse.statusCode == 404 {
                throw NetworkError.notFound(message: "User not found")
            }
            throw NetworkError.httpError(statusCode: httpResponse.statusCode, data: data)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(UserPostsResponse.self, from: data)
    }
    
    public func createPost(
        text: String,
        mediaBundleId: String?,
        linkUrl: String?,
        quotePostId: String?,
        replyToPostId: String?,
        selfDestructAt: Date?
    ) async throws -> Post {
        print("[APIClient] 📝 Creating post with text: \(text.prefix(50))...")
        
        guard let token = try? await authTokenProvider?.currentAccessToken() else {
            print("[APIClient] ❌ No auth token available")
            throw NetworkError.authenticationRequired
        }
        
        print("[APIClient] ✅ Got auth token")
        
        var request = URLRequest(url: baseURL.appending(path: "/create-post"))
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(AppConfig.supabaseAnonKey, forHTTPHeaderField: "apikey")
        
        // Create request body
        var body: [String: Any] = ["text": text]
        if let mediaBundleId = mediaBundleId {
            body["media_bundle_id"] = mediaBundleId
        }
        if let linkUrl = linkUrl {
            body["link_url"] = linkUrl
        }
        if let quotePostId = quotePostId {
            body["quote_post_id"] = quotePostId
        }
        if let replyToPostId = replyToPostId {
            body["reply_to_post_id"] = replyToPostId
        }
        if let selfDestructAt = selfDestructAt {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            body["self_destruct_at"] = formatter.string(from: selfDestructAt)
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        print("[APIClient] 🌐 Sending POST to: \(request.url?.absoluteString ?? "unknown")")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("[APIClient] ❌ Invalid HTTP response")
            throw NetworkError.serverError(message: "Invalid response")
        }
        
        print("[APIClient] 📡 Response status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 201 else {
            if httpResponse.statusCode == 401 {
                print("[APIClient] ❌ Authentication required")
                throw NetworkError.authenticationRequired
            }
            if let responseString = String(data: data, encoding: .utf8) {
                print("[APIClient] ❌ Error response: \(responseString)")
            }
            throw NetworkError.httpError(statusCode: httpResponse.statusCode, data: data)
        }
        
        print("[APIClient] ✅ Post created successfully!")
        
        // Decode response - the Edge Function returns the raw database row
        struct CreatePostResponse: Codable {
            let id: String  // Bigserial is returned as string in JSON
            let author_id: String
            let text: String
            let link_url: String?
            let media_bundle_id: String?  // Also returned as string
            let reply_to_post_id: String?
            let quote_post_id: String?
            let like_count: Int
            let repost_count: Int
            let reply_count: Int
            let visibility: String
            let created_at: String
            let edited_at: String?
            let self_destruct_at: String?
        }
        
        let decoder = JSONDecoder()
        let dbPost = try decoder.decode(CreatePostResponse.self, from: data)
        
        // Transform to Post model
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        return Post(
            id: dbPost.id,
            authorId: dbPost.author_id,
            authorDisplayHandle: "", // Will be fetched separately if needed
            text: dbPost.text,
            linkUrl: dbPost.link_url,
            mediaBundleId: dbPost.media_bundle_id,
            replyToPostId: dbPost.reply_to_post_id,
            quotePostId: dbPost.quote_post_id,
            likeCount: dbPost.like_count,
            repostCount: dbPost.repost_count,
            replyCount: dbPost.reply_count,
            visibility: PostVisibility(rawValue: dbPost.visibility) ?? .public,
            createdAt: dateFormatter.date(from: dbPost.created_at) ?? Date()
        )
    }
}

// MARK: - Authentication Operations

extension APIClient {
    /// Begin Sign in with Apple flow (internal implementation)
    /// - Parameter nonce: Random nonce for security
    /// - Returns: Apple authentication URL
    private func beginSignInWithAppleInternal(nonce: String) async throws -> Components.Schemas.SWABeginResponse {
        return try await performRequest { client in
            let response = try await client.post_sol_auth_sol_swa_sol_begin(
                body: .json(.init(nonce: nonce))
            )
            
            switch response {
            case .ok(let okResponse):
                switch okResponse.body {
                case .json(let beginResponse):
                    return beginResponse
                }
            case .badRequest:
                throw NetworkError.serverError(message: "Bad request")
            case .internalServerError:
                throw NetworkError.serverError(message: "Internal server error")
            case .undocumented(let statusCode, _):
                throw NetworkError.httpError(statusCode: statusCode, data: nil)
            }
        }
    }
    
    /// Complete Sign in with Apple flow (internal implementation)
    /// - Parameters:
    ///   - identityToken: Apple identity token
    ///   - authorizationCode: Apple authorization code
    /// - Returns: Authentication response with tokens and user info
    private func finishSignInWithAppleInternal(
        identityToken: String,
        authorizationCode: String
    ) async throws -> Components.Schemas.AuthResponse {
        return try await performRequest { client in
            let response = try await client.post_sol_auth_sol_swa_sol_finish(
                body: .json(.init(
                    identityToken: identityToken,
                    authorizationCode: authorizationCode
                ))
            )
            
            switch response {
            case .ok(let okResponse):
                switch okResponse.body {
                case .json(let authResponse):
                    return authResponse
                }
            case .badRequest:
                throw NetworkError.serverError(message: "Bad request")
            case .unauthorized:
                throw NetworkError.authenticationRequired
            case .internalServerError:
                throw NetworkError.serverError(message: "Internal server error")
            case .undocumented(let statusCode, _):
                throw NetworkError.httpError(statusCode: statusCode, data: nil)
            }
        }
    }
}