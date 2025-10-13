//
//  ContentView.swift
//  Agora
//
//  Created by Rocky Evans on 10/7/25.
//

import SwiftUI
import Home
import Search
import Notifications
import Profile
import DMs
import DesignSystem
import AppFoundation

struct ContentView: View {
    @Environment(\.deps) private var deps
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab - Combined For You and Following feeds
            HomeView()
                .tabItem {
                    Image(systemName: "house")
                        .accessibilityLabel("Home")
                }
                .tag(0)
            
            // Search Tab - Find users and posts
            SearchView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                        .accessibilityLabel("Search")
                }
                .tag(1)
            
            // DMs Tab - Direct messages
            DMThreadsView()
                .tabItem {
                    Image(systemName: "message")
                        .accessibilityLabel("Messages")
                }
                .tag(2)
            
            // Notifications Tab - Activity and mentions
            NotificationsView()
                .tabItem {
                    Image(systemName: "bell")
                        .accessibilityLabel("Notifications")
                }
                .tag(3)
            
            // Profile Tab - User profile and settings
            ProfileView()
                .tabItem {
                    Image(systemName: "person.circle")
                        .accessibilityLabel("Profile")
                }
                .tag(4)
        }
        .accentColor(ColorTokens.primary) // Use design system primary color
        .background(ColorTokens.background) // Use design system background color
        .preferredColorScheme(.dark) // Default to dark mode
        .environment(\.isDarkMode, true) // Set dark mode environment
        .liquidGlass(.tabBar) // Use design system Liquid Glass effect for tab bar
        .onAppear {
            // Configure dark mode as default using design system
            DesignSystem.configureDarkModeAsDefault()
        }
    }
}

#Preview("Default Tab (Home)") {
    ContentView()
        .environment(\.deps, .preview)
        .preferredColorScheme(.dark)
}
