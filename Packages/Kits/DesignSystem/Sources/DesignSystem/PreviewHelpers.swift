//
//  PreviewHelpers.swift
//  DesignSystem
//
//  Preview helpers specific to DesignSystem components
//

import SwiftUI
import AppFoundation
import Engagement

#if DEBUG
/// Preview helpers for DesignSystem components that need engagement services
@available(iOS 26.0, macOS 15.0, *)
public enum DesignSystemPreviewDeps {
    /// Wrap any view in a DI scope with engagement service for previews
    @ViewBuilder
    public static func withEngagement<V: View>(@ViewBuilder _ content: () -> V) -> some View {
        content()
            .environment(\.deps, Dependencies.test().withEngagement(EngagementServiceFake()))
            .environment(\.colorScheme, .light)
            .environment(\.locale, .init(identifier: "en_US"))
    }
    
    /// Wrap any view with dark mode and engagement service
    @ViewBuilder
    public static func withEngagementDark<V: View>(@ViewBuilder _ content: () -> V) -> some View {
        content()
            .environment(\.deps, Dependencies.test().withEngagement(EngagementServiceFake()))
            .environment(\.colorScheme, .dark)
            .environment(\.locale, .init(identifier: "en_US"))
            .preferredColorScheme(.dark)
    }
}
#endif
