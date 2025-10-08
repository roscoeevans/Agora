//
//  SearchViewModel.swift
//  Agora
//
//  Created by Agora Team on 2024.
//

import Foundation
import SwiftUI
import Networking

@MainActor
@Observable
public class SearchViewModel {
    public var searchResults: [SearchResult] = []
    public var isLoading = false
    public var error: Error?
    
    private let networking: APIClient
    private var searchTask: Task<Void, Never>?
    
    public init(networking: APIClient = APIClient.shared) {
        self.networking = networking
    }
    
    public func search(query: String) async {
        // Cancel previous search
        searchTask?.cancel()
        
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = []
            return
        }
        
        searchTask = Task {
            isLoading = true
            defer { isLoading = false }
            
            do {
                // Add a small delay to debounce rapid typing
                try await Task.sleep(nanoseconds: 300_000_000) // 300ms
                
                // Check if task was cancelled
                try Task.checkCancellation()
                
                // TODO: Implement actual API call
                // For now, simulate network delay and load placeholder data
                try await Task.sleep(nanoseconds: 500_000_000) // 500ms
                
                // Check if task was cancelled again
                try Task.checkCancellation()
                
                loadPlaceholderResults(for: query)
            } catch is CancellationError {
                // Task was cancelled, do nothing
            } catch {
                self.error = error
            }
        }
        
        await searchTask?.value
    }
    
    private func loadPlaceholderResults(for query: String) {
        let lowercaseQuery = query.lowercased()
        
        var results: [SearchResult] = []
        
        // Mock user results
        let users = [
            ("Alice Johnson", "@alice", "iOS developer and coffee enthusiast"),
            ("Bob Smith", "@bobsmith", "Designer creating beautiful experiences"),
            ("Carol Davis", "@carol_d", "Writer sharing stories and insights"),
            ("David Wilson", "@dwilson", "Photographer capturing life's moments")
        ]
        
        for (name, handle, bio) in users {
            if name.lowercased().contains(lowercaseQuery) || handle.lowercased().contains(lowercaseQuery) {
                results.append(SearchResult(
                    type: .user,
                    title: name,
                    subtitle: handle,
                    content: bio
                ))
            }
        }
        
        // Mock post results
        let posts = [
            ("Alice Johnson", "Just shipped a new feature! Really excited about the user feedback so far."),
            ("Bob Smith", "Working on some new design concepts. The creative process never stops!"),
            ("Carol Davis", "Sometimes the best stories come from the most unexpected places."),
            ("David Wilson", "Golden hour photography tips: timing is everything in capturing the perfect shot.")
        ]
        
        for (author, content) in posts {
            if content.lowercased().contains(lowercaseQuery) {
                results.append(SearchResult(
                    type: .post,
                    title: author,
                    subtitle: "Posted recently",
                    content: content
                ))
            }
        }
        
        searchResults = results
    }
}

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