// UserSearchServiceMock: Mock implementation for testing and previews

import Foundation
import AppFoundation

/// Mock implementation of UserSearchProtocol for testing and previews
public final class UserSearchServiceMock: UserSearchProtocol, Sendable {
    private let mockResults: [SearchUser]
    private let delay: Duration
    private let shouldFail: Bool
    
    /// Initialize mock user search service
    /// - Parameters:
    ///   - mockResults: Predefined search results to return
    ///   - delay: Simulated network delay (default: 100ms)
    ///   - shouldFail: Whether to simulate failure (default: false)
    public init(
        mockResults: [SearchUser] = [],
        delay: Duration = .milliseconds(100),
        shouldFail: Bool = false
    ) {
        #if DEBUG
        self.mockResults = mockResults.isEmpty ? SearchUser.previewArray : mockResults
        #else
        self.mockResults = mockResults
        #endif
        self.delay = delay
        self.shouldFail = shouldFail
    }
    
    // MARK: - UserSearchProtocol
    
    public func search(q: String, limit: Int, after: String?) async throws -> [SearchUser] {
        // Simulate network delay
        try? await Task.sleep(for: delay)
        
        if shouldFail {
            throw UserSearchError.serverError(500)
        }
        
        // Filter mock results by query
        let lowercaseQuery = q.lowercased().replacingOccurrences(of: "@", with: "")
        let filtered = mockResults.filter { user in
            user.handle.lowercased().contains(lowercaseQuery) ||
            user.displayName.lowercased().contains(lowercaseQuery)
        }
        
        // Apply cursor pagination
        let afterIndex = after.flatMap { afterHandle in
            filtered.firstIndex(where: { $0.handle > afterHandle })
        } ?? 0
        
        // Return paginated results
        let endIndex = min(afterIndex + limit, filtered.count)
        return Array(filtered[afterIndex..<endIndex])
    }
    
    public func suggestedCreators(limit: Int) async throws -> [SearchUser] {
        // Simulate network delay
        try? await Task.sleep(for: delay)
        
        if shouldFail {
            throw UserSearchError.serverError(500)
        }
        
        // Return top users by follower count
        let sorted = mockResults.sorted { $0.followersCount > $1.followersCount }
        return Array(sorted.prefix(limit))
    }
    
    public func lookupByHandle(_ handle: String) async throws -> SearchUser? {
        // Simulate network delay
        try? await Task.sleep(for: delay)
        
        if shouldFail {
            throw UserSearchError.serverError(500)
        }
        
        let cleanHandle = handle.lowercased().replacingOccurrences(of: "@", with: "")
        return mockResults.first(where: { $0.handle.lowercased() == cleanHandle })
    }
}

// MARK: - Convenience Initializers

extension UserSearchServiceMock {
    /// Mock service with no results (empty state testing)
    public static var empty: UserSearchServiceMock {
        UserSearchServiceMock(mockResults: [])
    }
    
    /// Mock service that always fails (error state testing)
    public static var failing: UserSearchServiceMock {
        UserSearchServiceMock(shouldFail: true)
    }
    
    /// Mock service with instant responses (no delay)
    public static var instant: UserSearchServiceMock {
        UserSearchServiceMock(delay: .zero)
    }
}

