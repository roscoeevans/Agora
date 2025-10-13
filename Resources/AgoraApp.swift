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
import Observation

@main
struct AgoraApp: App {
    @State private var authManager: AuthStateManager
    
    init() {
        // Register networking services FIRST, before creating any managers
        NetworkingServiceFactory.register()
        
        // Now safe to create auth manager (which needs API client)
        _authManager = State(initialValue: AuthStateManager())
        
        // Initialize other app-level services
        setupLogging()
        setupAppearance()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
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
        // Let tab bar use default iOS behavior for proper background rendering
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
}
