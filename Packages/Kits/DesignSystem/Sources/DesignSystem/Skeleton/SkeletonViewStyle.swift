//
//  SkeletonViewStyle.swift
//  DesignSystem
//
//  Created by Agora Team on 2024.
//

import SwiftUI

/// Protocol for styling variants of skeleton components.
///
/// SkeletonViewStyle provides a consistent interface for creating different
/// visual styles of skeleton placeholders while maintaining design system compliance.
@available(iOS 26.0, *)
public protocol SkeletonViewStyle: Sendable {
    /// The type of view that represents the styled skeleton content.
    associatedtype Body: View
    
    /// Creates the styled skeleton view.
    ///
    /// - Parameter configuration: The skeleton configuration containing styling parameters
    /// - Returns: A view representing the styled skeleton content
    func makeBody(configuration: SkeletonStyleConfiguration) -> Body
}

/// Configuration passed to skeleton view styles.
@available(iOS 26.0, *)
public struct SkeletonStyleConfiguration {
    /// Whether the skeleton is currently active/visible
    public let isActive: Bool
    
    /// The content that the skeleton is representing
    public let content: AnyView
    
    /// The skeleton theme containing design tokens
    public let theme: any SkeletonTheme
    
    /// Whether shimmer animation should be enabled
    public let shimmerEnabled: Bool
    
    public init(
        isActive: Bool,
        content: AnyView,
        theme: any SkeletonTheme,
        shimmerEnabled: Bool
    ) {
        self.isActive = isActive
        self.content = content
        self.theme = theme
        self.shimmerEnabled = shimmerEnabled
    }
}

/// Default skeleton view style with redaction and shimmer.
@available(iOS 26.0, *)
public struct DefaultSkeletonViewStyle: SkeletonViewStyle {
    public init() {}
    
    public func makeBody(configuration: SkeletonStyleConfiguration) -> some View {
        Group {
            if configuration.isActive {
                configuration.content
                    .redacted(reason: .placeholder)
                    .overlay(
                        Group {
                            if configuration.shimmerEnabled {
                                ShimmerView(theme: configuration.theme)
                            } else {
                                RoundedRectangle(cornerRadius: configuration.theme.cornerRadii.sm)
                                    .fill(configuration.theme.placeholderColor)
                            }
                        }
                    )
                    .animation(.easeInOut(duration: configuration.theme.crossfadeDuration), value: configuration.isActive)
            } else {
                configuration.content
                    .animation(.easeInOut(duration: configuration.theme.crossfadeDuration), value: configuration.isActive)
            }
        }
    }
}

/// Compact skeleton view style for smaller elements.
@available(iOS 26.0, *)
public struct CompactSkeletonViewStyle: SkeletonViewStyle {
    public init() {}
    
    public func makeBody(configuration: SkeletonStyleConfiguration) -> some View {
        Group {
            if configuration.isActive {
                RoundedRectangle(cornerRadius: configuration.theme.cornerRadii.xs)
                    .fill(configuration.theme.placeholderColor)
                    .overlay(
                        Group {
                            if configuration.shimmerEnabled {
                                ShimmerView(theme: configuration.theme)
                                    .clipShape(RoundedRectangle(cornerRadius: configuration.theme.cornerRadii.xs))
                            }
                        }
                    )
                    .animation(.easeInOut(duration: configuration.theme.crossfadeDuration), value: configuration.isActive)
            } else {
                configuration.content
                    .animation(.easeInOut(duration: configuration.theme.crossfadeDuration), value: configuration.isActive)
            }
        }
    }
}

/// Circular skeleton view style for avatars and circular elements.
@available(iOS 26.0, *)
public struct CircularSkeletonViewStyle: SkeletonViewStyle {
    public init() {}
    
    public func makeBody(configuration: SkeletonStyleConfiguration) -> some View {
        Group {
            if configuration.isActive {
                Circle()
                    .fill(configuration.theme.placeholderColor)
                    .overlay(
                        Group {
                            if configuration.shimmerEnabled {
                                ShimmerView(theme: configuration.theme)
                                    .clipShape(Circle())
                            }
                        }
                    )
                    .animation(.easeInOut(duration: configuration.theme.crossfadeDuration), value: configuration.isActive)
            } else {
                configuration.content
                    .animation(.easeInOut(duration: configuration.theme.crossfadeDuration), value: configuration.isActive)
            }
        }
    }
}

/// Environment key for skeleton view style
@available(iOS 26.0, *)
private struct SkeletonViewStyleKey: EnvironmentKey {
    static let defaultValue: any SkeletonViewStyle = DefaultSkeletonViewStyle()
}

@available(iOS 26.0, *)
public extension EnvironmentValues {
    var skeletonViewStyle: any SkeletonViewStyle {
        get { self[SkeletonViewStyleKey.self] }
        set { self[SkeletonViewStyleKey.self] = newValue }
    }
}

@available(iOS 26.0, *)
public extension View {
    /// Sets the skeleton view style for this view and its children.
    func skeletonViewStyle(_ style: any SkeletonViewStyle) -> some View {
        environment(\.skeletonViewStyle, style)
    }
}