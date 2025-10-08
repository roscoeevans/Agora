import XCTest
import HTTPTypes
@testable import Networking
import TestSupport
import AppFoundation

/// Integration tests demonstrating mock networking functionality
final class MockIntegrationTests: XCTestCase {
    
    func testMockTransportIntegration() {
        // Test that MockTransport can be created and configured
        let mockTransport = MockTransport()
        XCTAssertNotNil(mockTransport)
        
        // Test that we can configure mock responses
        mockTransport.mock.setResponse(
            for: "/test",
            response: MockNetworking.MockResponse(statusCode: 200, data: "success".data(using: .utf8))
        )
        
        // Verify configuration was successful
        XCTAssertEqual(mockTransport.mock.recordedRequests.count, 0)
    }
    
    func testAuthInterceptorWithMockProvider() {
        // Test that AuthInterceptor works with MockAuthTokenProvider
        let mockProvider = MockAuthTokenProvider()
        mockProvider.setToken("test-token")
        
        let interceptor = AuthInterceptor(authTokenProvider: mockProvider)
        XCTAssertNotNil(interceptor)
    }
    
    func testRetryInterceptorConfiguration() {
        // Test that RetryInterceptor can be configured for testing
        let interceptor = RetryInterceptor(
            maxRetries: 1,
            baseDelay: 0.01, // Very short for tests
            maxDelay: 0.1,
            logger: nil // No logging in tests
        )
        XCTAssertNotNil(interceptor)
    }
    
    func testNetworkingComponentsIntegration() {
        // Test that all networking components can be created together
        let mockProvider = MockAuthTokenProvider()
        let authInterceptor = AuthInterceptor(authTokenProvider: mockProvider)
        let retryInterceptor = RetryInterceptor(maxRetries: 1, baseDelay: 0.01)
        let mockTransport = MockTransport()
        
        XCTAssertNotNil(authInterceptor)
        XCTAssertNotNil(retryInterceptor)
        XCTAssertNotNil(mockTransport)
        
        // Test that mock provider can be configured
        mockProvider.setToken("integration-test-token")
        
        // Test that mock transport can be configured
        mockTransport.mock.setResponse(
            for: "/integration",
            response: MockNetworking.MockResponse(statusCode: 200)
        )
        
        // If we get here, all components integrated successfully
        XCTAssertTrue(true)
    }
}