//
//  ContentView.swift
//  Agora
//
//  iOS 26 Navigation - Root tab container with per-tab navigation paths
//

import SwiftUI
import AppFoundation
import Home
import Search
import Notifications
import Profile
import DMs
import PostDetail
import Compose

@available(iOS 26.0, *)
struct ContentView: View {
    // Persisted tab selection
    @SceneStorage("nav.tab.selection") private var selectionRaw: String = AppTab.home.rawValue
    private var selection: Binding<AppTab> {
        Binding(
            get: { AppTab(rawValue: selectionRaw) ?? .home },
            set: { selectionRaw = $0.rawValue }
        )
    }
    
    // Persisted paths (serialized)
    @SceneStorage("nav.path.home") private var homePathData: Data?
    @SceneStorage("nav.path.search") private var searchPathData: Data?
    @SceneStorage("nav.path.notifications") private var notificationsPathData: Data?
    @SceneStorage("nav.path.profile") private var profilePathData: Data?
    
    // Live paths
    @State private var homePath: [HomeRoute] = []
    @State private var searchPath: [SearchRoute] = []
    @State private var notificationsPath: [NotificationsRoute] = []
    @State private var profilePath: [ProfileRoute] = []
    
    // Compose sheet state
    @State private var showingCompose = false
    @State private var previousTab: AppTab = .home
    
    var body: some View {
        tabView
            .sheet(isPresented: $showingCompose, onDismiss: handleComposeDismiss) {
                ComposeView()
            }
            .task {
                homePath = decode(homePathData) ?? []
                searchPath = decode(searchPathData) ?? []
                notificationsPath = decode(notificationsPathData) ?? []
                profilePath = decode(profilePathData) ?? []
            }
            .onChange(of: homePath) { _, newValue in homePathData = encode(newValue) }
            .onChange(of: searchPath) { _, newValue in searchPathData = encode(newValue) }
            .onChange(of: notificationsPath) { _, newValue in notificationsPathData = encode(newValue) }
            .onChange(of: profilePath) { _, newValue in profilePathData = encode(newValue) }
            .onOpenURL(perform: handleDeepLink)
    }
    
    private var tabView: some View {
        TabView(selection: selection) {
            Tab(value: AppTab.home) {
                HomeFlow(path: $homePath)
            } label: {
                Image(systemName: "house.fill")
            }
            
            // iOS 26 search role - provides visual separation and enhanced search UX
            Tab(value: AppTab.search, role: .search) {
                SearchFlow(path: $searchPath)
            }
            
            // Compose tab - shows sheet instead of navigating
            Tab(value: AppTab.compose) {
                Color.clear
            } label: {
                Image(systemName: "square.and.pencil")
                    .fontWeight(.semibold)
                    .environment(\.symbolVariants, .none)
            }
            
            Tab(value: AppTab.notifications) {
                NotificationsFlow(path: $notificationsPath)
            } label: {
                Image(systemName: "bell.fill")
            }
            
            Tab(value: AppTab.profile) {
                ProfileFlow(path: $profilePath)
            } label: {
                Image(systemName: "person.crop.circle")
            }
        }
        .onChange(of: selection.wrappedValue) { oldValue, newValue in
            handleTabSelection(oldValue: oldValue, newValue: newValue)
        }
    }
    
    private func handleTabSelection(oldValue: AppTab, newValue: AppTab) {
        // Show compose sheet when compose tab is tapped
        if newValue == .compose {
            showingCompose = true
        } else {
            // Update previous tab only when switching to non-compose tabs
            previousTab = newValue
        }
    }
    
    private func handleComposeDismiss() {
        // Restore to previous tab when compose sheet is dismissed
        if selection.wrappedValue == .compose {
            selection.wrappedValue = previousTab
        }
    }
    
    private func handleDeepLink(_ url: URL) {
        guard let (tab, newPath): (AppTab, [any Codable]) = DeepLinkRouter.decode(url) else { return }
        selection.wrappedValue = tab
        switch tab {
        case .home:
            homePath = (newPath as? [HomeRoute]) ?? []
        case .search:
            searchPath = (newPath as? [SearchRoute]) ?? []
        case .compose:
            // Open compose sheet for deep link
            showingCompose = true
        case .notifications:
            notificationsPath = (newPath as? [NotificationsRoute]) ?? []
        case .profile:
            profilePath = (newPath as? [ProfileRoute]) ?? []
        }
    }
}

// MARK: - Flow Views

private struct HomeFlow: View {
    @Binding var path: [HomeRoute]
    
    var body: some View {
        NavigationStack(path: $path) {
            HomeView()
                .environment(\.navigateToPost, NavigateToPost { postId in
                    Task { @MainActor in
                        path.append(.post(id: postId))
                    }
                })
                .environment(\.navigateToProfile, NavigateToProfile { profileId in
                    Task { @MainActor in
                        path.append(.profile(id: profileId))
                    }
                })
                .navigationDestination(for: HomeRoute.self) { route in
                    switch route {
                    case .post(let id):
                        PostDetailView(postId: id.uuidString)
                    case .profile(let id):
                        ProfileView(userId: id.uuidString)
                    case .compose(let quotePostId):
                        ComposeView(quotePostId: quotePostId)
                    case .editHistory(let postId, let currentText):
                        EditHistorySheet(postId: postId, currentText: currentText)
                    }
                }
        }
    }
}

private struct SearchFlow: View {
    @Binding var path: [SearchRoute]
    
    var body: some View {
        NavigationStack(path: $path) {
            SearchView()
                .environment(\.navigateToSearchResult, NavigateToSearchResult { resultId in
                    Task { @MainActor in
                        path.append(.result(id: resultId))
                    }
                })
                .navigationDestination(for: SearchRoute.self) { route in
                    switch route {
                    case .result(let id):
                        PostDetailView(postId: id.uuidString)
                    }
                }
        }
    }
}

// MessagesFlow removed - DMs now accessible via HomeView toolbar

private struct NotificationsFlow: View {
    @Binding var path: [NotificationsRoute]
    
    var body: some View {
        NavigationStack(path: $path) {
            NotificationsView()
                .environment(\.navigateToPost, NavigateToPost { postId in
                    // Notifications navigate using the detail route
                    Task { @MainActor in
                        path.append(.detail(id: postId))
                    }
                })
                .navigationDestination(for: NotificationsRoute.self) { route in
                    switch route {
                    case .detail(let id):
                        PostDetailView(postId: id.uuidString)
                    }
                }
        }
    }
}

private struct ProfileFlow: View {
    @Binding var path: [ProfileRoute]
    
    var body: some View {
        NavigationStack(path: $path) {
            ProfileView()
                .navigationDestination(for: ProfileRoute.self) { route in
                    switch route {
                    case .settings:
                        // TODO: Implement settings view
                        Text("Settings")
                            .navigationTitle("Settings")
                    case .followers:
                        // TODO: Implement followers view
                        Text("Followers")
                            .navigationTitle("Followers")
                    }
                }
        }
    }
}

// MARK: - Helpers

private func encode<T: Codable>(_ value: T) -> Data? {
    try? JSONEncoder().encode(value)
}

private func decode<T: Codable>(_ data: Data?) -> T? {
    guard let data else { return nil }
    return try? JSONDecoder().decode(T.self, from: data)
}

#Preview("Default Tab (Home)") {
    ContentView()
        .environment(\.deps, .preview)
}
