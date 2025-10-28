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
                Group {
                    // Show empty/loading states without ScrollView (for proper centering)
                    if searchText.isEmpty {
                        // Empty search state - centered like "You're All Caught Up"
                        VStack {
                            Spacer()
                            AgoraEmptyStateView.emptySearch()
                                .padding(.horizontal, SpacingTokens.md)
                                .transition(.liquidGlass)
                            Spacer()
                        }
                        
                    } else if viewModel.isLoading && viewModel.searchResults.isEmpty {
                        // Loading state - centered
                        VStack {
                            Spacer()
                            LoadingView()
                            Spacer()
                        }
                            
                    } else if viewModel.searchResults.isEmpty {
                        // No results state - centered
                        VStack {
                            Spacer()
                            AgoraEmptyStateView.noSearchResults()
                                .padding(.horizontal, SpacingTokens.md)
                                .transition(.liquidGlass)
                            Spacer()
                        }
                            
                    } else {
                        // Search results list - needs ScrollView
                        ScrollView {
                            SearchResultsList(
                                results: viewModel.searchResults,
                                isLoading: viewModel.isLoading,
                                hasMore: viewModel.hasMore,
                                onLoadMore: {
                                    Task {
                                        await viewModel.loadMore(query: searchText)
                                    }
                                }
                            )
                            .padding(.bottom, 100) // Add bottom padding to ensure content extends under tab bar
                        }
                    }
                }
                .navigationTitle("Search")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.large)
                #endif
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
            self.viewModel = SearchViewModel(userSearch: deps.userSearch)
            
            // Load suggested creators for empty state
            if let vm = viewModel {
                await vm.loadSuggestedCreators()
            }
        }
    }
}

// MARK: - Suggested Creators Section

struct SuggestedCreatorsSection: View {
    let creators: [SearchUser]
    
    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.md) {
            Text("Suggested People")
                .font(TypographyScale.headline)
                .foregroundColor(ColorTokens.primaryText)
                .padding(.horizontal, SpacingTokens.lg)
            
            LazyVStack(spacing: SpacingTokens.sm) {
                ForEach(creators) { creator in
                    UserRow(user: creator)
                }
            }
            .padding(.horizontal, SpacingTokens.md)
        }
    }
}

// MARK: - Search Results List

struct SearchResultsList: View {
    let results: [SearchUser]
    let isLoading: Bool
    let hasMore: Bool
    let onLoadMore: () -> Void
    
    var body: some View {
        LazyVStack(spacing: SpacingTokens.sm) {
            ForEach(results) { user in
                UserRow(user: user)
            }
            
            // Load more indicator
            if hasMore {
                HStack {
                    Spacer()
                    if isLoading {
                        ProgressView()
                            .padding(SpacingTokens.md)
                    } else {
                        Button(action: onLoadMore) {
                            Text("Load More")
                                .font(TypographyScale.callout)
                                .foregroundColor(ColorTokens.agoraBrand)
                        }
                        .padding(SpacingTokens.md)
                    }
                    Spacer()
                }
            }
        }
        .padding(SpacingTokens.md)
    }
}

// MARK: - User Row

struct UserRow: View {
    let user: SearchUser
    @State private var isPressed = false
    @State private var hapticTrigger = false
    @Environment(\.navigateToProfile) private var navigateToProfile
    
    var body: some View {
        HStack(alignment: .top, spacing: SpacingTokens.md) {
            // Avatar
            Circle()
                .fill(ColorTokens.agoraBrand.gradient)
                .frame(width: 48, height: 48)
                .overlay {
                    Text(String(user.displayName.prefix(1)))
                        .font(TypographyScale.title3)
                        .foregroundColor(.white)
                }
            
            // User info
            VStack(alignment: .leading, spacing: SpacingTokens.xxs) {
                HStack(spacing: SpacingTokens.xs) {
                    Text(user.displayName)
                        .font(TypographyScale.calloutEmphasized)
                        .foregroundColor(ColorTokens.primaryText)
                    
                    if user.verified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(TypographyScale.caption2)
                            .foregroundColor(ColorTokens.agoraBrand)
                    }
                    
                    Spacer()
                }
                
                Text("@\(user.displayHandle)")
                    .font(TypographyScale.caption1)
                    .foregroundColor(ColorTokens.tertiaryText)
                
                // Follower count
                if user.followersCount > 0 {
                    Text("\(user.followersCount) followers")
                        .font(TypographyScale.caption2)
                        .foregroundColor(ColorTokens.tertiaryText)
                }
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(TypographyScale.caption1)
                .foregroundColor(ColorTokens.tertiaryText)
        }
        .padding(SpacingTokens.md)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: BorderRadiusTokens.md))
        .overlay(
            RoundedRectangle(cornerRadius: BorderRadiusTokens.md)
                .stroke(ColorTokens.separator.opacity(0.3), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onTapGesture {
            hapticTrigger.toggle()
            navigateToProfile?(user.userId)
        }
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(user.displayName), @\(user.displayHandle)\(user.verified ? ", verified" : ""), \(user.followersCount) followers")
        .accessibilityHint("Double tap to view profile")
        .sensoryFeedback(.selection, trigger: hapticTrigger)
    }
}

// MARK: - Loading View

struct LoadingView: View {
    var body: some View {
        VStack(spacing: SpacingTokens.lg) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(ColorTokens.agoraBrand)
            
            Text("Searching...")
                .font(TypographyScale.body)
                .foregroundColor(ColorTokens.secondaryText)
        }
        .padding(SpacingTokens.xl)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Environment Keys

private struct NavigateToProfileKey: EnvironmentKey {
    static let defaultValue: (@Sendable (UUID) -> Void)? = nil
}

extension EnvironmentValues {
    var navigateToProfile: (@Sendable (UUID) -> Void)? {
        get { self[NavigateToProfileKey.self] }
        set { self[NavigateToProfileKey.self] = newValue }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Search") {
    PreviewDeps.scoped {
        SearchView()
    }
}

#Preview("Search Results") {
    PreviewDeps.scoped {
        let view = SearchView()
        return view
    }
}
#endif
