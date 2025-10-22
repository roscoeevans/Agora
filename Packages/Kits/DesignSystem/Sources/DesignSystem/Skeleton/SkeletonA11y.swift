//
//  SkeletonA11y.swift
//  DesignSystem
//
//  Created by Agora Team on 2024.
//

import SwiftUI

/// Accessibility helpers for skeleton loading states.
///
/// SkeletonA11y provides utilities for making skeleton loading accessible
/// to users with VoiceOver and other assistive technologies.
@available(iOS 26.0, *)
public struct SkeletonA11y {
    /// Hides skeleton content from accessibility tree.
    ///
    /// This modifier should be applied to skeleton placeholders to prevent
    /// VoiceOver from reading placeholder content.
    ///
    /// - Parameter isActive: Whether the skeleton is currently active
    /// - Returns: A view modifier that manages accessibility visibility
    public static func hiddenFromAccessibility(isActive: Bool) -> some ViewModifier {
        SkeletonAccessibilityModifier(isActive: isActive)
    }
    
    /// Announces loading state to VoiceOver users.
    ///
    /// - Parameter message: The loading message to announce
    /// - Returns: A view modifier that announces the loading state
    public static func loadingAnnouncement(_ message: String = "Loading") -> some ViewModifier {
        LoadingAnnouncementModifier(message: message)
    }
    
    /// Provides skeleton-specific accessibility labels.
    ///
    /// - Parameters:
    ///   - isActive: Whether the skeleton is currently active
    ///   - loadingLabel: Label to use when skeleton is active
    ///   - contentLabel: Label to use when content is loaded
    /// - Returns: A view modifier that manages accessibility labels
    public static func skeletonLabel(
        isActive: Bool,
        loadingLabel: String = "Loading content",
        contentLabel: String? = nil
    ) -> some ViewModifier {
        SkeletonLabelModifier(
            isActive: isActive,
            loadingLabel: loadingLabel,
            contentLabel: contentLabel
        )
    }
}

/// View modifier that hides skeleton content from accessibility tree
@available(iOS 26.0, *)
private struct SkeletonAccessibilityModifier: ViewModifier {
    let isActive: Bool
    
    func body(content: Content) -> some View {
        content
            .accessibilityHidden(isActive)
    }
}

/// View modifier that announces loading state to VoiceOver
@available(iOS 26.0, *)
private struct LoadingAnnouncementModifier: ViewModifier {
    let message: String
    @State private var hasAnnounced = false
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                if !hasAnnounced && voiceOverEnabled {
                    announceLoading()
                    hasAnnounced = true
                }
            }
            .onChange(of: voiceOverEnabled) { _, isEnabled in
                if isEnabled && !hasAnnounced {
                    announceLoading()
                    hasAnnounced = true
                }
            }
    }
    
    private func announceLoading() {
        #if canImport(UIKit)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            UIAccessibility.post(notification: .announcement, argument: message)
        }
        #endif
    }
}

/// View modifier that manages skeleton accessibility labels
@available(iOS 26.0, *)
private struct SkeletonLabelModifier: ViewModifier {
    let isActive: Bool
    let loadingLabel: String
    let contentLabel: String?
    
    func body(content: Content) -> some View {
        content
            .accessibilityLabel(isActive ? loadingLabel : (contentLabel ?? ""))
    }
}

/// View modifier that provides Dynamic Type support for skeleton text elements
@available(iOS 26.0, *)
private struct DynamicTypeSkeletonModifier: ViewModifier {
    let isActive: Bool
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.skeletonTheme) private var theme
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(dynamicTypeScaleFactor)
            .animation(.easeInOut(duration: theme.crossfadeDuration), value: dynamicTypeSize)
    }
    
    private var dynamicTypeScaleFactor: CGFloat {
        guard isActive else { return 1.0 }
        
        switch dynamicTypeSize {
        case .xSmall: return 0.8
        case .small: return 0.9
        case .medium: return 1.0
        case .large: return 1.0
        case .xLarge: return 1.1
        case .xxLarge: return 1.2
        case .xxxLarge: return 1.3
        case .accessibility1: return 1.4
        case .accessibility2: return 1.5
        case .accessibility3: return 1.6
        case .accessibility4: return 1.7
        case .accessibility5: return 1.8
        @unknown default: return 1.0
        }
    }
}

/// View modifier that provides comprehensive accessibility support for skeleton containers
@available(iOS 26.0, *)
private struct SkeletonContainerAccessibilityModifier: ViewModifier {
    let isLoading: Bool
    let loadingMessage: String
    let loadedMessage: String
    
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    @State private var hasAnnouncedLoading = false
    @State private var hasAnnouncedLoaded = false
    
