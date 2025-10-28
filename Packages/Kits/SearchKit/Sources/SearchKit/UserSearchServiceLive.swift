// UserSearchServiceLive: Production implementation of user search

import Foundation
import AppFoundation

/// Live implementation of UserSearchProtocol that calls Supabase Edge Functions
public final class UserSearchServiceLive: UserSearchProtocol, Sendable {
    private let baseURL: URL
    private let authTokenProvider: @Sendable () async -> String?
    
    /// Initialize live user search service
    /// - Parameters:
    ///   - baseURL: Supabase project URL
    ///   - authTokenProvider: Async closure providing current JWT access token
    public init(
        baseURL: URL,
        authTokenProvider: @escaping @Sendable () async -> String?
    ) {
        self.baseURL = baseURL
        self.authTokenProvider = authTokenProvider
    }
    
    // MARK: - UserSearchProtocol
    
    public func search(q: String, limit: Int, after: String?) async throws -> [SearchUser] {
        // Build URL with query parameters
        var components = URLComponents(
            url: baseURL.appendingPathComponent("/functions/v1/search-users"),
            resolvingAgainstBaseURL: false
        )!
        
        components.queryItems = [
            URLQueryItem(name: "q", value: q),
            URLQueryItem(name: "limit", value: String(limit)),
        ]
        
        if let after = after {
            components.queryItems?.append(URLQueryItem(name: "after", value: after))
        }
        
        guard let url = components.url else {
            throw UserSearchError.invalidURL
        }
        
        // Create request with authentication
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = await authTokenProvider() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            throw UserSearchError.unauthorized
        }
        
        // Execute request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check HTTP status
        guard let httpResponse = response as? HTTPURLResponse else {
            throw UserSearchError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 {
                throw UserSearchError.unauthorized
            } else if httpResponse.statusCode == 400 {
                throw UserSearchError.badRequest
            } else {
                throw UserSearchError.serverError(httpResponse.statusCode)
            }
        }
        
        // Decode response
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let responsePayload = try decoder.decode(SearchResponse.self, from: data)
        return responsePayload.items
    }
    
    public func suggestedCreators(limit: Int) async throws -> [SearchUser] {
        // Build URL
        var components = URLComponents(
            url: baseURL.appendingPathComponent("/functions/v1/suggested-creators"),
            resolvingAgainstBaseURL: false
        )!
        
        components.queryItems = [
            URLQueryItem(name: "limit", value: String(limit))
        ]
        
        guard let url = components.url else {
            throw UserSearchError.invalidURL
        }
        
        // Create request with authentication
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = await authTokenProvider() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            throw UserSearchError.unauthorized
        }
        
        // Execute request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check HTTP status
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw UserSearchError.serverError((response as? HTTPURLResponse)?.statusCode ?? -1)
        }
        
        // Decode response
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let responsePayload = try decoder.decode(SuggestedCreatorsResponse.self, from: data)
        return responsePayload.items
    }
    
    public func lookupByHandle(_ handle: String) async throws -> SearchUser? {
        // Use search with exact handle query
        let cleanHandle = handle.trimmingCharacters(in: .whitespacesAndNewlines)
        let query = cleanHandle.hasPrefix("@") ? cleanHandle : "@\(cleanHandle)"
        
        let results = try await search(q: query, limit: 1, after: nil)
        
        // Return first result if it's an exact match
        return results.first(where: { $0.handle.lowercased() == cleanHandle.lowercased().replacingOccurrences(of: "@", with: "") })
    }
}

// MARK: - Response Models

private struct SearchResponse: Codable {
    let items: [SearchUser]
    let query: String
    let count: Int
    let hasMore: Bool
    let nextCursor: String?
}

private struct SuggestedCreatorsResponse: Codable {
    let items: [SearchUser]
}

// MARK: - Errors

public enum UserSearchError: Error, LocalizedError {
    case invalidURL
    case unauthorized
    case badRequest
    case invalidResponse
    case serverError(Int)
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid search URL"
        case .unauthorized:
            return "Authentication required for search"
        case .badRequest:
            return "Invalid search query"
        case .invalidResponse:
            return "Invalid server response"
        case .serverError(let code):
            return "Server error (\(code))"
        }
    }
}

