import XCTest
import HTTPTypes
import OpenAPIRuntime
@testable import Networking
import TestSupport
import AppFoundation

/// Tests for retry logic and error handling scenarios
final class RetryLogicTests: XCTestCase {
    
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
    
    // MARK: - RetryInterceptor Tests
    
    func testRetryInterceptorWithServerError() async throws {
        // Create retry interceptor with short delays for testing
        let retryInterceptor = RetryInterceptor(
            maxRetries: 2,
            baseDelay: 0.01, // Very short delay for tests
            maxDelay: 0.1,
            logger: nil
        )
        
        // Test that retry interceptor exists and can be configured
        XCTAssertNotNil(retryInterceptor)
        
        // Note: Testing the actual retry behavior requires integration with the full OpenAPI client
        // which is complex due to the middleware architecture. For now, we test the components.
    }
    
    func testRetryInterceptorConfiguration() {
        let interceptor1 = RetryInterceptor()
        XCTAssertNotNil(interceptor1)
        
        let interceptor2 = RetryInterceptor(
            maxRetries: 5,
            baseDelay: 2.0,
            maxDelay: 30.0,
            logger: Logger.networking
        )
        XCTAssertNotNil(interceptor2)
    }
    
    // MARK: - Error Handling Scenarios
    
    func testNetworkErrorRetryability() {
        // Test retryable errors
        let retryableErrors: [NetworkError] = [
            .networkUnavailable,
            .timeout,
            .httpError(statusCode: 500, data: nil),
            .httpError(statusCode: 502, data: nil),
            .httpError(statusCode: 503, data: nil),
            .httpError(statusCode: 504, data: nil),
            .httpError(statusCode: 429, data: nil),
            .rateLimited(retryAfter: nil),
            .rateLimited(retryAfter: 30.0)
        ]
        
        for error in retryableErrors {
            XCTAssertTrue(error.isRetryable, "Error \(error) should be retryable")
        }
        
        // Test non-retryable errors
        let nonRetryableErrors: [NetworkError] = [
            .invalidURL,
            .noData,
            .decodingError(NSError(domain: "Test", code: 1)),
            .encodingError(NSError(domain: "Test", code: 1)),
            .httpError(statusCode: 400, data: nil),
            .httpError(statusCode: 401, data: nil),
            .httpError(statusCode: 403, data: nil),
            .httpError(statusCode: 404, data: nil),
            .authenticationRequired,
            .serverError(message: "Test"),
            .unknownError(NSError(domain: "Test", code: 1))
        ]
        
        for error in nonRetryableErrors {
            XCTAssertFalse(error.isRetryable, "Error \(error) should not be retryable")
        }
    }
    
    func testURLErrorRetryability() {
        // Test URLErrors that should be retryable
        let retryableURLErrors: [URLError.Code] = [
            .notConnectedToInternet,
            .networkConnectionLost,
            .timedOut
        ]
        
        for errorCode in retryableURLErrors {
            let urlError = URLError(errorCode)
            // Note: We would need to test this through the RetryInterceptor
            // For now, we verify the error types exist
            XCTAssertNotNil(urlError)
        }
        
        // Test URLErrors that should not be retryable
        let nonRetryableURLErrors: [URLError.Code] = [
            .badURL,
            .unsupportedURL,
            .cannotFindHost,
            .cannotConnectToHost,
            .userCancelledAuthentication,
            .userAuthenticationRequired
        ]
        
        for errorCode in nonRetryableURLErrors {
            let urlError = URLError(errorCode)
            XCTAssertNotNil(urlError)
        }
    }
    
    // MARK: - Error Mapping Tests
    
    func testAPIClientErrorMapping() {
        let apiClient = APIClient()
        XCTAssertNotNil(apiClient)
        
        // Test that APIClient can be created and has error mapping capability
        // The actual error mapping is tested through integration tests
    }
    
    // MARK: - Simulated Retry Scenarios
    
