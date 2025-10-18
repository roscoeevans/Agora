//
//  SearchView.swift
//  Agora
//
//  Created by Agora Team on 2024.
//

import SwiftUI
import DesignSystem
import AppFoundation

public struct SearchView: View {
    @Environment(\.deps) private var deps
    @State private var viewModel: SearchViewModel?
    @State private var searchText = ""
    
    public init() {}
    
    public var body: some View {
        Group {
            if let viewModel = viewModel {
                ScrollView {
                    VStack(spacing: 0) {
                        // Search results
                        if searchText.isEmpty {
                            EmptySearchView()
                        } else if viewModel.isLoading {
                            LoadingView()
                        } else if viewModel.searchResults.isEmpty {
                            NoResultsView(query: searchText)
                        } else {
                            SearchResultsList(results: viewModel.searchResults)
                        }
                    }
                    .padding(.bottom, 100) // Add bottom padding to ensure content extends under tab bar
                }
                .navigationTitle("Search")
                .navigationBarTitleDisplayMode(.large)
                .searchable(text: $searchText, prompt: "Search users and posts")
                .onChange(of: searchText) { _, newValue in
                    Task {
                        await viewModel.search(query: newValue)
                    }
                }
            } else {
                LoadingView()
            }
        }
        .task {
            // Initialize view model with dependencies from environment
            // Following DI rule: dependencies injected from environment
            self.viewModel = SearchViewModel(networking: deps.networking)
        }
    }
}

struct EmptySearchView: View {
    var body: some View {
        VStack(spacing: SpacingTokens.lg) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(ColorTokens.tertiaryText)
                .symbolEffect(.pulse, isActive: true)
            
            Text("Search Agora")
                .font(TypographyScale.title2)
                .foregroundColor(ColorTokens.primaryText)
            
            Text("Find users and posts by typing in the search bar above.")
                .font(TypographyScale.body)
                .foregroundColor(ColorTokens.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(SpacingTokens.xl)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(ColorTokens.separator.opacity(0.2), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Search Agora. Find users and posts by typing in the search bar above.")
    }
}

struct NoResultsView: View {
    let query: String
    
    var body: some View {
        VStack(spacing: SpacingTokens.lg) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(ColorTokens.tertiaryText)
            
            Text("No Results")
                .font(TypographyScale.title2)
                .foregroundColor(ColorTokens.primaryText)
            
            Text("No results found for \"\(query)\". Try a different search term.")
                .font(TypographyScale.body)
                .foregroundColor(ColorTokens.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(SpacingTokens.xl)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(ColorTokens.separator.opacity(0.2), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No results found for \(query). Try a different search term.")
    }
}

struct SearchResultsList: View {
    let results: [SearchResult]
    
    var body: some View {
        LazyVStack(spacing: SpacingTokens.md) {
            ForEach(results, id: \.id) { result in
                SearchResultCard(result: result)
            }
        }
        .padding(SpacingTokens.md)
    }
}

struct SearchResultCard: View {
    let result: SearchResult
    @State private var isPressed = false
    @Environment(\.navigateToSearchResult) private var navigateToSearchResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.sm) {
            HStack(alignment: .top, spacing: SpacingTokens.sm) {
                Circle()
                    .fill(ColorTokens.agoraBrand)
                    .frame(width: 40, height: 40)
                    .overlay {
                        Text(String(result.title.prefix(1)))
                            .font(TypographyScale.calloutEmphasized)
                            .foregroundColor(.white)
                    }
                
                VStack(alignment: .leading, spacing: SpacingTokens.xxs) {
                    HStack {
                        Text(result.title)
                            .font(TypographyScale.calloutEmphasized)
                            .foregroundColor(ColorTokens.primaryText)
                        
                        Spacer()
                        
                        Image(systemName: result.type == .user ? "person" : "doc.text")
                            .font(TypographyScale.footnote)
                            .foregroundColor(ColorTokens.tertiaryText)
                    }
                    
                    Text(result.subtitle)
                        .font(TypographyScale.caption1)
                        .foregroundColor(ColorTokens.tertiaryText)
                }
            }
            
            if let content = result.content {
                Text(content)
                    .font(TypographyScale.body)
                    .foregroundColor(ColorTokens.secondaryText)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(SpacingTokens.md)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: SpacingTokens.sm))
        .overlay(
            RoundedRectangle(cornerRadius: SpacingTokens.sm)
                .stroke(ColorTokens.separator.opacity(0.3), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.05), radius: SpacingTokens.xxs, x: 0, y: 2)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onTapGesture {
            // Add haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            // Navigate to search result
            if let navigate = navigateToSearchResult, let uuid = UUID(uuidString: result.id) {
                navigate.action(uuid)
            }
        }
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .frame(minHeight: 60) // Ensure adequate touch target
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Double tap to view \(result.type == .user ? "profile" : "post")")
    }
    
    private var accessibilityLabel: String {
        var label = "\(result.type == .user ? "User" : "Post"): \(result.title)"
        if let content = result.content {
            label += ". \(content)"
        }
        return label
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: SpacingTokens.md) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Searching...")
                .font(TypographyScale.callout)
                .foregroundColor(ColorTokens.secondaryText)
        }
        .padding(SpacingTokens.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#if DEBUG
#Preview("Search") {
    PreviewDeps.scoped {
        SearchView()
    }
}
#endif