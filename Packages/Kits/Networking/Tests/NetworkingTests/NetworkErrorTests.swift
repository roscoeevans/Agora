import XCTest
@testable import Networking

final class NetworkErrorTests: XCTestCase {
    
    // MARK: - Error Description Tests
    
    func testInvalidURLErrorDescription() {
        let error = NetworkError.invalidURL
        XCTAssertEqual(error.errorDescription, "Invalid URL")
    }
    
    func testNoDataErrorDescription() {
        let error = NetworkError.noData
        XCTAssertEqual(error.errorDescription, "No data received")
    }
    
    func testDecodingErrorDescription() {
        let underlyingError = NSError(domain: "TestDomain", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test decoding error"])
        let error = NetworkError.decodingError(underlyingError)
        XCTAssertEqual(error.errorDescription, "Failed to decode response: Test decoding error")
    }
    
    func testEncodingErrorDescription() {
        let underlyingError = NSError(domain: "TestDomain", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test encoding error"])
        let error = NetworkError.encodingError(underlyingError)
        XCTAssertEqual(error.errorDescription, "Failed to encode request: Test encoding error")
    }
    
    func testHTTPErrorDescription() {
        let error = NetworkError.httpError(statusCode: 404, data: nil)
        XCTAssertEqual(error.errorDescription, "HTTP error with status code: 404")
    }
    
    func testAuthenticationRequiredErrorDescription() {
        let error = NetworkError.authenticationRequired
        XCTAssertEqual(error.errorDescription, "Authentication required")
    }
    
    func testNetworkUnavailableErrorDescription() {
        let error = NetworkError.networkUnavailable
        XCTAssertEqual(error.errorDescription, "Network unavailable")
    }
    
    func testTimeoutErrorDescription() {
        let error = NetworkError.timeout
        XCTAssertEqual(error.errorDescription, "Request timed out")
    }
    
    func testRateLimitedErrorDescriptionWithRetryAfter() {
        let error = NetworkError.rateLimited(retryAfter: 30.0)
        XCTAssertEqual(error.errorDescription, "Rate limited. Retry after 30.0 seconds")
    }
    
    func testRateLimitedErrorDescriptionWithoutRetryAfter() {
        let error = NetworkError.rateLimited(retryAfter: nil)
        XCTAssertEqual(error.errorDescription, "Rate limited")
    }
    
    func testServerErrorDescription() {
        let error = NetworkError.serverError(message: "Internal server error")
        XCTAssertEqual(error.errorDescription, "Server error: Internal server error")
    }
    
    func testUnknownErrorDescription() {
        let underlyingError = NSError(domain: "TestDomain", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test unknown error"])
        let error = NetworkError.unknownError(underlyingError)
        XCTAssertEqual(error.errorDescription, "Unknown error: Test unknown error")
    }
    
    // MARK: - Retryable Tests
    
    func testRetryableErrors() {
        let retryableErrors: [NetworkError] = [
            .networkUnavailable,
            .timeout,
            .httpError(statusCode: 500, data: nil),
            .httpError(statusCode: 502, data: nil),
            .httpError(statusCode: 503, data: nil),
            .httpError(statusCode: 429, data: nil),
            .rateLimited(retryAfter: nil),
            .rateLimited(retryAfter: 30.0)
        ]
        
        for error in retryableErrors {
            XCTAssertTrue(error.isRetryable, "Error \(error) should be retryable")
        }
    }
    
    func testNonRetryableErrors() {
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
    
    // MARK: - Equality Tests
    
    func testNetworkErrorEquality() {
        // Test cases where errors should be equal
        XCTAssertEqual(NetworkError.invalidURL, NetworkError.invalidURL)
        XCTAssertEqual(NetworkError.noData, NetworkError.noData)
        XCTAssertEqual(NetworkError.authenticationRequired, NetworkError.authenticationRequired)
        XCTAssertEqual(NetworkError.networkUnavailable, NetworkError.networkUnavailable)
        XCTAssertEqual(NetworkError.timeout, NetworkError.timeout)
        
        // Test HTTP errors with same status code
        XCTAssertEqual(
            NetworkError.httpError(statusCode: 404, data: nil),
            NetworkError.httpError(statusCode: 404, data: nil)
        )
        
        // Test rate limited errors
        XCTAssertEqual(
            NetworkError.rateLimited(retryAfter: 30.0),
            NetworkError.rateLimited(retryAfter: 30.0)
        )
        
        // Test server errors with same message
        XCTAssertEqual(
            NetworkError.serverError(message: "Test"),
            NetworkError.serverError(message: "Test")
        )
    }
    
    func testNetworkErrorInequality() {
        // Test different error types
        XCTAssertNotEqual(NetworkError.invalidURL, NetworkError.noData)
        
        // Test HTTP errors with different status codes
        XCTAssertNotEqual(
            NetworkError.httpError(statusCode: 404, data: nil),
            NetworkError.httpError(statusCode: 500, data: nil)
        )
        
        // Test rate limited errors with different retry times
        XCTAssertNotEqual(
            NetworkError.rateLimited(retryAfter: 30.0),
            NetworkError.rateLimited(retryAfter: 60.0)
        )
        
        // Test server errors with different messages
        XCTAssertNotEqual(
            NetworkError.serverError(message: "Error 1"),
            NetworkError.serverError(message: "Error 2")
        )
    }
}

// MARK: - NetworkError Equatable Extension for Testing

extension NetworkError: Equatable {
    public static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL),
             (.noData, .noData),
             (.authenticationRequired, .authenticationRequired),
             (.networkUnavailable, .networkUnavailable),
             (.timeout, .timeout):
            return true
            
        case (.decodingError(let lhsError), .decodingError(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
            
        case (.encodingError(let lhsError), .encodingError(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
            
        case (.httpError(let lhsCode, let lhsData), .httpError(let rhsCode, let rhsData)):
            return lhsCode == rhsCode && lhsData == rhsData
            
        case (.rateLimited(let lhsRetry), .rateLimited(let rhsRetry)):
            return lhsRetry == rhsRetry
            
        case (.serverError(let lhsMessage), .serverError(let rhsMessage)):
            return lhsMessage == rhsMessage
            
        case (.unknownError(let lhsError), .unknownError(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
            
        default:
            return false
        }
    }
}