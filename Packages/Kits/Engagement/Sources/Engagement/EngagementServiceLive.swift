import Foundation
import AppFoundation

/// Production implementation of EngagementService
public actor EngagementServiceLive: EngagementService {
    private let baseURL: URL
    private let authTokenProvider: () async -> String?
    private let session: URLSession
    
    /// Initialize engagement service
    /// - Parameters:
    ///   - baseURL: Base URL for Supabase Edge Functions
    ///   - authTokenProvider: Closure that provides the current auth token
    ///   - session: URLSession for networking (defaults to .shared)
    public init(
        baseURL: URL,
        authTokenProvider: @escaping () async -> String?,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.authTokenProvider = authTokenProvider
        self.session = session
    }
    
    public func toggleLike(postId: String) async throws -> LikeResult {
        let endpoint = baseURL.appendingPathComponent("toggle-like")
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authorization header
        if let token = await authTokenProvider() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Request body
        let body = ["postId": postId]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        // Make request
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw EngagementError.networkError
        }
        
        // Handle errors
        if httpResponse.statusCode != 200 {
            throw try mapHTTPError(statusCode: httpResponse.statusCode, data: data)
        }
        
        // Parse success response
        let result = try JSONDecoder().decode(LikeResultResponse.self, from: data)
        return LikeResult(isLiked: result.isLiked, likeCount: result.likeCount)
    }
    
    public func toggleRepost(postId: String) async throws -> RepostResult {
        let endpoint = baseURL.appendingPathComponent("toggle-repost")
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authorization header
        if let token = await authTokenProvider() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Request body
        let body = ["postId": postId]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        // Make request
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw EngagementError.networkError
        }
        
        // Handle errors
        if httpResponse.statusCode != 200 {
            throw try mapHTTPError(statusCode: httpResponse.statusCode, data: data)
        }
        
        // Parse success response
        let result = try JSONDecoder().decode(RepostResultResponse.self, from: data)
        return RepostResult(isReposted: result.isReposted, repostCount: result.repostCount)
    }
    
    public func getShareURL(postId: String) async throws -> URL {
        // For MVP, construct URL directly
        // In future, could call API to get short URL
        guard let url = URL(string: "https://agora.app/p/\(postId)") else {
            throw EngagementError.serverError("Invalid post ID")
        }
        return url
    }
    
    // MARK: - Private Helpers
    
    private func mapHTTPError(statusCode: Int, data: Data) throws -> EngagementError {
        // Try to decode error response
        if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
            switch errorResponse.code {
            case "POST_NOT_FOUND":
                return .postNotFound
            case "UNAUTHORIZED":
                return .unauthorized
            case "RATE_LIMITED":
                return .rateLimited
            default:
                return .serverError(errorResponse.message)
            }
        }
        
        // Fallback based on status code
        switch statusCode {
        case 401:
            return .unauthorized
        case 404:
            return .postNotFound
        case 429:
            return .rateLimited
        case 500...599:
            return .serverError("Server error")
        default:
            return .networkError
        }
    }
}

// MARK: - Response Types

private struct LikeResultResponse: Decodable {
    let isLiked: Bool
    let likeCount: Int
}

private struct RepostResultResponse: Decodable {
    let isReposted: Bool
    let repostCount: Int
}

private struct ErrorResponse: Decodable {
    let code: String
    let message: String
    let correlationId: String?
}

