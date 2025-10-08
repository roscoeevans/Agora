import XCTest
import HTTPTypes
import OpenAPIRuntime
@testable import Networking
import TestSupport
import AppFoundation

/// Comprehensive tests for MockNetworking implementation and network behavior
final class MockNetworkingTests: XCTestCase {
    
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
    
    // MARK: - MockNetworking Basic Functionality Tests
    
    func testMockNetworkingBasicResponse() async throws {
        // Set up mock response
        let testData = "Hello, World!".data(using: .utf8)!
        mockNetworking.setResponse(
            for: "/test",
            response: MockNetworking.MockResponse(statusCode: 200, data: testData)
        )
        
        // Create request
        let request = HTTPRequest(method: .get, scheme: "https", authority: "api.test.com", path: "/test")
        
        // Perform request
        let (response, body) = try await mockNetworking.performRequest(request, body: nil)
        
        // Verify response
        XCTAssertEqual(response.status.code, 200)
        
        if let body = body {
            let data = try await Data(collecting: body, upTo: 1024)
            XCTAssertEqual(data, testData)
        } else {
            XCTFail("Expected response body")
        }
        
        // Verify request was recorded
        XCTAssertEqual(mockNetworking.recordedRequests.count, 1)
        XCTAssertEqual(mockNetworking.lastRequest?.0.path, "/test")
    }
    
    func testMockNetworkingJSONResponse() async throws {
        struct TestResponse: Codable, Equatable {
            let message: String
            let count: Int
        }
        
        let testObject = TestResponse(message: "Success", count: 42)
        try mockNetworking.setJSONResponse(for: "/json", object: testObject)
        
        let request = HTTPRequest(method: .get, scheme: "https", authority: "api.test.com", path: "/json")
        let (response, body) = try await mockNetworking.performRequest(request, body: nil)
        
        XCTAssertEqual(response.status.code, 200)
        
        if let body = body {
            let data = try await Data(collecting: body, upTo: 1024)
            let decodedObject = try JSONDecoder().decode(TestResponse.self, from: data)
            XCTAssertEqual(decodedObject, testObject)
        } else {
            XCTFail("Expected response body")
        }
    }
    
    func testMockNetworkingErrorResponse() async throws {
        mockNetworking.setErrorResponse(for: "/error", statusCode: 404, message: "Not Found")
        
        let request = HTTPRequest(method: .get, scheme: "https", authority: "api.test.com", path: "/error")
        let (response, body) = try await mockNetworking.performRequest(request, body: nil)
        
        XCTAssertEqual(response.status.code, 404)
        
        if let body = body {
            let data = try await Data(collecting: body, upTo: 1024)
            let message = String(data: data, encoding: .utf8)
            XCTAssertEqual(message, "Not Found")
        }
    }
    
    func testMockNetworkingDelayedResponse() async throws {
        let startTime = Date()
        let delay: TimeInterval = 0.1
        
        mockNetworking.setResponse(
            for: "/delayed",
            response: MockNetworking.MockResponse(statusCode: 200, delay: delay)
        )
        
        let request = HTTPRequest(method: .get, scheme: "https", authority: "api.test.com", path: "/delayed")
        let (response, _) = try await mockNetworking.performRequest(request, body: nil)
        
        let elapsed = Date().timeIntervalSince(startTime)
        XCTAssertEqual(response.status.code, 200)
        XCTAssertGreaterThanOrEqual(elapsed, delay)
    }
    
