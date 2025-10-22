//
//  OnboardingCarouselView.swift
//  Onboarding
//
//  Full-screen onboarding carousel with swipeable pages
//

import SwiftUI
import DesignSystem

/// Full-screen onboarding carousel with swipeable pages, pagination dots, and navigation buttons
public struct OnboardingCarouselView: View {
    @State private var currentPage: Int = 0
    @State private var dragOffset: CGFloat = 0
    
    let onComplete: () -> Void
    
    private let pages = OnboardingPage.pages
    
    public init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
    }
    
    public var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Pages
                TabView(selection: $currentPage) {
                    ForEach(pages) { page in
                        OnboardingPageView(page: page)
                            .tag(page.id)
                    }
                }
                #if os(iOS)
                .tabViewStyle(.page(indexDisplayMode: .never))
                #endif
                .animation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.2), value: currentPage)
                .sensoryFeedback(.selection, trigger: currentPage)
                
                // Bottom controls
                VStack(spacing: 24) {
                    // Pagination dots
                    HStack(spacing: 8) {
                        ForEach(pages) { page in
                            Circle()
                                .fill(currentPage == page.id ? Color.accentColor : Color.secondary.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0.1), value: currentPage)
                        }
                    }
                    .padding(.bottom, 8)
                    
                    // Next/Get Started button
                    HStack {
                        Spacer()
                        
                        Button {
                            handleNextTapped()
                        } label: {
                            Text(isLastPage ? "Get Started" : "Next")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: isLastPage ? 160 : 100, height: 50)
                                .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 25))
                                .contentShape(RoundedRectangle(cornerRadius: 25))
                                .scaleEffect(isLastPage ? 1.05 : 1.0)
                        }
                        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.7), trigger: currentPage)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0.2), value: isLastPage)
                        
                        Spacer()
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
    }
    
    // MARK: - Helpers
    
    private var isLastPage: Bool {
        currentPage == pages.count - 1
    }
    
    private func handleNextTapped() {
        if isLastPage {
            // Complete onboarding
            onComplete()
        } else {
            // Go to next page with coordinated animation
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.2)) {
                currentPage += 1
            }
        }
    }
}

#if DEBUG && canImport(SwiftUI)
import AppFoundation

#Preview("Onboarding Carousel - Light") {
    PreviewDeps.scoped {
        OnboardingCarouselView {
            print("Onboarding completed")
        }
    }
    .preferredColorScheme(.light)
}

#Preview("Onboarding Carousel - Dark") {
    PreviewDeps.scoped {
        OnboardingCarouselView {
            print("Onboarding completed")
        }
    }
    .preferredColorScheme(.dark)
}
#endif

