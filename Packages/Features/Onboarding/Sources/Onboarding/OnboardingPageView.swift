//
//  OnboardingPageView.swift
//  Onboarding
//
//  Individual page view for onboarding carousel
//

import SwiftUI
import DesignSystem

/// Displays a single onboarding page with icon, title, and body text
struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Top: Icon
            Image(systemName: page.symbolName)
                .font(.system(size: 80, weight: .light))
                .foregroundStyle(page.accentColor.gradient)
                .symbolEffect(.pulse.byLayer, options: .speed(0.5).repeat(3))
                .padding(.bottom, 40)
            
            // Middle: Content
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 32)
                
                Text(page.body)
                    .font(.system(size: 17, weight: .regular))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 40)
                    .lineSpacing(4)
            }
            
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#if DEBUG && canImport(SwiftUI)
import AppFoundation

#Preview("Welcome - Light") {
    OnboardingPageView(page: OnboardingPage.pages[0])
        .preferredColorScheme(.light)
}

#Preview("Welcome - Dark") {
    OnboardingPageView(page: OnboardingPage.pages[0])
        .preferredColorScheme(.dark)
}

#Preview("Humanity First - Light") {
    OnboardingPageView(page: OnboardingPage.pages[1])
        .preferredColorScheme(.light)
}

#Preview("Humanity First - Dark") {
    OnboardingPageView(page: OnboardingPage.pages[1])
        .preferredColorScheme(.dark)
}

#Preview("Self-Destruct - Light") {
    OnboardingPageView(page: OnboardingPage.pages[2])
        .preferredColorScheme(.light)
}

#Preview("Self-Destruct - Dark") {
    OnboardingPageView(page: OnboardingPage.pages[2])
        .preferredColorScheme(.dark)
}

#Preview("Feed - Light") {
    OnboardingPageView(page: OnboardingPage.pages[3])
        .preferredColorScheme(.light)
}

#Preview("Feed - Dark") {
    OnboardingPageView(page: OnboardingPage.pages[3])
        .preferredColorScheme(.dark)
}
#endif

