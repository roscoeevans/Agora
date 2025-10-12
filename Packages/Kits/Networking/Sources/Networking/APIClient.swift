import Foundation
import OpenAPIRuntime
import OpenAPIURLSession
import AppFoundation

/// Main API client for Agora backend communication
public final class APIClient: Sendable {
    public static let shared = APIClient()
    
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
        
        let urlSession = URLSession(configuration: configuration)
        let transport = URLSessionTransport(configuration: .init(session: urlSession))
        
        // Create OpenAPI client
        // TODO: Add auth and retry interceptors when implemented
        self.client = Client(
            serverURL: baseURL,
            transport: transport
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

// MARK: - Authentication Operations

extension APIClient {
    /// Begin Sign in with Apple flow
    /// - Parameter nonce: Random nonce for security
    /// - Returns: Apple authentication URL
    public func beginSignInWithApple(nonce: String) async throws -> Components.Schemas.SWABeginResponse {
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
    
    /// Complete Sign in with Apple flow
    /// - Parameters:
    ///   - identityToken: Apple identity token
    ///   - authorizationCode: Apple authorization code
    /// - Returns: Authentication response with tokens and user info
    public func finishSignInWithApple(
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