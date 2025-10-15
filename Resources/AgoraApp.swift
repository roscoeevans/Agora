//
//  AgoraApp.swift
//  Agora
//
//  Created by Rocky Evans on 10/7/25.
//

import SwiftUI
import AppFoundation
import DesignSystem
import AuthFeature
import Networking
import Analytics
import Observation

@main
struct AgoraApp: App {
    // MARK: - Composition Root (DI Container)
    // This is where we wire all dependencies once at app startup
    
    private let deps: Dependencies
    @State private var authManager: AuthStateManager
    
    init() {
        // Register networking services first (before any dependencies)
        NetworkingServiceFactory.register()
        
        // Create the Dependencies container with live implementations
        // This is the single place where we wire production dependencies
        let analyticsClient = AnalyticsClientLive()
        
        var baseDeps = Dependencies.production
        baseDeps = baseDeps.withAnalytics(analyticsClient)
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
            let mode = deps.appearance.currentMode
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                for window in windowScene.windows {
                    window.overrideUserInterfaceStyle = mode == .dark ? .dark : .light
                }
            }
        }
    }
    
}
