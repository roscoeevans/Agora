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
    @SceneStorage("nav.path.messages") private var messagesPathData: Data?
    @SceneStorage("nav.path.notifications") private var notificationsPathData: Data?
    @SceneStorage("nav.path.profile") private var profilePathData: Data?
    
    // Live paths
    @State private var homePath: [HomeRoute] = []
    @State private var searchPath: [SearchRoute] = []
    @State private var messagesPath: [MessagesRoute] = []
    @State private var notificationsPath: [NotificationsRoute] = []
    @State private var profilePath: [ProfileRoute] = []
    
    var body: some View {
        TabView(selection: selection) {
            HomeFlow(path: $homePath)
                .tabItem { Image(systemName: "house.fill") }
                .tag(AppTab.home)
            
            SearchFlow(path: $searchPath)
                .tabItem { Image(systemName: "magnifyingglass") }
                .tag(AppTab.search)
            
            MessagesFlow(path: $messagesPath)
                .tabItem { Image(systemName: "message.fill") }
                .tag(AppTab.messages)
            
            NotificationsFlow(path: $notificationsPath)
                .tabItem { Image(systemName: "bell.fill") }
                .tag(AppTab.notifications)
            
            ProfileFlow(path: $profilePath)
                .tabItem { Image(systemName: "person.crop.circle") }
                .tag(AppTab.profile)
        }
        .task {
            homePath = decode(homePathData) ?? []
            searchPath = decode(searchPathData) ?? []
            messagesPath = decode(messagesPathData) ?? []
            notificationsPath = decode(notificationsPathData) ?? []
            profilePath = decode(profilePathData) ?? []
        }
        .onChange(of: homePath) { _, newValue in homePathData = encode(newValue) }
        .onChange(of: searchPath) { _, newValue in searchPathData = encode(newValue) }
        .onChange(of: messagesPath) { _, newValue in messagesPathData = encode(newValue) }
        .onChange(of: notificationsPath) { _, newValue in notificationsPathData = encode(newValue) }
        .onChange(of: profilePath) { _, newValue in profilePathData = encode(newValue) }
        // Deep links
        .onOpenURL { url in
            guard let (tab, newPath): (AppTab, [any Codable]) = DeepLinkRouter.decode(url) else { return }
            selection.wrappedValue = tab
            switch tab {
            case .home:
                homePath = (newPath as? [HomeRoute]) ?? []
            case .search:
                searchPath = (newPath as? [SearchRoute]) ?? []
            case .messages:
                messagesPath = (newPath as? [MessagesRoute]) ?? []
            case .notifications:
                notificationsPath = (newPath as? [NotificationsRoute]) ?? []
            case .profile:
                profilePath = (newPath as? [ProfileRoute]) ?? []
            }
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
                    path.append(.post(id: postId))
                })
                .environment(\.navigateToProfile, NavigateToProfile { profileId in
                    path.append(.profile(id: profileId))
                })
                .navigationDestination(for: HomeRoute.self) { route in
                    switch route {
                    case .post(let id):
                        PostDetailView(postId: id.uuidString)
                    case .profile(let id):
                        ProfileView(userId: id.uuidString)
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
                    path.append(.result(id: resultId))
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

private struct MessagesFlow: View {
    @Binding var path: [MessagesRoute]
    
    var body: some View {
        NavigationStack(path: $path) {
            DMThreadsView()
                .navigationDestination(for: MessagesRoute.self) { route in
                    switch route {
                    case .thread(let id):
                        // TODO: Implement thread detail view
                        Text("Thread: \(id.uuidString)")
                    }
                }
        }
    }
}

private struct NotificationsFlow: View {
    @Binding var path: [NotificationsRoute]
    
    var body: some View {
        NavigationStack(path: $path) {
            NotificationsView()
                .environment(\.navigateToPost, NavigateToPost { postId in
                    // Notifications navigate using the detail route
                    path.append(.detail(id: postId))
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