    func testMockNetworkingFailureSimulation() async throws {
        let testError = URLError(.timedOut)
        mockNetworking.setFailure(error: testError, count: 1)
        
        let request = HTTPRequest(method: .get, scheme: "https", authority: "api.test.com", path: "/fail")
        
        do {
            _ = try await mockNetworking.performRequest(request, body: nil)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is URLError)
            if let urlError = error as? URLError {
                XCTAssertEqual(urlError.code, .timedOut)
            }
        }
    }
    
    func testMockNetworkingMultipleFailures() async throws {
        let testError = URLError(.networkConnectionLost)
        mockNetworking.setFailure(error: testError, count: 2)
        
        let request = HTTPRequest(method: .get, scheme: "https", authority: "api.test.com", path: "/fail")
        
        // First request should fail
        do {
            _ = try await mockNetworking.performRequest(request, body: nil)
            XCTFail("Expected first request to fail")
        } catch {
            XCTAssertTrue(error is URLError)
        }
        
        // Second request should also fail
        do {
            _ = try await mockNetworking.performRequest(request, body: nil)
            XCTFail("Expected second request to fail")
        } catch {
            XCTAssertTrue(error is URLError)
        }
        
        // Third request should succeed (no more failures configured)
        mockNetworking.setResponse(for: "/fail", response: MockNetworking.MockResponse(statusCode: 200))
        let (response, _) = try await mockNetworking.performRequest(request, body: nil)
        XCTAssertEqual(response.status.code, 200)
    }
    
    // MARK: - Request Recording and Inspection Tests
    
    func testRequestRecording() async throws {
        mockNetworking.setResponse(for: "/test1", response: MockNetworking.MockResponse(statusCode: 200))
        mockNetworking.setResponse(for: "/test2", response: MockNetworking.MockResponse(statusCode: 201))
        
        let request1 = HTTPRequest(method: .get, scheme: "https", authority: "api.test.com", path: "/test1")
        let request2 = HTTPRequest(method: .post, scheme: "https", authority: "api.test.com", path: "/test2")
        
        _ = try await mockNetworking.performRequest(request1, body: nil)
        _ = try await mockNetworking.performRequest(request2, body: nil)
        
        XCTAssertEqual(mockNetworking.recordedRequests.count, 2)
        XCTAssertEqual(mockNetworking.recordedRequests[0].0.path, "/test1")
        XCTAssertEqual(mockNetworking.recordedRequests[1].0.path, "/test2")
        XCTAssertEqual(mockNetworking.lastRequest?.0.path, "/test2")
        
        XCTAssertTrue(mockNetworking.wasRequestMade(to: "/test1"))
        XCTAssertTrue(mockNetworking.wasRequestMade(to: "/test2"))
        XCTAssertFalse(mockNetworking.wasRequestMade(to: "/test3"))
        
        let test1Requests = mockNetworking.requests(to: "/test1")
        XCTAssertEqual(test1Requests.count, 1)
        XCTAssertEqual(test1Requests[0].0.method, .get)
    }
    
    func testMockNetworkingReset() async throws {
        // Set up some state
        mockNetworking.setResponse(for: "/test", response: MockNetworking.MockResponse(statusCode: 200))
        
        let request = HTTPRequest(method: .get, scheme: "https", authority: "api.test.com", path: "/test")
        _ = try await mockNetworking.performRequest(request, body: nil)
        
        XCTAssertEqual(mockNetworking.recordedRequests.count, 1)
        
        // Reset and verify clean state
        mockNetworking.reset()
        
        XCTAssertEqual(mockNetworking.recordedRequests.count, 0)
        XCTAssertNil(mockNetworking.lastRequest)
        XCTAssertFalse(mockNetworking.wasRequestMade(to: "/test"))
        
        // Verify that unmocked requests return 404
        let (response, _) = try await mockNetworking.performRequest(request, body: nil)
        XCTAssertEqual(response.status.code, 404)
    }
    
    // MARK: - Convenience Methods Tests
    
    func testConvenienceMethods() async throws {
        struct TestData: Codable, Equatable {
            let id: Int
            let name: String
        }
        
        let testData = TestData(id: 1, name: "Test")
        
        // Test setSuccessResponse
        try mockNetworking.setSuccessResponse(for: "/success", object: testData)
        
        let request1 = HTTPRequest(method: .get, scheme: "https", authority: "api.test.com", path: "/success")
        let (response1, body1) = try await mockNetworking.performRequest(request1, body: nil)
        
        XCTAssertEqual(response1.status.code, 200)
        if let body1 = body1 {
            let data = try await Data(collecting: body1, upTo: 1024)
            let decoded = try JSONDecoder().decode(TestData.self, from: data)
            XCTAssertEqual(decoded, testData)
        }
        
        // Test setTimeoutError
        mockNetworking.setTimeoutError()
        
        let request2 = HTTPRequest(method: .get, scheme: "https", authority: "api.test.com", path: "/timeout")
        
        do {
            _ = try await mockNetworking.performRequest(request2, body: nil)
            XCTFail("Expected timeout error")
        } catch {
            XCTAssertTrue(error is URLError)
            if let urlError = error as? URLError {
                XCTAssertEqual(urlError.code, .timedOut)
            }
        }
        
        // Test setConnectionError
        mockNetworking.reset()
        mockNetworking.setConnectionError()
        
        let request3 = HTTPRequest(method: .get, scheme: "https", authority: "api.test.com", path: "/connection")
        
        do {
            _ = try await mockNetworking.performRequest(request3, body: nil)
            XCTFail("Expected connection error")
        } catch {
            XCTAssertTrue(error is URLError)
            if let urlError = error as? URLError {
                XCTAssertEqual(urlError.code, .notConnectedToInternet)
            }
        }
    }
}