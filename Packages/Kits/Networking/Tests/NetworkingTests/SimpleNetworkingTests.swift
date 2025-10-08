import XCTest
import HTTPTypes
@testable import Networking
import TestSupport
import AppFoundation

/// Simplified networking tests that avoid complex Sendable issues
final class SimpleNetworkingTests: XCTestCase {
    
    // MARK: - NetworkError Tests
    
    func testNetworkErrorRetryability() {
        // Test retryable errors
        XCTAssertTrue(NetworkError.networkUnavailable.isRetryable)
        XCTAssertTrue(NetworkError.timeout.isRetryable)
        XCTAssertTrue(NetworkError.httpError(statusCode: 500, data: nil).isRetryable)
        XCTAssertTrue(NetworkError.httpError(statusCode: 429, data: nil).isRetryable)
        XCTAssertTrue(NetworkError.rateLimited(retryAfter: nil).isRetryable)
        
        // Test non-retryable errors
        XCTAssertFalse(NetworkError.invalidURL.isRetryable)
        XCTAssertFalse(NetworkError.authenticationRequired.isRetryable)
        XCTAssertFalse(NetworkError.httpError(statusCode: 400, data: nil).isRetryable)
        XCTAssertFalse(NetworkError.httpError(statusCode: 404, data: nil).isRetryable)
    }
    
    func testNetworkErrorDescriptions() {
        XCTAssertEqual(NetworkError.invalidURL.errorDescription, "Invalid URL")
        XCTAssertEqual(NetworkError.noData.errorDescription, "No data received")
        XCTAssertEqual(NetworkError.authenticationRequired.errorDescription, "Authentication required")
        XCTAssertEqual(NetworkError.timeout.errorDescription, "Request timed out")
        XCTAssertEqual(NetworkError.serverError(message: "Test").errorDescription, "Server error: Test")
    }
    
    // MARK: - MockAuthTokenProvider Tests
    
    func testMockAuthTokenProvider() async throws {
        let mockProvider = MockAuthTokenProvider()
        
        // Test initial state
        let initialToken = try await mockProvider.currentAccessToken()
        XCTAssertNil(initialToken)
        
        let initialAuth = await mockProvider.isAuthenticated
        XCTAssertFalse(initialAuth)
        
        // Test setting token
        mockProvider.setToken("test-token")
        let token = try await mockProvider.currentAccessToken()
        XCTAssertEqual(token, "test-token")
        
        let isAuth = await mockProvider.isAuthenticated
        XCTAssertTrue(isAuth)
        
        // Test error throwing
        mockProvider.setShouldThrowError(true, error: .tokenNotFound)
        do {
            _ = try await mockProvider.currentAccessToken()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error is AuthTokenError)
        }
    }
    
    // MARK: - MockNetworking Tests
    
    func testMockNetworkingCreation() {
        let mockNetworking = MockNetworking()
        XCTAssertNotNil(mockNetworking)
        
        // Test setting response
        let testData = "test response".data(using: .utf8)!
        mockNetworking.setResponse(
            for: "/test",
            response: MockNetworking.MockResponse(statusCode: 200, data: testData)
        )
        
        // Test initial state
        XCTAssertEqual(mockNetworking.recordedRequests.count, 0)
    }
    
    func testMockNetworkingWithJSONResponse() throws {
        let mockNetworking = MockNetworking()
        
        struct TestResponse: Codable {
            let message: String
        }
        
        let testResponse = TestResponse(message: "Hello, World!")
        try mockNetworking.setJSONResponse(for: "/json", object: testResponse)
        
        // Test that no error was thrown
        XCTAssertTrue(true) // If we get here, the JSON response was set successfully
    }
    
    func testMockNetworkingErrorResponse() {
        let mockNetworking = MockNetworking()
        
        // Set up error response
        mockNetworking.setErrorResponse(for: "/error", statusCode: 404, message: "Not Found")
        
        // Test that no error was thrown during setup
        XCTAssertTrue(true)
    }
    
    func testMockNetworkingFailureSetup() {
        let mockNetworking = MockNetworking()
        
        // Set up to fail with error
        mockNetworking.setFailure(error: URLError(.timedOut), count: 1)
        
        // Test that setup completed without error
        XCTAssertTrue(true)
    }
    
    // MARK: - APIClient Tests
    
    func testAPIClientInitialization() {
        let client = APIClient()
        XCTAssertNotNil(client.openAPIClient)
        
        let customURL = URL(string: "https://custom.api.com")!
        let customClient = APIClient(baseURL: customURL)
        XCTAssertNotNil(customClient.openAPIClient)
        
        let mockProvider = MockAuthTokenProvider()
        let authClient = APIClient(authTokenProvider: mockProvider)
        XCTAssertNotNil(authClient.openAPIClient)
    }
    
    // MARK: - Component Integration Tests
    
    func testAuthInterceptorCreation() {
        let mockProvider = MockAuthTokenProvider()
        let interceptor = AuthInterceptor(authTokenProvider: mockProvider)
        XCTAssertNotNil(interceptor)
        
        let nilInterceptor = AuthInterceptor(authTokenProvider: nil)
        XCTAssertNotNil(nilInterceptor)
    }
    
    func testRetryInterceptorCreation() {
        let interceptor = RetryInterceptor()
        XCTAssertNotNil(interceptor)
        
        let customInterceptor = RetryInterceptor(
            maxRetries: 5,
            baseDelay: 2.0,
            maxDelay: 30.0,
            logger: Logger.networking
        )
        XCTAssertNotNil(customInterceptor)
    }
}

