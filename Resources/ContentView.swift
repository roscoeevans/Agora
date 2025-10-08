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

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab - Combined For You and Following feeds
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(0)
            
            // Search Tab - Find users and posts
            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(1)
            
            // DMs Tab - Direct messages
            DMThreadsView()
                .tabItem {
                    Label("Messages", systemImage: "message")
                }
                .tag(2)
            
            // Notifications Tab - Activity and mentions
            NotificationsView()
                .tabItem {
                    Label("Notifications", systemImage: "bell")
                }
                .tag(3)
            
            // Profile Tab - User profile and settings
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
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

#Preview {
    ContentView()
}
