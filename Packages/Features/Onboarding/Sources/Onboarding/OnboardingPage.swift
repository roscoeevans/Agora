//
//  OnboardingPage.swift
//  Onboarding
//
//  Model representing each onboarding page
//

import SwiftUI

/// Represents a single page in the onboarding carousel
struct OnboardingPage: Identifiable, Equatable {
    let id: Int
    let symbolName: String
    let title: String
    let body: String
    let accentColor: Color
    
    /// All onboarding pages in order
    static let pages: [OnboardingPage] = [
        OnboardingPage(
            id: 0,
            symbolName: "sparkles",
            title: "Welcome to Agora",
            body: "A space for genuine human connection and thoughtful conversation.",
            accentColor: .purple
        ),
        OnboardingPage(
            id: 1,
            symbolName: "person.fill.checkmark",
            title: "Humanity First",
            body: "Absolutely no AI-generated content allowed. Every voice here is real.",
            accentColor: .blue
        ),
        OnboardingPage(
            id: 2,
            symbolName: "timer",
            title: "Posts That Self-Destruct",
            body: "Choose when your posts disappear—24 hours, 3 days, or a week. Share freely.",
            accentColor: .orange
        ),
        OnboardingPage(
            id: 3,
            symbolName: "chart.line.uptrend.xyaxis",
            title: "Your Feed, Your Way",
            body: "Discover new perspectives with a personalized For You feed, or keep it classic with a chronological Following feed.",
            accentColor: .green
        )
    ]
}

