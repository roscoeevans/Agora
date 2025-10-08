import Foundation
import OpenAPIRuntime
import HTTPTypes

/// Mock transport implementation for OpenAPI client testing
public final class MockTransport: ClientTransport, @unchecked Sendable {
    private let mockNetworking: MockNetworking
    
    public init(mockNetworking: MockNetworking = MockNetworking()) {
        self.mockNetworking = mockNetworking
    }
    
    public func send(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String
    ) async throws -> (HTTPResponse, HTTPBody?) {
        return try await mockNetworking.performRequest(request, body: body)
    }
    
    /// Access the underlying mock networking for configuration
    public var mock: MockNetworking {
        return mockNetworking
    }
}