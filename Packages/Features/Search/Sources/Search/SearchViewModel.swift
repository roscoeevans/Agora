//
//  SearchViewModel.swift
//  Agora
//
//  Created by Agora Team on 2024.
//

import Foundation
import SwiftUI
import AppFoundation

@MainActor
@Observable
public class SearchViewModel {
    // MARK: - Published State
    
    public var searchResults: [SearchUser] = []
    public var suggestedCreators: [SearchUser] = []
    public var isLoading = false
    public var error: Error?
    public var hasMore = false
    
    // MARK: - Private State
    
    private var currentCursor: String?
    private var searchTask: Task<Void, Never>?
    private let userSearch: UserSearchProtocol?
    
    // MARK: - Initialization
    
    public init(userSearch: UserSearchProtocol?) {
        self.userSearch = userSearch
    }
    
    // MARK: - Public Methods
    
    /// Search for users with debouncing
    public func search(query: String) async {
        // Cancel previous search
        searchTask?.cancel()
        
        // Clear results if query is empty
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = []
            currentCursor = nil
            hasMore = false
            await loadSuggestedCreators() // Show suggested creators when empty
            return
        }
        
        searchTask = Task {
            isLoading = true
            defer { isLoading = false }
            
            do {
                // Debounce rapid typing (300ms)
                try await Task.sleep(for: .milliseconds(300))
                try Task.checkCancellation()
                
                // Perform search
                guard let service = userSearch else {
                    throw SearchError.serviceUnavailable
                }
                
                let results = try await service.search(
                    q: query,
                    limit: 20,
                    after: nil // Reset cursor for new search
                )
                
                try Task.checkCancellation()
                
                // Update UI
                searchResults = results
                currentCursor = results.last?.handle
                hasMore = results.count >= 20
                error = nil
                
            } catch is CancellationError {
                // Task was cancelled, do nothing
            } catch {
                self.error = error
                searchResults = []
            }
        }
        
        await searchTask?.value
    }
    
    /// Load more results (pagination)
    public func loadMore(query: String) async {
        guard !isLoading, hasMore, let cursor = currentCursor else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            guard let service = userSearch else {
                throw SearchError.serviceUnavailable
            }
            
            let moreResults = try await service.search(
                q: query,
                limit: 20,
                after: cursor
            )
            
            // Append results
            searchResults.append(contentsOf: moreResults)
            currentCursor = moreResults.last?.handle
            hasMore = moreResults.count >= 20
            error = nil
            
        } catch {
            self.error = error
            hasMore = false
        }
    }
    
    /// Load suggested creators (for empty state)
    public func loadSuggestedCreators() async {
        guard suggestedCreators.isEmpty else { return }
        
        do {
            guard let service = userSearch else {
                throw SearchError.serviceUnavailable
            }
            
            let creators = try await service.suggestedCreators(limit: 10)
            suggestedCreators = creators
            
        } catch {
            // Silently fail for suggested creators
            print("Failed to load suggested creators: \(error)")
        }
    }
    
    /// Clear all results and state
    public func clear() {
        searchResults = []
        suggestedCreators = []
        currentCursor = nil
        hasMore = false
        error = nil
        searchTask?.cancel()
    }
}

// MARK: - Search Errors

enum SearchError: LocalizedError {
    case serviceUnavailable
    case invalidQuery
    
    var errorDescription: String? {
        switch self {
        case .serviceUnavailable:
            return "Search service is not available"
        case .invalidQuery:
            return "Invalid search query"
        }
    }
}

// MARK: - Legacy SearchResult (for compatibility)

public struct SearchResult: Identifiable, Codable {
    public let id: String
    public let type: SearchResultType
    public let title: String
    public let subtitle: String
    public let content: String?
    
    public init(type: SearchResultType, title: String, subtitle: String, content: String? = nil) {
        self.id = UUID().uuidString
        self.type = type
        self.title = title
        self.subtitle = subtitle
        self.content = content
    }
}

public enum SearchResultType: String, Codable, CaseIterable {
    case user
    case post
}