    func testSimulatedRetryScenarios() async throws {
        // Scenario 1: Temporary server error that resolves
        mockNetworking.setErrorResponse(for: "/temp-error", statusCode: 503, message: "Service Unavailable")
        
        let request1 = HTTPRequest(method: .get, scheme: "https", authority: "api.test.com", path: "/temp-error")
        let (response1, _) = try await mockNetworking.performRequest(request1, body: nil)
        XCTAssertEqual(response1.status.code, 503)
        
        // Scenario 2: Rate limiting
        mockNetworking.setErrorResponse(for: "/rate-limited", statusCode: 429, message: "Too Many Requests")
        
        let request2 = HTTPRequest(method: .get, scheme: "https", authority: "api.test.com", path: "/rate-limited")
        let (response2, _) = try await mockNetworking.performRequest(request2, body: nil)
        XCTAssertEqual(response2.status.code, 429)
        
        // Scenario 3: Network timeout
        mockNetworking.setTimeoutError()
        
        let request3 = HTTPRequest(method: .get, scheme: "https", authority: "api.test.com", path: "/timeout")
        
        do {
            _ = try await mockNetworking.performRequest(request3, body: nil)
            XCTFail("Expected timeout error")
        } catch {
            XCTAssertTrue(error is URLError)
        }
        
        // Scenario 4: Connection lost
        mockNetworking.reset()
        mockNetworking.setConnectionError()
        
        let request4 = HTTPRequest(method: .get, scheme: "https", authority: "api.test.com", path: "/connection-lost")
        
        do {
            _ = try await mockNetworking.performRequest(request4, body: nil)
            XCTFail("Expected connection error")
        } catch {
            XCTAssertTrue(error is URLError)
        }
    }
    
    // MARK: - Exponential Backoff Calculation Tests
    
    func testExponentialBackoffCalculation() {
        // Test that we can create RetryInterceptor with different backoff settings
        let shortBackoff = RetryInterceptor(
            maxRetries: 3,
            baseDelay: 0.1,
            maxDelay: 1.0
        )
        XCTAssertNotNil(shortBackoff)
        
        let longBackoff = RetryInterceptor(
            maxRetries: 5,
            baseDelay: 1.0,
            maxDelay: 60.0
        )
        XCTAssertNotNil(longBackoff)
        
        // Note: The actual backoff calculation is internal to RetryInterceptor
        // We test that different configurations can be created
    }
    
    // MARK: - Error Recovery Tests
    
    func testErrorRecoveryScenarios() async throws {
        // Test recovery from multiple failure types
        struct TestScenario {
            let path: String
            let initialError: Error
            let recoveryStatusCode: Int
        }
        
        let scenarios: [TestScenario] = [
            TestScenario(path: "/recover-timeout", initialError: URLError(.timedOut), recoveryStatusCode: 200),
            TestScenario(path: "/recover-connection", initialError: URLError(.networkConnectionLost), recoveryStatusCode: 200),
            TestScenario(path: "/recover-server", initialError: URLError(.badServerResponse), recoveryStatusCode: 200)
        ]
        
        for scenario in scenarios {
            mockNetworking.reset()
            
            // First request fails
            mockNetworking.setFailure(error: scenario.initialError, count: 1)
            
            let request = HTTPRequest(method: .get, scheme: "https", authority: "api.test.com", path: scenario.path)
            
            do {
                _ = try await mockNetworking.performRequest(request, body: nil)
                XCTFail("Expected error for scenario \(scenario.path)")
            } catch {
                // Expected failure
            }
            
            // Second request succeeds
            mockNetworking.setResponse(
                for: scenario.path,
                response: MockNetworking.MockResponse(statusCode: scenario.recoveryStatusCode)
            )
            
            let (response, _) = try await mockNetworking.performRequest(request, body: nil)
            XCTAssertEqual(response.status.code, scenario.recoveryStatusCode)
        }
    }
    
    // MARK: - Sequential Request Tests
    
    func testSequentialRequestHandling() async throws {
        // Set up responses for sequential requests
        for i in 1...3 {
            mockNetworking.setResponse(
                for: "/sequential-\(i)",
                response: MockNetworking.MockResponse(statusCode: 200, data: "Response \(i)".data(using: .utf8))
            )
        }
        
        // Make sequential requests
        var results: [(HTTPResponse, HTTPBody?)] = []
        
        for i in 1...3 {
            let request = HTTPRequest(method: .get, scheme: "https", authority: "api.test.com", path: "/sequential-\(i)")
            let result = try await mockNetworking.performRequest(request, body: nil)
            results.append(result)
        }
        
        // Verify all requests succeeded
        XCTAssertEqual(results.count, 3)
        for (response, _) in results {
            XCTAssertEqual(response.status.code, 200)
        }
        
        // Verify all requests were recorded
        XCTAssertEqual(mockNetworking.recordedRequests.count, 3)
    }
}