//
//  ContentView.swift
//  Agora
//
//  iOS 26 Navigation - Root tab container with per-tab navigation paths
//

import SwiftUI
import AppFoundation
import DesignSystem
import HomeForYou
import HomeFollowing
import Search
import Notifications
import Profile
import DirectMessages
import PostDetail
import Compose
import Authentication

@available(iOS 26.0, *)
struct ContentView: View {
    // Tab selection - resets to home on every launch
    @State private var selectionRaw: String = AppTab.home.rawValue
    private var selection: Binding<AppTab> {
        Binding(
            get: { AppTab(rawValue: selectionRaw) ?? .home },
            set: { selectionRaw = $0.rawValue }
        )
    }
    
    // Navigation paths - reset on every launch
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
        .tabBarMinimizeBehavior(.onScrollDown)
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
        case .messages:
            // Messages are now accessed via toolbar button, not deep links
            break
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
    @State private var selectedFeed: HomeFeedType = .following
    @State private var showingFeedSettings = false
    @State private var showingCompose = false
    
    // ========================================
    // HARDCODED FEED TOGGLE
    // ========================================
    // To switch between feeds, change the value below:
    // .following = Following feed (chronological)
    // .forYou = Recommended feed (algorithmic)
    // ========================================
    private let defaultFeed: HomeFeedType = .following
    
    var body: some View {
        NavigationStack(path: $path) {
            Group {
                switch selectedFeed {
                case .forYou:
                    HomeForYouView(onComposeAction: {
                        showingCompose = true
                    })
                case .following:
                    HomeFollowingView(onComposeAction: {
                        showingCompose = true
                    })
                }
            }
            .navigationTitle("αgorα")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingFeedSettings = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                    .accessibilityLabel("Feed settings")
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        path.append(.directMessages)
                    } label: {
                        Image(systemName: "message.fill")
                    }
                    .accessibilityLabel("Direct Messages")
                }
            }
            .sheet(isPresented: $showingFeedSettings) {
                FeedSettingsView(selectedFeed: $selectedFeed)
            }
            .sheet(isPresented: $showingCompose) {
                ComposeView()
            }
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
                    PostDetailScreen(postId: id.uuidString)
                case .profile(let id):
                    ProfileView(userId: id.uuidString)
                case .compose(let quotePostId):
                    ComposeView(quotePostId: quotePostId)
                case .editHistory(let postId, let currentText):
                    EditHistorySheet(postId: postId, currentText: currentText)
                case .fullscreenVideo(let bundleId, let videoUrl):
                    FullscreenVideoPlayer(videoUrl: videoUrl, bundleId: bundleId)
                case .imageGallery(let urls, let initialIndex):
                    ImageGalleryView(imageUrls: urls, initialIndex: initialIndex)
                case .directMessages:
                    DirectMessagesView()
                        .environment(\.navigateToConversation, NavigateToConversation { conversationId in
                            Task { @MainActor in
                                path.append(.conversation(id: conversationId))
                            }
                        })
                case .conversation(let id):
                    ConversationView(conversationId: id)
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
                        PostDetailScreen(postId: id.uuidString)
                    }
                }
        }
    }
}

private struct MessagesFlow: View {
    @Binding var path: [DMsRoute]
    
    var body: some View {
        NavigationStack(path: $path) {
            DMsEntry(route: .list)
                .navigationDestination(for: DMsRoute.self) { route in
                    switch route {
                    case .list:
                        DMsEntry(route: .list)
                    case .conversation(let id):
                        DMsEntry(route: .conversation(id: id))
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
                    Task { @MainActor in
                        path.append(.detail(id: postId))
                    }
                })
                .navigationDestination(for: NotificationsRoute.self) { route in
                    switch route {
                    case .detail(let id):
                        PostDetailScreen(postId: id.uuidString)
                    }
                }
        }
    }
}

private struct ProfileFlow: View {
    @Binding var path: [ProfileRoute]
    @Environment(\.deps) private var deps
    @Environment(AuthStateManager.self) private var authManager
    
    var body: some View {
        NavigationStack(path: $path) {
            ProfileView()
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
                .environment(\.navigateToEditProfile, NavigateToEditProfile {
                    Task { @MainActor in
                        path.append(.editProfile)
                    }
                })
                .navigationDestination(for: ProfileRoute.self) { route in
                    switch route {
                    case .settings:
                        SettingsView()
                    case .editProfile:
                        if let currentUser = authManager.state.currentUser {
                            EditProfileView(
                                profile: UserProfile(
                                    id: currentUser.id,
                                    handle: currentUser.handle,
                                    displayName: currentUser.displayName,
                                    bio: currentUser.bio ?? "",
                                    avatarUrl: currentUser.avatarUrl,
                                    postCount: 0,
                                    followingCount: 0,
                                    followerCount: 0,
                                    isCurrentUser: true,
                                    isFollowing: false
                                ),
                                userId: currentUser.id,
                                networking: deps.networking
                            )
                        } else {
                            Text("Profile not available")
                        }
                    case .followers:
                        // TODO: Implement followers view
                        Text("Followers")
                            .navigationTitle("Followers")
                    case .post(let id):
                        PostDetailScreen(postId: id.uuidString)
                    case .profile(let id):
                        ProfileView(userId: id.uuidString)
                    }
                }
        }
    }
}

// MARK: - Home Feed Types

private enum HomeFeedType: String, CaseIterable {
    case forYou = "forYou"
    case following = "following"
    
    var selectionLabel: String {
        switch self {
        case .forYou:
            return "Recommended"
        case .following:
            return "Following"
        }
    }
}

private struct FeedSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedFeed: HomeFeedType
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(HomeFeedType.allCases, id: \.self) { feedType in
                        Button {
                            selectedFeed = feedType
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(feedType.selectionLabel)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    
                                    Text(feedType == .forYou ? "Personalized recommendations" : "Posts from people you follow")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if selectedFeed == feedType {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Feed Type")
                }
                
                Section {
                    Text("More feed settings coming soon...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } header: {
                    Text("Additional Settings")
                }
            }
            .navigationTitle("Feed Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                    }
                }
            }
        }
    }
}

#if DEBUG
@available(iOS 26.0, *)
#Preview("Default Tab (Home)") {
    PreviewDeps.scoped {
        ContentView()
    }
}
#endif
