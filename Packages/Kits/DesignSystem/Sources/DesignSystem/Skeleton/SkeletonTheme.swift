//
//  SkeletonTheme.swift
//  DesignSystem
//
//  Created by Agora Team on 2024.
//

import SwiftUI

/// Protocol for skeleton theming that bridges existing DesignSystem tokens.
///
/// SkeletonTheme provides a consistent interface for skeleton styling
/// while integrating with the existing design system tokens.
@available(iOS 26.0, *)
public protocol SkeletonTheme: Sendable {
    // MARK: - Color Management (bridges existing DesignSystem tokens)
    
    /// Background color for skeleton placeholders
    var backgroundColor: Color { get }
    
    /// Placeholder color for skeleton elements
    var placeholderColor: Color { get }
    
    /// Shimmer gradient for animation effect
    var shimmerGradient: LinearGradient { get }
    
    // MARK: - Animation Parameters
    
    /// Duration of shimmer animation (default: 1.5s)
    var shimmerDuration: TimeInterval { get }
    
    /// Duration of crossfade animation (default: 300ms)
    var crossfadeDuration: TimeInterval { get }
    
    /// Stagger delay between skeleton rows (default: 50ms)
    var staggerDelay: TimeInterval { get }
    
    // MARK: - Geometry Tokens (wraps existing DesignSystem tokens)
    
    /// Avatar sizes for different contexts
    var avatarSizes: (sm: CGFloat, md: CGFloat, lg: CGFloat) { get }
    
    /// Spacing scale from DesignSystem
    var spacingScale: SpacingTokens.Type { get }
    
    /// Corner radii from DesignSystem
    var cornerRadii: BorderRadiusTokens.Type { get }
    
    /// Typography scale from DesignSystem
    var typography: TypographyScale.Type { get }
}

/// Default implementation of SkeletonTheme using DesignSystem tokens.
@available(iOS 26.0, *)
public struct DefaultSkeletonTheme: SkeletonTheme {
    public init() {}
    
    // MARK: - Color Management
    
    public var backgroundColor: Color {
        ColorTokens.background
    }
    
    public var placeholderColor: Color {
        ColorTokens.separator.opacity(0.3)
    }
    
    public var shimmerGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: placeholderColor.opacity(0.3), location: 0.0),
                .init(color: placeholderColor.opacity(0.8), location: 0.5),
                .init(color: placeholderColor.opacity(0.3), location: 1.0)
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    // MARK: - Animation Parameters
    
    public var shimmerDuration: TimeInterval {
        1.5
    }
    
    public var crossfadeDuration: TimeInterval {
        0.3
    }
    
    public var staggerDelay: TimeInterval {
        0.05
    }
    
    // MARK: - Geometry Tokens
    
    public var avatarSizes: (sm: CGFloat, md: CGFloat, lg: CGFloat) {
        (sm: 32, md: 40, lg: 80)
    }
    
    public var spacingScale: SpacingTokens.Type {
        SpacingTokens.self
    }
    
    public var cornerRadii: BorderRadiusTokens.Type {
        BorderRadiusTokens.self
    }
    
    public var typography: TypographyScale.Type {
        TypographyScale.self
    }
}

/// Environment key for skeleton theme
@available(iOS 26.0, *)
private struct SkeletonThemeKey: EnvironmentKey {
    static let defaultValue: any SkeletonTheme = DefaultSkeletonTheme()
}

@available(iOS 26.0, *)
public extension EnvironmentValues {
    var skeletonTheme: any SkeletonTheme {
        get { self[SkeletonThemeKey.self] }
        set { self[SkeletonThemeKey.self] = newValue }
    }
}

@available(iOS 26.0, *)
public extension View {
    /// Sets the skeleton theme for this view and its children.
    func skeletonTheme(_ theme: any SkeletonTheme) -> some View {
        environment(\.skeletonTheme, theme)
    }
}