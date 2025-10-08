import Foundation
import OpenAPIRuntime
import HTTPTypes
import AppFoundation

/// Middleware that automatically adds authentication headers to requests
public struct AuthInterceptor: ClientMiddleware, Sendable {
    private let authTokenProvider: AuthTokenProvider?
    
    public init(authTokenProvider: AuthTokenProvider?) {
        self.authTokenProvider = authTokenProvider
    }
    
    public func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: @Sendable (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        var modifiedRequest = request
        
        // Add authentication header if token is available
        if let authTokenProvider = authTokenProvider {
            do {
                if let token = try await authTokenProvider.currentAccessToken() {
                    modifiedRequest.headerFields[.authorization] = "Bearer \(token)"
                }
            } catch {
                // Log the error but don't fail the request
                // Some endpoints might not require authentication
                Logger.networking.warning("Failed to get auth token for request to \(request.path ?? "unknown"): \(error)")
            }
        }
        
        // Add common headers
        modifiedRequest.headerFields[.userAgent] = "Agora-iOS/1.0"
        modifiedRequest.headerFields[.accept] = "application/json"
        
        if modifiedRequest.method == .post || modifiedRequest.method == .put || modifiedRequest.method == .patch {
            modifiedRequest.headerFields[.contentType] = "application/json"
        }
        
        return try await next(modifiedRequest, body, baseURL)
    }
}