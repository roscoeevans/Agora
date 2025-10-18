import Foundation
import OpenAPIRuntime
import OpenAPIURLSession
import HTTPTypes
import AppFoundation

/// Production implementation of AgoraAPIClient using OpenAPI-generated code
public final class OpenAPIAgoraClient: AgoraAPIClient {
    private let client: Client
    private let authTokenProvider: AuthTokenProvider
    private let baseURL: URL
    
    /// Initialize OpenAPI-based Agora API client
    /// - Parameters:
    ///   - baseURL: Base URL for the API
    ///   - session: URLSession for networking (defaults to .shared)
    ///   - authTokenProvider: Provider for auth tokens
    public init(
        baseURL: URL, 
        session: URLSession = .shared, 
        authTokenProvider: AuthTokenProvider
    ) {
        self.authTokenProvider = authTokenProvider
        self.baseURL = baseURL
        
        let transport = URLSessionTransport(
            configuration: .init(session: session)
        )
        
        // Configure lenient ISO8601 date decoding (handles fractional seconds)
        var converterConfig = Configuration()
        converterConfig.dateTranscoder = .iso8601WithFractionalSeconds
        
        self.client = Client(
            serverURL: baseURL,
            configuration: converterConfig,
            transport: transport,
            middlewares: [AuthMiddleware(tokenProvider: authTokenProvider)]
        )
    }
    
    // MARK: - Feed Operations
    
