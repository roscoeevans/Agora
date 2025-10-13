import Foundation
import AppFoundation

// MARK: - Conformance to AppFoundation protocol

// MARK: - Networking Service Factory

/// Factory for creating API clients based on environment configuration
public struct NetworkingServiceFactory {
    
    /// Register the API client provider with ServiceFactory
    /// Call this once at app startup
    public static func register() {
        DefaultServiceFactory.apiClientProvider = {
            return NetworkingServiceFactory.makeAPIClient(useStub: false)
        }
        print("[NetworkingServiceFactory] Registered API client provider")
    }
    
    /// Create an API client appropriate for the current environment
    /// - Parameters:
    ///   - useStub: Force use of stub client (useful for development/testing)
    ///   - authTokenProvider: Auth token provider (optional, can be injected later)
    /// - Returns: Configured API client
    public static func makeAPIClient(
        useStub: Bool = false,
        authTokenProvider: AuthTokenProvider? = nil
    ) -> any AgoraAPIClient {
        #if DEBUG
        // In debug builds, allow forcing stub client via parameter
        if useStub {
            print("[NetworkingServiceFactory] Creating stub API client")
            return StubAgoraClient()
        }
        #endif
        
        // Create production OpenAPI-based client
        print("[NetworkingServiceFactory] Creating OpenAPI-based API client")
        print("[NetworkingServiceFactory]   Base URL: \(AppConfig.apiBaseURL)")
        
        // Get auth token provider - only when not provided
        // This breaks the circular dependency by making it lazy
        let provider = authTokenProvider ?? ServiceProvider.shared.authTokenProvider()
        
        return OpenAPIAgoraClient(
            baseURL: AppConfig.apiBaseURL,
            session: .shared,
            authTokenProvider: provider
        )
    }
    
    /// Create an API client with explicit auth token provider
    /// - Parameters:
    ///   - useStub: Force use of stub client
    ///   - authTokenProvider: Provider for fetching current auth token
    /// - Returns: Configured API client with auth
    public static func makeAuthenticatedAPIClient(
        useStub: Bool = false,
        authTokenProvider: AuthTokenProvider
    ) -> any AgoraAPIClient {
        return makeAPIClient(useStub: useStub, authTokenProvider: authTokenProvider)
    }
}

// MARK: - Default ServiceFactory Extension

/// Extend DefaultServiceFactory to provide API client creation
extension DefaultServiceFactory {
    public static func apiClient() throws -> any AgoraAPIClientProtocol {
        return NetworkingServiceFactory.makeAPIClient(
            useStub: false
        )
    }
}

