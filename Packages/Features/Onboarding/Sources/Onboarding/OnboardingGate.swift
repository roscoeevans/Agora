//
//  OnboardingGate.swift
//  Onboarding
//
//  Gate that shows onboarding or child content based on completion status
//

import SwiftUI
import AppFoundation

/// Gate that shows onboarding on first launch, then shows child content
public struct OnboardingGate<Content: View>: View {
    @AppStorage("onboarding.completed.version") private var completedVersion: Int = 0
    @State private var showOnboarding: Bool = false
    
    let content: () -> Content
    
    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    public var body: some View {
        Group {
            if shouldShowOnboarding {
                OnboardingCarouselView {
                    handleOnboardingComplete()
                }
                .transition(.opacity)
            } else {
                content()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: showOnboarding)
        .onAppear {
            checkOnboardingStatus()
        }
    }
    
    // MARK: - Helpers
    
    private var shouldShowOnboarding: Bool {
        showOnboarding
    }
    
    private func checkOnboardingStatus() {
        // completedVersion is 0 for first launch, then set to currentVersion after completion
        let needsOnboarding = completedVersion < OnboardingModule.currentVersion
        
        if needsOnboarding {
            // Small delay for smoother initial presentation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    showOnboarding = true
                }
            }
        }
    }
    
    private func handleOnboardingComplete() {
        // Mark onboarding as complete
        completedVersion = OnboardingModule.currentVersion
        
        // Track analytics (if needed in future)
        // deps.analytics.track("onboarding_completed", ["version": OnboardingModule.currentVersion])
        
        // Dismiss onboarding
        withAnimation {
            showOnboarding = false
        }
    }
}

#if DEBUG && canImport(SwiftUI)
#Preview("Gate - Needs Onboarding") {
    PreviewDeps.scoped {
        OnboardingGate {
            Text("Main App Content")
                .font(.largeTitle)
        }
    }
}

#Preview("Gate - Completed") {
    struct PreviewWrapper: View {
        @AppStorage("onboarding.completed.version") private var completedVersion: Int = OnboardingModule.currentVersion
        
        var body: some View {
            OnboardingGate {
                VStack(spacing: 20) {
                    Text("Main App Content")
                        .font(.largeTitle)
                    
                    Button("Reset Onboarding") {
                        completedVersion = 0
                    }
                }
            }
        }
    }
    
    return PreviewDeps.scoped {
        PreviewWrapper()
    }
}
#endif

