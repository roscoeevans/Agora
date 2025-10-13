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
        // Configure global app appearance with dark mode as default
        DesignSystem.configureDarkModeAsDefault()
        
        // Configure additional appearance settings
        configureNavigationBarAppearance()
        configureTabBarAppearance()
    }
    
    private func configureNavigationBarAppearance() {
        // Configure navigation bar for dark mode
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.label
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.label
        ]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }
    
    private func configureTabBarAppearance() {
        // Configure tab bar with brand colors
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
        
        // AccentColor is our PRIMARY brand color #FF3466
        // This is the same as AgoraBrand in DesignSystem, but AccentColor is the
        // global iOS accent color that's accessible from UIKit
        let accentColor: UIColor
        if let loadedColor = UIColor(named: "AccentColor") {
            accentColor = loadedColor
        } else {
            // Fallback to PRIMARY brand color #FF3466
            accentColor = UIColor(red: 1.0, green: 0.204, blue: 0.4, alpha: 1.0)
        }
        
        // Set selected tab items to use AccentColor (PRIMARY brand color #FF3466)
        UITabBar.appearance().tintColor = accentColor
        
        // Set unselected items to secondary text color
        UITabBar.appearance().unselectedItemTintColor = UIColor.secondaryLabel
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
    }
}
