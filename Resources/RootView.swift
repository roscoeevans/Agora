//
//  RootView.swift
//  Agora
//
//  Created by AI on 10/12/25.
//

import SwiftUI
import AuthFeature
import Observation

/// Root view that handles authentication-gated routing
/// Shows different views based on authentication state
struct RootView: View {
    @Environment(AuthStateManager.self) private var authManager
    
    var body: some View {
        Group {
            switch authManager.state {
            case .initializing:
                ZStack {
                    Color.black
                        .ignoresSafeArea()
                    ProgressView()
                        .controlSize(.large)
                        .tint(.white)
                }
                .transition(.opacity)
                
            case .unauthenticated:
                WelcomeView()
                    .transition(.opacity)
                
            case .authenticatedNoProfile:
                OnboardingView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                
            case .authenticated:
                ContentView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authManager.state)
    }
}

#Preview("Initializing") {
    RootView()
        .environment({
            let manager = AuthStateManager()
            return manager
        }())
}

#Preview("Unauthenticated") {
    RootView()
        .environment({
            AuthStateManager()
            // Note: Can't set state directly in preview as setter is private
            // This preview will show initializing state
        }())
}

