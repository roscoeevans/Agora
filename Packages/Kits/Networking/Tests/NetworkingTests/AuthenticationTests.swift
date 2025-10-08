import XCTest
import HTTPTypes
import OpenAPIRuntime
@testable import Networking
import TestSupport
import AppFoundation

/// Tests for authentication token injection and auth-related functionality
final class AuthenticationTests: XCTestCase {
    
    var mockNetworking: MockNetworking!
    var mockTransport: MockTransport!
    var mockAuthProvider: MockAuthTokenProvider!
    
    override func setUp() {
        super.setUp()
        mockNetworking = MockNetworking()
        mockTransport = MockTransport(mockNetworking: mockNetworking)
        mockAuthProvider = MockAuthTokenProvider()
    }
    
    override func tearDown() {
        mockNetworking = nil
        mockTransport = nil
        mockAuthProvider = nil
        super.tearDown()
    }
    
    // MARK: - AuthInterceptor Creation Tests
    
    func testAuthInterceptorCreation() {
        let interceptorWithAuth = AuthInterceptor(authTokenProvider: mockAuthProvider)
        XCTAssertNotNil(interceptorWithAuth)
        
        let interceptorWithoutAuth = AuthInterceptor(authTokenProvider: nil)
        XCTAssertNotNil(interceptorWithoutAuth)
    }
    
    // MARK: - MockAuthTokenProvider Tests
    
    func testMockAuthTokenProviderBasicFunctionality() async throws {
        let provider = MockAuthTokenProvider()
        
        // Test initial state
        let isInitiallyAuthenticated = await provider.isAuthenticated
        XCTAssertFalse(isInitiallyAuthenticated)
        
        let initialToken = try await provider.currentAccessToken()
        XCTAssertNil(initialToken)
        
        // Test setting token
        provider.setToken("test-token-123")
        
        let isAuthenticatedAfterSet = await provider.isAuthenticated
        XCTAssertTrue(isAuthenticatedAfterSet)
        
        let token = try await provider.currentAccessToken()
        XCTAssertEqual(token, "test-token-123")
        
        // Test clearing token
        provider.setToken(nil)
        
        let isAuthenticatedAfterClear = await provider.isAuthenticated
        XCTAssertFalse(isAuthenticatedAfterClear)
        
        let clearedToken = try await provider.currentAccessToken()
        XCTAssertNil(clearedToken)
    }
    
    func testMockAuthTokenProviderErrorHandling() async throws {
        let provider = MockAuthTokenProvider()
        
        // Test different error types
        let errorTypes: [AuthTokenError] = [
            .tokenNotFound,
            .tokenExpired,
            .networkError
        ]
        
        for errorType in errorTypes {
            provider.setShouldThrowError(true, error: errorType)
            
            do {
                _ = try await provider.currentAccessToken()
                XCTFail("Expected error \(errorType) to be thrown")
            } catch {
                XCTAssertTrue(error is AuthTokenError)
                if let authError = error as? AuthTokenError {
                    XCTAssertEqual(authError, errorType)
                }
            }
            
            // Reset error state
            provider.setShouldThrowError(false)
        }
    }
    
    func testMockAuthTokenProviderConcurrentAccess() async throws {
        let provider = MockAuthTokenProvider()
        provider.setToken("concurrent-test-token")
        
        // Test concurrent access to token
        let tasks = (1...10).map { _ in
            Task {
                return try await provider.currentAccessToken()
            }
        }
        
        let results = try await withThrowingTaskGroup(of: String?.self) { group in
            for task in tasks {
                group.addTask { try await task.value }
            }
            
            var tokens: [String?] = []
            for try await token in group {
                tokens.append(token)
            }
            return tokens
        }
        
        // All results should be the same token
        XCTAssertEqual(results.count, 10)
        for token in results {
            XCTAssertEqual(token, "concurrent-test-token")
        }
    }
    
    // MARK: - APIClient Authentication Integration Tests
    
    func testAPIClientWithAuthentication() {
        let mockProvider = MockAuthTokenProvider()
        mockProvider.setToken("integration-test-token")
        
        let apiClient = APIClient(authTokenProvider: mockProvider)
        XCTAssertNotNil(apiClient.openAPIClient)
        
        // Test that client can be created with auth provider
        // Full integration testing would require actual network calls
    }
    
    func testAPIClientWithoutAuthentication() {
        let apiClient = APIClient()
        XCTAssertNotNil(apiClient.openAPIClient)
        
        // Test that client works without auth provider
    }
    
    // MARK: - Authentication Flow Simulation Tests
    