    public func fetchForYouFeed(cursor: String?, limit: Int?) async throws -> FeedResponse {
        let response = try await client.get_sol_feed_sol_for_hyphen_you(
            query: .init(cursor: cursor, limit: limit)
        )
        
        switch response {
        case .ok(let ok):
            let generatedResponse = try ok.body.json
            // Convert from generated Components.Schemas.FeedResponse to manual FeedResponse
            // EnhancedPost uses allOf, so value1 has base Post, value2 has enhanced metadata
            let posts = generatedResponse.posts.map { enhancedPost in
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
            return FeedResponse(posts: posts, nextCursor: generatedResponse.nextCursor)
        case .unauthorized:
            throw NetworkError.authenticationRequired
        case .internalServerError(let error):
            let errorBody = try? error.body.json
            throw NetworkError.serverError(message: errorBody?.message ?? "Internal server error")
        case .undocumented(let statusCode, _):
            throw NetworkError.httpError(statusCode: statusCode, data: nil)
        }
    }
    
    // MARK: - Authentication Operations
    
    public func beginSignInWithApple(nonce: String) async throws -> SWABeginResponse {
        // TODO: Replace with generated API call once available
        // Example (after generation):
        // let response = try await client.post_slash_auth_slash_swa_slash_begin(
        //     body: .json(.init(nonce: nonce))
        // )
        // return try response.ok.body.json
        
        print("[OpenAPIAgoraClient] beginSignInWithApple not yet wired to generated client")
        throw NetworkError.serverError(message: "Not yet implemented")
    }
    
    public func finishSignInWithApple(identityToken: String, authorizationCode: String) async throws -> AuthResponse {
        // TODO: Replace with generated API call once available
        // Example (after generation):
        // let response = try await client.post_slash_auth_slash_swa_slash_finish(
        //     body: .json(.init(
        //         identityToken: identityToken,
        //         authorizationCode: authorizationCode
        //     ))
        // )
        // return try response.ok.body.json
        
        print("[OpenAPIAgoraClient] finishSignInWithApple not yet wired to generated client")
        throw NetworkError.serverError(message: "Not yet implemented")
    }
    
    // MARK: - User Profile Operations
    
    public func createProfile(request: CreateProfileRequest) async throws -> User {
        // Convert AppFoundation request to Components.Schemas request
        let componentsRequest = request.toComponentsSchemas()
        let response = try await client.post_sol_create_hyphen_profile(
            .init(body: .json(componentsRequest))
        )
        
        switch response {
        case .created(let created):
            let generatedUser = try created.body.json
            return generatedUser.toAppFoundation()
        case .badRequest(let error):
            let errorBody = try? error.body.json
            throw NetworkError.serverError(message: errorBody?.message ?? "Bad request")
        case .unauthorized:
            throw NetworkError.authenticationRequired
        case .conflict(let error):
            let errorBody = try? error.body.json
            throw NetworkError.serverError(message: errorBody?.message ?? "Conflict")
        case .internalServerError(let error):
            let errorBody = try? error.body.json
            throw NetworkError.serverError(message: errorBody?.message ?? "Internal server error")
        case .undocumented(let statusCode, _):
            throw NetworkError.httpError(statusCode: statusCode, data: nil)
        }
    }
    
    public func checkHandle(handle: String) async throws -> CheckHandleResponse {
        let response = try await client.get_sol_check_hyphen_handle(
            query: .init(handle: handle)
        )
        
        switch response {
        case .ok(let ok):
            let generatedResponse = try ok.body.json
            return generatedResponse.toAppFoundation()
        case .badRequest(let error):
            let errorBody = try? error.body.json
            throw NetworkError.serverError(message: errorBody?.message ?? "Invalid handle format")
        case .internalServerError(let error):
            let errorBody = try? error.body.json
            throw NetworkError.serverError(message: errorBody?.message ?? "Internal server error")
        case .undocumented(let statusCode, _):
            throw NetworkError.httpError(statusCode: statusCode, data: nil)
        }
    }
    
    public func getCurrentUserProfile() async throws -> User {
        let response = try await client.get_sol_get_hyphen_current_hyphen_profile(.init())
        
        switch response {
        case .ok(let ok):
            let generatedUser = try ok.body.json
            return generatedUser.toAppFoundation()
        case .unauthorized:
            throw NetworkError.authenticationRequired
        case .notFound(let error):
            let errorBody = try? error.body.json
            throw NetworkError.notFound(message: errorBody?.message ?? "Profile not found")
        case .internalServerError(let error):
            let errorBody = try? error.body.json
            throw NetworkError.serverError(message: errorBody?.message ?? "Internal server error")
        case .undocumented(let statusCode, _):
            throw NetworkError.httpError(statusCode: statusCode, data: nil)
        }
    }
    
    public func updateProfile(request: UpdateProfileRequest) async throws -> User {
        let componentsRequest = request.toComponentsSchemas()
        let response = try await client.patch_sol_update_hyphen_profile(
            body: .json(componentsRequest)
        )
        
        switch response {
        case .ok(let ok):
            let generatedUser = try ok.body.json
            return generatedUser.toAppFoundation()
        case .badRequest(let error):
            let errorBody = try? error.body.json
            throw NetworkError.serverError(message: errorBody?.message ?? "Bad request")
        case .unauthorized:
            throw NetworkError.authenticationRequired
        case .internalServerError(let error):
            let errorBody = try? error.body.json
            throw NetworkError.serverError(message: errorBody?.message ?? "Internal server error")
        case .undocumented(let statusCode, _):
            throw NetworkError.httpError(statusCode: statusCode, data: nil)
        }
    }
    
    // MARK: - Following Feed
    
    public func fetchFollowingFeed(cursor: String?, limit: Int?) async throws -> FollowingFeedResponse {
        // Temporarily use a manual implementation until OpenAPI client is regenerated
        guard let token = try? await authTokenProvider.currentAccessToken() else {
            throw NetworkError.authenticationRequired
        }
        
        // Build URL with query parameters
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
        
        // Decode response
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(FollowingFeedResponse.self, from: data)
        return decoded
    }
    
    // MARK: - User Profile Operations
    
    public func getUserProfile(userId: String) async throws -> UserProfileWithStats {
        // Temporarily use a manual implementation until OpenAPI client is regenerated
        let url = baseURL.appending(path: "/get-user-profile/\(userId)")
        
        var request = URLRequest(url: url)
        if let token = try? await authTokenProvider.currentAccessToken() {
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
        
        // Decode response
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(UserProfileWithStats.self, from: data)
        return decoded
    }
    
    public func getUserPosts(userId: String, cursor: String?, limit: Int?) async throws -> UserPostsResponse {
        // Temporarily use a manual implementation until OpenAPI client is regenerated
        guard let token = try? await authTokenProvider.currentAccessToken() else {
            throw NetworkError.authenticationRequired
        }
        
        // Build URL with query parameters
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
        
        // Decode response
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(UserPostsResponse.self, from: data)
        return decoded
    }
    
    public func createPost(
        text: String,
        mediaBundleId: String?,
        linkUrl: String?,
        quotePostId: String?,
        replyToPostId: String?,
        selfDestructAt: Date?
    ) async throws -> Post {
        print("[OpenAPIAgoraClient] 📝 Creating post with text: \(text.prefix(50))...")
        
        guard let token = try? await authTokenProvider.currentAccessToken() else {
            print("[OpenAPIAgoraClient] ❌ No auth token available")
            throw NetworkError.authenticationRequired
        }
        
        print("[OpenAPIAgoraClient] ✅ Got auth token")
        
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
        
        print("[OpenAPIAgoraClient] 🌐 Sending POST to: \(request.url?.absoluteString ?? "unknown")")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("[OpenAPIAgoraClient] ❌ Invalid HTTP response")
            throw NetworkError.serverError(message: "Invalid response")
        }
        
        print("[OpenAPIAgoraClient] 📡 Response status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 201 else {
            if httpResponse.statusCode == 401 {
                print("[OpenAPIAgoraClient] ❌ Authentication required")
                throw NetworkError.authenticationRequired
            }
            if let responseString = String(data: data, encoding: .utf8) {
                print("[OpenAPIAgoraClient] ❌ Error response: \(responseString)")
            }
            throw NetworkError.httpError(statusCode: httpResponse.statusCode, data: data)
        }
        
        print("[OpenAPIAgoraClient] ✅ Post created successfully!")
        
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

// MARK: - Auth Middleware (for future use with generated client)

/// Middleware to add Bearer token to requests
private struct AuthMiddleware: ClientMiddleware {
    let tokenProvider: AuthTokenProvider
    
    func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        var modifiedRequest = request
        
        // Get current access token
        if let token = try? await tokenProvider.currentAccessToken() {
            modifiedRequest.headerFields[.authorization] = "Bearer \(token)"
        }
        
        return try await next(modifiedRequest, body, baseURL)
    }
}

