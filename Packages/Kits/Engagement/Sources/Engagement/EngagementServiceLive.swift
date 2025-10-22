//
//  EngagementServiceLive.swift
//  Engagement
//
//  Live implementation of engagement service using Supabase Edge Functions
//

import Foundation
import AppFoundation

/// Live implementation of EngagementService using Supabase Edge Functions
public struct EngagementServiceLive: EngagementService {
    private let baseURL: URL
    private let authTokenProvider: @Sendable () async throws -> String?
    private let session: URLSession
    
    public init(
        baseURL: URL,
        authTokenProvider: @escaping @Sendable () async throws -> String?,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.authTokenProvider = authTokenProvider
        self.session = session
    }
    
    public func toggleLike(postId: String) async throws -> LikeResult {
        let endpoint = baseURL.appendingPathComponent("toggle-like")
        let requestBody: [String: Any] = ["postId": postId]
        
        let response = try await makeRequest(to: endpoint, body: requestBody)
        
        guard let isLiked = response["isLiked"] as? Bool,
              let likeCount = response["likeCount"] as? Int else {
            throw EngagementError.serverError("Invalid response format")
        }
        
        return LikeResult(isLiked: isLiked, likeCount: likeCount)
    }
    
    public func toggleRepost(postId: String) async throws -> RepostResult {
        let endpoint = baseURL.appendingPathComponent("toggle-repost")
        let requestBody: [String: Any] = ["postId": postId]
        
        let response = try await makeRequest(to: endpoint, body: requestBody)
        
        guard let isReposted = response["isReposted"] as? Bool,
              let repostCount = response["repostCount"] as? Int else {
            throw EngagementError.serverError("Invalid response format")
        }
        
        return RepostResult(isReposted: isReposted, repostCount: repostCount)
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
    
    private func makeRequest(to endpoint: URL, body: [String: Any]) async throws -> [String: Any] {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add auth token if available
        if let token = try? await authTokenProvider() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Encode body
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw EngagementError.networkError
        }
        
        // Handle error responses
        if httpResponse.statusCode != 200 {
            let errorResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            let errorMessage = errorResponse?["message"] as? String ?? "Unknown error"
            
            switch httpResponse.statusCode {
            case 404:
                throw EngagementError.postNotFound
            case 401:
                throw EngagementError.unauthorized
            case 429:
                throw EngagementError.rateLimited
            default:
                throw EngagementError.serverError(errorMessage)
            }
        }
        
        // Parse success response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw EngagementError.serverError("Invalid response format")
        }
        
        return json
    }
}