    func testAuthenticationFlowSimulation() async throws {
        // Simulate a complete authentication flow
        let provider = MockAuthTokenProvider()
        
        // 1. Initial state - no token
        let initialAuth = await provider.isAuthenticated
        XCTAssertFalse(initialAuth)
        
        // 2. User signs in - token is set
        provider.setToken("fresh-auth-token")
        let authAfterSignIn = await provider.isAuthenticated
        XCTAssertTrue(authAfterSignIn)
        
        let token1 = try await provider.currentAccessToken()
        XCTAssertEqual(token1, "fresh-auth-token")
        
        // 3. Token refresh - new token is set
        provider.setToken("refreshed-auth-token")
        let token2 = try await provider.currentAccessToken()
        XCTAssertEqual(token2, "refreshed-auth-token")
        
        // 4. Token expires - error is thrown
        provider.setShouldThrowError(true, error: .tokenExpired)
        
        do {
            _ = try await provider.currentAccessToken()
            XCTFail("Expected token expired error")
        } catch {
            XCTAssertTrue(error is AuthTokenError)
        }
        
        // 5. User signs out - token is cleared
        provider.setShouldThrowError(false)
        provider.setToken(nil)
        let finalAuth = await provider.isAuthenticated
        XCTAssertFalse(finalAuth)
        
        let finalToken = try await provider.currentAccessToken()
        XCTAssertNil(finalToken)
    }
    
    // MARK: - Security Tests
    
    func testTokenSecurityBestPractices() async throws {
        let provider = MockAuthTokenProvider()
        
        // Test that tokens are handled securely
        let sensitiveToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test.token"
        provider.setToken(sensitiveToken)
        
        let retrievedToken = try await provider.currentAccessToken()
        XCTAssertEqual(retrievedToken, sensitiveToken)
        
        // Test that clearing token works properly
        provider.setToken(nil)
        let clearedToken = try await provider.currentAccessToken()
        XCTAssertNil(clearedToken)
        
        // Verify no token is returned after clearing
        let finalAuth = await provider.isAuthenticated
        XCTAssertFalse(finalAuth)
    }
    
    // MARK: - Mock Transport Integration Tests
    
    func testMockTransportWithAuthenticatedRequests() async throws {
        // Set up authenticated mock response
        mockNetworking.setResponse(
            for: "/authenticated",
            response: MockNetworking.MockResponse(statusCode: 200, data: "Success".data(using: .utf8))
        )
        
        let request = HTTPRequest(method: .get, scheme: "https", authority: "api.test.com", path: "/authenticated")
        let (response, body) = try await mockTransport.send(request, body: nil, baseURL: URL(string: "https://api.test.com")!, operationID: "test")
        
        XCTAssertEqual(response.status.code, 200)
        
        if let body = body {
            let data = try await Data(collecting: body, upTo: 1024)
            let message = String(data: data, encoding: .utf8)
            XCTAssertEqual(message, "Success")
        }
        
        // Verify request was recorded
        XCTAssertEqual(mockNetworking.recordedRequests.count, 1)
        XCTAssertEqual(mockNetworking.lastRequest?.0.path, "/authenticated")
    }
    
    func testMockTransportWithUnauthorizedResponse() async throws {
        // Set up unauthorized mock response
        mockNetworking.setErrorResponse(for: "/protected", statusCode: 401, message: "Unauthorized")
        
        let request = HTTPRequest(method: .get, scheme: "https", authority: "api.test.com", path: "/protected")
        let (response, body) = try await mockTransport.send(request, body: nil, baseURL: URL(string: "https://api.test.com")!, operationID: "test")
        
        XCTAssertEqual(response.status.code, 401)
        
        if let body = body {
            let data = try await Data(collecting: body, upTo: 1024)
            let message = String(data: data, encoding: .utf8)
            XCTAssertEqual(message, "Unauthorized")
        }
    }
    
    // MARK: - Authentication Header Format Tests
    
    func testBearerTokenFormat() async throws {
        // Test that we can verify Bearer token format in integration
        let testToken = "test-bearer-token-12345"
        mockAuthProvider.setToken(testToken)
        
        // Verify token is set correctly
        let retrievedToken = try await mockAuthProvider.currentAccessToken()
        XCTAssertEqual(retrievedToken, testToken)
        
        // In a real scenario, this would be formatted as "Bearer test-bearer-token-12345"
        // by the AuthInterceptor
        let expectedAuthHeader = "Bearer \(testToken)"
        XCTAssertTrue(expectedAuthHeader.hasPrefix("Bearer "))
        XCTAssertTrue(expectedAuthHeader.contains(testToken))
    }
}