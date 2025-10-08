import XCTest
import Foundation

/// Custom XCTest assertions and utilities
public extension XCTestCase {
    
    /// Assert that two dates are approximately equal (within tolerance)
    func assertDatesEqual(
        _ date1: Date,
        _ date2: Date,
        tolerance: TimeInterval = 1.0,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let difference = abs(date1.timeIntervalSince(date2))
        XCTAssertLessThanOrEqual(
            difference,
            tolerance,
            "Dates differ by \(difference) seconds, expected within \(tolerance) seconds",
            file: (file),
            line: line
        )
    }
    
    /// Assert that a URL is valid and reachable
    func assertValidURL(
        _ url: URL?,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertNotNil(url, "URL should not be nil", file: (file), line: line)
        guard let url = url else { return }
        
        XCTAssertNotNil(url.scheme, "URL should have a scheme", file: (file), line: line)
        XCTAssertNotNil(url.host, "URL should have a host", file: (file), line: line)
    }
    
    /// Assert that a string contains only valid characters for a handle
    func assertValidHandle(
        _ handle: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertFalse(handle.isEmpty, "Handle should not be empty", file: (file), line: line)
        XCTAssertLessThanOrEqual(handle.count, 30, "Handle should not exceed 30 characters", file: (file), line: line)
        XCTAssertGreaterThanOrEqual(handle.count, 3, "Handle should be at least 3 characters", file: (file), line: line)
        
        let validCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))
        let handleCharacters = CharacterSet(charactersIn: handle)
        XCTAssertTrue(
            validCharacters.isSuperset(of: handleCharacters),
            "Handle contains invalid characters",
            file: (file),
            line: line
        )
    }
    
    /// Wait for a condition to become true (synchronous version)
    func waitForCondition(
        timeout: TimeInterval = 5.0,
        pollingInterval: TimeInterval = 0.1,
        file: StaticString = #filePath,
        line: UInt = #line,
        condition: @escaping () -> Bool
    ) {
        let startTime = Date()
        
        while !condition() {
            if Date().timeIntervalSince(startTime) > timeout {
                XCTFail("Condition not met within timeout of \(timeout) seconds", file: (file), line: line)
                return
            }
            
            Thread.sleep(forTimeInterval: pollingInterval)
        }
    }
}

/// Timeout error for async operations
public struct TimeoutError: Error, LocalizedError {
    public var errorDescription: String? {
        return "Operation timed out"
    }
}

/// Mock URLSession for testing network requests
public class MockURLSession: @unchecked Sendable {
    public var mockData: Data?
    public var mockResponse: URLResponse?
    public var mockError: Error?
    
    public init() {}
    
    public func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        if let error = mockError {
            throw error
        }
        
        let data = mockData ?? Data()
        let response = mockResponse ?? HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        
        return (data, response)
    }
}