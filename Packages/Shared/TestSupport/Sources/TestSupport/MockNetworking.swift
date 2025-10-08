import Foundation
import OpenAPIRuntime
import HTTPTypes

/// Mock networking implementation for testing
public final class MockNetworking: @unchecked Sendable {
    
    // MARK: - Mock Configuration
    
    public struct MockResponse: Sendable {
        public let statusCode: Int
        public let data: Data?
        public let headers: [String: String]
        public let delay: TimeInterval
        
        public init(
            statusCode: Int = 200,
            data: Data? = nil,
            headers: [String: String] = [:],
            delay: TimeInterval = 0
        ) {
            self.statusCode = statusCode
            self.data = data
            self.headers = headers
            self.delay = delay
        }
    }
    
    private var responses: [String: MockResponse] = [:]
    private var requestLog: [(HTTPRequest, HTTPBody?)] = []
    private var shouldFailWithError: Error?
    private var failureCount: Int = 0
    private var currentFailureCount: Int = 0
    
    public init() {}
    
    // MARK: - Configuration Methods
    
    /// Set a mock response for a specific path
    public func setResponse(for path: String, response: MockResponse) {
        responses[path] = response
    }
    
    /// Set a mock response with JSON data
    public func setJSONResponse<T: Codable>(for path: String, object: T, statusCode: Int = 200) throws {
        let data = try JSONEncoder().encode(object)
        setResponse(for: path, response: MockResponse(statusCode: statusCode, data: data))
    }
    
    /// Configure the mock to fail with an error for the next N requests
    public func setFailure(error: Error, count: Int = 1) {
        shouldFailWithError = error
        failureCount = count
        currentFailureCount = 0
    }
    
    /// Clear all mock responses and request logs
    public func reset() {
        responses.removeAll()
        requestLog.removeAll()
        shouldFailWithError = nil
        failureCount = 0
        currentFailureCount = 0
    }
    
    // MARK: - Request Inspection
    
    /// Get all recorded requests
    public var recordedRequests: [(HTTPRequest, HTTPBody?)] {
        return requestLog
    }
    
    /// Get the last recorded request
    public var lastRequest: (HTTPRequest, HTTPBody?)? {
        return requestLog.last
    }
    
    /// Check if a request was made to a specific path
    public func wasRequestMade(to path: String) -> Bool {
        return requestLog.contains { request, _ in
            request.path == path
        }
    }
    
    /// Get requests made to a specific path
    public func requests(to path: String) -> [(HTTPRequest, HTTPBody?)] {
        return requestLog.filter { request, _ in
            request.path == path
        }
    }
    
    // MARK: - Mock Transport Implementation
    
    /// Simulate a network request
    public func performRequest(
        _ request: HTTPRequest,
        body: HTTPBody?
    ) async throws -> (HTTPResponse, HTTPBody?) {
        // Record the request
        requestLog.append((request, body))
        
        // Check if we should fail
        if let error = shouldFailWithError, currentFailureCount < failureCount {
            currentFailureCount += 1
            throw error
        }
        
        // Get the path for response lookup
        let path = request.path ?? ""
        
        // Find matching response
        guard let mockResponse = responses[path] else {
            // Default to 404 if no mock response is configured
            let response = HTTPResponse(status: .notFound)
            return (response, nil)
        }
        
        // Add delay if specified
        if mockResponse.delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(mockResponse.delay * 1_000_000_000))
        }
        
        // Create HTTP response
        let status = HTTPResponse.Status(code: mockResponse.statusCode)
        var response = HTTPResponse(status: status)
        
        // Add headers
        for (key, value) in mockResponse.headers {
            response.headerFields[HTTPField.Name(key)!] = value
        }
        
        // Create response body
        let responseBody = mockResponse.data.map { HTTPBody($0) }
        
        return (response, responseBody)
    }
}

// MARK: - Convenience Methods

extension MockNetworking {
    /// Set a successful JSON response
    public func setSuccessResponse<T: Codable>(for path: String, object: T) throws {
        try setJSONResponse(for: path, object: object, statusCode: 200)
    }
    
    /// Set an error response
    public func setErrorResponse(for path: String, statusCode: Int, message: String? = nil) {
        let data = message?.data(using: .utf8)
        setResponse(for: path, response: MockResponse(statusCode: statusCode, data: data))
    }
    
    /// Set a network timeout error
    public func setTimeoutError() {
        let error = URLError(.timedOut)
        setFailure(error: error)
    }
    
    /// Set a network connection error
    public func setConnectionError() {
        let error = URLError(.notConnectedToInternet)
        setFailure(error: error)
    }
}