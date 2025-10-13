import Foundation
import OpenAPIRuntime
import OpenAPIURLSession
import HTTPTypes
import AppFoundation

/// Production implementation of AgoraAPIClient using OpenAPI-generated code
public final class OpenAPIAgoraClient: AgoraAPIClient {
    private let client: Client
    private let authTokenProvider: AuthTokenProvider
    
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
            // EnhancedPost uses allOf, so properties are in value1 (the base Post)
            let posts = generatedResponse.posts.map { enhancedPost in
                let post = enhancedPost.value1
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
                    createdAt: post.createdAt
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
    
    public func createProfile(request: Components.Schemas.CreateProfileRequest) async throws -> Components.Schemas.User {
        let response = try await client.post_sol_create_hyphen_profile(
            .init(body: .json(request))
        )
        
        switch response {
        case .created(let created):
            return try created.body.json
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
    
    public func checkHandle(handle: String) async throws -> Components.Schemas.CheckHandleResponse {
        let response = try await client.get_sol_check_hyphen_handle(
            query: .init(handle: handle)
        )
        
        switch response {
        case .ok(let ok):
            return try ok.body.json
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
    
    public func getCurrentUserProfile() async throws -> Components.Schemas.User {
        let response = try await client.get_sol_get_hyphen_current_hyphen_profile(.init())
        
        switch response {
        case .ok(let ok):
            return try ok.body.json
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
    
    public func updateProfile(request: Components.Schemas.UpdateProfileRequest) async throws -> Components.Schemas.User {
        // TODO: Replace with generated API call once available
        // Example (after generation):
        // let response = try await client.patch_slash_users_slash_me(
        //     body: .json(request)
        // )
        // return try response.ok.body.json
        
        print("[OpenAPIAgoraClient] updateProfile not yet wired to generated client")
        throw NetworkError.serverError(message: "Not yet implemented")
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

