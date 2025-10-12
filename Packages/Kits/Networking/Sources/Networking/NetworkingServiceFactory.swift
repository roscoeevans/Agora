import Foundation
import AppFoundation

// MARK: - Conformance to AppFoundation protocol

// MARK: - Networking Service Factory

/// Factory for creating API clients based on environment configuration
public struct NetworkingServiceFactory {
    // Auto-register on first access to this type
    private static let autoRegister: Void = {
        DefaultServiceFactory.apiClientProvider = {
            return NetworkingServiceFactory.makeAPIClient(useStub: false)
        }
        print("[NetworkingServiceFactory] Auto-registered API client provider")
    }()
    
    /// Create an API client appropriate for the current environment
    /// - Parameters:
    ///   - useStub: Force use of stub client (useful for development/testing)
    ///   - authToken: Optional authentication token
    /// - Returns: Configured API client
    public static func makeAPIClient(
        useStub: Bool = false,
        authToken: String? = nil
    ) -> any AgoraAPIClient {
        // Ensure auto-registration happened
        _ = autoRegister
        
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
        return OpenAPIAgoraClient(
            baseURL: AppConfig.apiBaseURL,
            session: .shared,
            authToken: authToken
        )
    }
    
    /// Create an API client with automatic auth token injection
    /// - Parameters:
    ///   - useStub: Force use of stub client
    ///   - authTokenProvider: Provider for fetching current auth token
    /// - Returns: Configured API client with auth
    public static func makeAuthenticatedAPIClient(
        useStub: Bool = false,
        authTokenProvider: AuthTokenProvider
    ) async -> any AgoraAPIClient {
        let token = try? await authTokenProvider.currentAccessToken()
        return makeAPIClient(useStub: useStub, authToken: token)
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

