//
//  AgoraApp.swift
//  Agora
//
//  Created by Rocky Evans on 10/7/25.
//

import SwiftUI
import AppFoundation
import DesignSystem

@main
struct AgoraApp: App {
    init() {
        // Initialize app-level services
        setupLogging()
        setupAppearance()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Additional app lifecycle setup can go here
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
        // Configure tab bar for dark mode
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
