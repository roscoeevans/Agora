//
//  AgoraApp.swift
//  Agora
//
//  Created by Rocky Evans on 10/7/25.
//

import SwiftUI
import AppFoundation
import DesignSystem
import Authentication
import Networking
import Analytics
import Engagement
import PostDetail
import SupabaseKit
import Observation

@main
struct AgoraApp: App {
    // MARK: - Composition Root (DI Container)
    // This is where we wire all dependencies once at app startup
    
    private let deps: Dependencies
    @State private var authManager: AuthStateManager
    
    init() {
        #if DEBUG
        // Skip heavy initialization in Xcode Previews for faster refresh
        if ProcessInfo.processInfo.isXcodePreviews {
            // Use lightweight test dependencies for previews
            self.deps = Dependencies.test()
            let authMgr = AuthStateManager(
                authService: deps.auth,
                apiClient: deps.networking,
                storageService: nil
            )
            _authManager = State(initialValue: authMgr)
            print("🎨 Agora app initialized with preview dependencies")
            return
        }
        #endif
        
        // Register networking services first (before any dependencies)
        NetworkingServiceFactory.register()
        
        // Create the Dependencies container with live implementations
        // This is the single place where we wire production dependencies
        let analyticsClient = AnalyticsClientLive()
        
        var baseDeps = Dependencies.production
        baseDeps = baseDeps.withAnalytics(analyticsClient)
        
        // Wire up Supabase client for realtime and direct database access
        let supabaseURL = AppConfig.supabaseURL.absoluteString
        let supabaseKey = AppConfig.supabaseAnonKey
        let supabaseClient = SupabaseClientLive(url: supabaseURL, key: supabaseKey)
        baseDeps = baseDeps.withSupabase(supabaseClient)
        
        // Wire up engagement service
        // Supabase Functions URL: https://[project-id].supabase.co/functions/v1
        let functionsURL = AppConfig.supabaseURL.appendingPathComponent("functions").appendingPathComponent("v1")
        let engagementService = EngagementServiceLive(
            baseURL: functionsURL,
            authTokenProvider: { [auth = baseDeps.auth] in
                try? await auth.currentAccessToken()
            },
            session: .shared
        )
        baseDeps = baseDeps.withEngagement(engagementService)
        
        // Wire up comment composition service
        let commentCompositionService = CommentCompositionService()
        baseDeps = baseDeps.withCommentComposition(commentCompositionService)
        
        self.deps = baseDeps
        
        // Create auth manager with dependencies from container
        let authMgr = AuthStateManager(
            authService: baseDeps.auth,
            apiClient: baseDeps.networking,
            storageService: nil  // Uses default
        )
        _authManager = State(initialValue: authMgr)
        
        // Setup logging and appearance after all properties are initialized
        setupLogging()
        setupAppearance()
        
        print("🚀 Agora app initialized with DI container")
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.deps, deps)  // Inject dependencies into environment
                .environment(authManager)
                .task {
                    await authManager.checkAuthState()
                }
        }
    }
    
    private func setupLogging() {
        // Initialize structured logging
        Logger.ui.info("Agora app starting up")
    }
    
    private func setupAppearance() {
        // Apply saved appearance preference on launch
        Task { @MainActor in
            let mode = deps.appearance.effectiveMode
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                for window in windowScene.windows {
                    switch mode {
                    case .light:
                        window.overrideUserInterfaceStyle = .light
                    case .dark:
                        window.overrideUserInterfaceStyle = .dark
                    case .system:
                        window.overrideUserInterfaceStyle = .unspecified
                    }
                }
            }
        }
    }
    
}