    func body(content: Content) -> some View {
        content
            .accessibilityElement(children: .contain)
            .accessibilityLabel(isLoading ? loadingMessage : loadedMessage)
            .accessibilityAddTraits(isLoading ? .updatesFrequently : [])
            .onAppear {
                if isLoading && voiceOverEnabled && !hasAnnouncedLoading {
                    announceState(loadingMessage)
                    hasAnnouncedLoading = true
                }
            }
            .onChange(of: isLoading) { _, newIsLoading in
                if voiceOverEnabled {
                    if newIsLoading && !hasAnnouncedLoading {
                        announceState(loadingMessage)
                        hasAnnouncedLoading = true
                        hasAnnouncedLoaded = false
                    } else if !newIsLoading && !hasAnnouncedLoaded {
                        announceState(loadedMessage)
                        hasAnnouncedLoaded = true
                        hasAnnouncedLoading = false
                    }
                }
            }
    }
    
    private func announceState(_ message: String) {
        #if canImport(UIKit)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            UIAccessibility.post(notification: .announcement, argument: message)
        }
        #endif
    }
}

@available(iOS 26.0, *)
public extension View {
    /// Hides this view from accessibility when skeleton is active.
    ///
    /// Use this modifier on skeleton placeholders to prevent VoiceOver
    /// from reading placeholder content.
    ///
    /// - Parameter isActive: Whether the skeleton is currently active
    /// - Returns: A view with accessibility visibility managed based on skeleton state
    func skeletonAccessibilityHidden(_ isActive: Bool) -> some View {
        modifier(SkeletonA11y.hiddenFromAccessibility(isActive: isActive))
    }
    
    /// Announces loading state to VoiceOver users.
    ///
    /// Use this modifier on containers that show skeleton loading to inform
    /// VoiceOver users that content is loading.
    ///
    /// - Parameter message: The loading message to announce (defaults to "Loading")
    /// - Returns: A view that announces loading state to assistive technologies
    func skeletonLoadingAnnouncement(_ message: String = "Loading") -> some View {
        modifier(SkeletonA11y.loadingAnnouncement(message))
    }
    
    /// Provides skeleton-specific accessibility labels.
    ///
    /// Use this modifier to provide appropriate labels for skeleton states
    /// and loaded content states.
    ///
    /// - Parameters:
    ///   - isActive: Whether the skeleton is currently active
    ///   - loadingLabel: Label to use when skeleton is active
    ///   - contentLabel: Label to use when content is loaded
    /// - Returns: A view with appropriate accessibility labels for skeleton states
    func skeletonAccessibilityLabel(
        isActive: Bool,
        loadingLabel: String = "Loading content",
        contentLabel: String? = nil
    ) -> some View {
        modifier(SkeletonA11y.skeletonLabel(
            isActive: isActive,
            loadingLabel: loadingLabel,
            contentLabel: contentLabel
        ))
    }
    
    /// Adds Dynamic Type support for skeleton text elements.
    ///
    /// This modifier ensures skeleton placeholders scale appropriately with
    /// the user's preferred text size, including accessibility sizes.
    ///
    /// - Parameter isActive: Whether the skeleton is currently active
    /// - Returns: A view that scales skeleton elements based on Dynamic Type settings
    func skeletonDynamicType(isActive: Bool) -> some View {
        modifier(DynamicTypeSkeletonModifier(isActive: isActive))
    }
    
    /// Provides comprehensive accessibility support for skeleton containers.
    ///
    /// This modifier handles VoiceOver announcements, accessibility labels,
    /// and traits for containers that display skeleton loading states.
    ///
    /// - Parameters:
    ///   - isLoading: Whether the container is currently loading
    ///   - loadingMessage: Message to announce when loading starts
    ///   - loadedMessage: Message to announce when loading completes
    /// - Returns: A view with comprehensive accessibility support for skeleton states
    func skeletonContainerAccessibility(
        isLoading: Bool,
        loadingMessage: String = "Loading content",
        loadedMessage: String = "Content loaded"
    ) -> some View {
        modifier(SkeletonContainerAccessibilityModifier(
            isLoading: isLoading,
            loadingMessage: loadingMessage,
            loadedMessage: loadedMessage
        ))
    }
}

#if DEBUG
@available(iOS 26.0, *)
struct SkeletonA11y_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: SpacingTokens.md) {
            // Example skeleton with accessibility
            RoundedRectangle(cornerRadius: BorderRadiusTokens.sm)
                .fill(ColorTokens.separator.opacity(0.3))
                .frame(height: 20)
                .skeletonAccessibilityHidden(true)
                .skeletonAccessibilityLabel(
                    isActive: true,
                    loadingLabel: "Loading post content"
                )
            
            // Example loaded content
            Text("This is the actual content")
                .font(TypographyScale.body)
                .skeletonAccessibilityHidden(false)
                .skeletonAccessibilityLabel(
                    isActive: false,
                    contentLabel: "Post content loaded"
                )
            
            // Container with loading announcement
            VStack {
                Text("Feed Container")
                    .font(TypographyScale.headline)
            }
            .skeletonLoadingAnnouncement("Loading your feed")
        }
        .padding(SpacingTokens.lg)
        .background(ColorTokens.background)
        .previewDisplayName("Accessibility Examples")
    }
}
#endif