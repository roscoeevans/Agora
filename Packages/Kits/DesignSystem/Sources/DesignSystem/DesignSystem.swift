//
//  DesignSystem.swift
//  Agora
//
//  Created by Agora Team on 2024.
//

import SwiftUI
import UIKitBridge
import AppFoundation

#if canImport(UIKit)
import UIKit
#endif

/// The main entry point for Agora's design system.
///
/// DesignSystem provides access to design tokens, components, and utilities
/// that ensure visual consistency across the Agora iOS app.
@available(iOS 26.0, *)
public struct DesignSystem: Sendable {
    /// Shared instance of the design system.
    public static let shared = DesignSystem()
    
    private init() {}
    
    // MARK: - Design System Configuration
    
    /// Note: Dark mode configuration utilities have been moved to UIKitBridge
    /// Use `UIKitBridge.DesignSystemBridge` for UIKit-specific appearance configuration
}

// MARK: - Appearance Integration

/// Environment key for accessing appearance preferences in design system components
@available(iOS 26.0, *)
private struct AppearancePreferenceKey: EnvironmentKey {
    static let defaultValue: AppearancePreference = AppearancePreferenceLive()
}

@available(iOS 26.0, *)
public extension EnvironmentValues {
    var appearancePreference: AppearancePreference {
        get { self[AppearancePreferenceKey.self] }
        set { self[AppearancePreferenceKey.self] = newValue }
    }
}

// MARK: - ColorTokens

/// Color tokens for the Agora design system.
///
/// All colors automatically adapt to light and dark modes and support
/// accessibility features like increased contrast.
@available(iOS 26.0, *)
public struct ColorTokens: Sendable {
    // MARK: - Primary Colors
    
    /// Primary brand color used for key interactive elements (Sky Blue).
    public static let primary = Color.accentColor
    
    /// Secondary brand color used for highlights and secondary actions (Rosy Magenta).
    public static let secondary = Color("AgoraAccent", bundle: .module)
    
    /// Variant of the primary color for secondary brand elements.
    public static let primaryVariant = Color("AgoraBrand", bundle: .module)
    
    // MARK: - System Colors (Adaptive for Dark Mode)
    // SwiftUI with UIKit semantic colors (platform-guarded)
    #if canImport(UIKit)
    public static let background = Color(uiColor: .systemBackground)
    public static let secondaryBackground = Color(uiColor: .secondarySystemBackground)
    public static let tertiaryBackground = Color(uiColor: .tertiarySystemBackground)
    public static let groupedBackground = Color(uiColor: .systemGroupedBackground)
    #else
    public static let background = Color(nsColor: .windowBackgroundColor)
    public static let secondaryBackground = Color(nsColor: .controlBackgroundColor)
    public static let tertiaryBackground = Color(nsColor: .controlBackgroundColor)
    public static let groupedBackground = Color(nsColor: .windowBackgroundColor)
    #endif
    
    // MARK: - Text Colors (Adaptive for Dark Mode)
    #if canImport(UIKit)
    public static let primaryText = Color(uiColor: .label)
    public static let secondaryText = Color(uiColor: .secondaryLabel)
    public static let tertiaryText = Color(uiColor: .tertiaryLabel)
    public static let quaternaryText = Color(uiColor: .quaternaryLabel)
    #else
    public static let primaryText = Color(nsColor: .labelColor)
    public static let secondaryText = Color(nsColor: .secondaryLabelColor)
    public static let tertiaryText = Color(nsColor: .tertiaryLabelColor)
    public static let quaternaryText = Color(nsColor: .quaternaryLabelColor)
    #endif
    
    // MARK: - Interactive Colors (Adaptive for Dark Mode)
    public static let link = Color("AgoraBrand", bundle: .module)
    #if canImport(UIKit)
    public static let separator = Color(uiColor: .separator)
    public static let opaqueSeparator = Color(uiColor: .opaqueSeparator)
    #else
    public static let separator = Color(nsColor: .separatorColor)
    public static let opaqueSeparator = Color(nsColor: .separatorColor)
    #endif
    
    // MARK: - Status Colors (Adaptive for Dark Mode)
    public static let success = DesignSystemBridge.systemGreen
    public static let warning = DesignSystemBridge.systemOrange
    public static let error = DesignSystemBridge.systemRed
    public static let info = Color("AgoraTertiary", bundle: .module)
    
    // MARK: - Error Background Colors
    public static let errorBackground = Color.red.opacity(0.1)
    
    // MARK: - App-Specific Colors (Adaptive for Dark Mode)
    public static let accentPrimary = Color("AgoraAccent", bundle: .module)
    #if canImport(UIKit)
    public static let agoraSurface = Color(uiColor: .secondarySystemBackground)
    #else
    public static let agoraSurface = Color(nsColor: .controlBackgroundColor)
    #endif
    
    // MARK: - Brand Colors (with Dark Mode variants)
    // These use custom colors from bundle resources with proper dark mode support
    public static let agoraBrand = Color("AgoraBrand", bundle: .module)
    public static let agoraAccent = Color("AgoraAccent", bundle: .module)
    public static let agoraTertiary = Color("AgoraTertiary", bundle: .module)
    
    // MARK: - Brand Palette
    /// Extended brand color palette with all six colors
    public struct BrandPalette: Sendable {
        /// Sky Blue - Primary brand color #30C1FD
        public static let skyBlue = Color("AgoraBrand", bundle: .module)
        
        /// Rosy Magenta - Secondary brand color #FF3268
        public static let rosyMagenta = Color("AgoraAccent", bundle: .module)
        
        /// Light Turquoise - Tertiary brand color #A6D3E8
        public static let lightTurquoise = Color("AgoraTertiary", bundle: .module)
        
        /// Golden Yellow - Warm accent #FCAE23
        public static let goldenYellow = Color(red: 0.988, green: 0.682, blue: 0.137)
        
        /// Peachy Coral - Warm accent #F97B47
        public static let peachyCoral = Color(red: 0.976, green: 0.482, blue: 0.278)
        
        /// Lavender Purple - Cool accent #D59FFF
        public static let lavenderPurple = Color(red: 0.835, green: 0.624, blue: 1.000)
    }
    
    // MARK: - Semantic Brand Color Tokens
    /// Primary brand color (Sky Blue)
    public static let brandPrimary = agoraBrand
    
    /// Secondary brand color (Rosy Magenta)
    public static let brandSecondary = agoraAccent
    
    /// Tertiary brand color (Light Turquoise)
    public static let brandTertiary = agoraTertiary
}

// MARK: - Color Extensions for Backward Compatibility
@available(iOS 26.0, *)
public extension Color {
    static let agoraPrimary = ColorTokens.primary
    static let agoraSecondary = ColorTokens.secondary
    static let agoraTertiary = ColorTokens.agoraTertiary
    static let agoraBackground = ColorTokens.background
    static let agoraSurface = ColorTokens.agoraSurface
}

// MARK: - TypographyScale

/// Typography scale based on San Francisco font with Dynamic Type support.
///
/// All typography tokens automatically scale with the user's preferred text size
/// and support accessibility features.
@available(iOS 26.0, *)
public struct TypographyScale {
    // MARK: - San Francisco Font Hierarchy
    
    /// Large Title - 34pt, Bold. Used for major section headers.
    public static let largeTitle = Font.largeTitle.weight(.bold)
    
    /// Title 1 - 28pt, Bold
    public static let title1 = Font.title.weight(.bold)
    
    /// Title 2 - 22pt, Bold
    @available(iOS 26.0, *)
    public static let title2 = Font.title2.weight(.bold)
    
    /// Title 3 - 20pt, Semibold
    @available(iOS 26.0, *)
    public static let title3 = Font.title3.weight(.semibold)
    
    /// Headline - 17pt, Semibold
    public static let headline = Font.headline.weight(.semibold)
    
    /// Body - 17pt, Regular
    public static let body = Font.body
    
    /// Body Emphasized - 17pt, Semibold
    public static let bodyEmphasized = Font.body.weight(.semibold)
    
    /// Callout - 16pt, Regular
    public static let callout = Font.callout
    
    /// Callout Emphasized - 16pt, Semibold
    public static let calloutEmphasized = Font.callout.weight(.semibold)
    
    /// Subheadline - 15pt, Regular
    public static let subheadline = Font.subheadline
    
    /// Footnote - 13pt, Regular
    public static let footnote = Font.footnote
    
    /// Caption 1 - 12pt, Regular
    public static let caption1 = Font.caption
    
    /// Caption 2 - 11pt, Regular (minimum readable size)
    @available(iOS 26.0, *)
    public static let caption2 = Font.caption2
}

// MARK: - Typography Extensions for Backward Compatibility
@available(iOS 26.0, *)
public struct AgoraTypography {
    public static let largeTitle = TypographyScale.largeTitle
    public static let title = TypographyScale.title1
    public static let headline = TypographyScale.headline
    public static let body = TypographyScale.body
    public static let callout = TypographyScale.callout
    public static let subheadline = TypographyScale.subheadline
    public static let footnote = TypographyScale.footnote
    public static let caption = TypographyScale.caption1
}

// MARK: - SpacingTokens (8-point grid system)

/// Spacing tokens based on an 8-point grid system.
///
/// Provides consistent spacing values throughout the app to ensure
/// visual rhythm and alignment.
public struct SpacingTokens: Sendable {
    /// 2pt - Minimal spacing for tight layouts.
    public static let xxxs: CGFloat = 2
    
    /// 4pt - Extra extra small
    public static let xxs: CGFloat = 4
    
    /// 8pt - Extra small (base unit)
    public static let xs: CGFloat = 8
    
    /// 12pt - Small
    public static let sm: CGFloat = 12
    
    /// 16pt - Medium (2x base unit)
    public static let md: CGFloat = 16
    
    /// 20pt - Medium large
    public static let ml: CGFloat = 20
    
    /// 24pt - Large (3x base unit)
    public static let lg: CGFloat = 24
    
    /// 32pt - Extra large (4x base unit)
    public static let xl: CGFloat = 32
    
    /// 40pt - Extra extra large
    public static let xxl: CGFloat = 40
    
    /// 48pt - Extra extra extra large (6x base unit)
    public static let xxxl: CGFloat = 48
    
    /// 64pt - Huge (8x base unit)
    public static let huge: CGFloat = 64
}

// MARK: - Spacing Extensions for Backward Compatibility
public struct AgoraSpacing {
    public static let xs: CGFloat = SpacingTokens.xxs
    public static let sm: CGFloat = SpacingTokens.xs
    public static let md: CGFloat = SpacingTokens.md
    public static let lg: CGFloat = SpacingTokens.lg
    public static let xl: CGFloat = SpacingTokens.xl
    public static let xxl: CGFloat = SpacingTokens.xxxl
}

// MARK: - BorderRadiusTokens

/// Border radius tokens following Apple's design guidelines.
///
/// Provides consistent corner radius values for UI elements
/// following Apple's Human Interface Guidelines.
public struct BorderRadiusTokens: Sendable {
    /// 4pt - Extra small radius for compact elements
    public static let xs: CGFloat = 4
    
    /// 8pt - Small radius (base unit) for standard elements
    public static let sm: CGFloat = 8
    
    /// 12pt - Medium radius for cards and panels
    public static let md: CGFloat = 12
    
    /// 16pt - Large radius for prominent elements
    public static let lg: CGFloat = 16
    
    /// 20pt - Extra large radius for modals and sheets
    public static let xl: CGFloat = 20
    
    /// 24pt - Huge radius for special containers
    public static let huge: CGFloat = 24
    
    /// 50% - Circular radius for avatars and circular elements
    public static let circular: CGFloat = 0.5
}

// MARK: - ShadowTokens

/// Shadow tokens for consistent depth and elevation.
///
/// Provides standardized shadow values that work well
/// with both light and dark modes.
public struct ShadowTokens: Sendable {
    /// Subtle shadow for cards and subtle elevation
    public static let subtle = Shadow(
        color: .black.opacity(0.05),
        radius: 2,
        x: 0,
        y: 1
    )
    
    /// Standard shadow for buttons and interactive elements
    public static let standard = Shadow(
        color: .black.opacity(0.1),
        radius: 4,
        x: 0,
        y: 2
    )
    
    /// Prominent shadow for modals and floating panels
    public static let prominent = Shadow(
        color: .black.opacity(0.15),
        radius: 8,
        x: 0,
        y: 4
    )
    
    /// Strong shadow for overlays and high elevation
    public static let strong = Shadow(
        color: .black.opacity(0.2),
        radius: 12,
        x: 0,
        y: 6
    )
    
    /// Floating shadow for elevated modals
    public static let floating = Shadow(
        color: .black.opacity(0.25),
        radius: 20,
        x: 0,
        y: 10
    )
    
    // MARK: - Dark Mode Optimized Shadows
    
    /// Dark mode subtle shadow - more visible in dark backgrounds
    public static let darkSubtle = Shadow(
        color: .white.opacity(0.03),
        radius: 2,
        x: 0,
        y: 1
    )
    
    /// Dark mode standard shadow
    public static let darkStandard = Shadow(
        color: .white.opacity(0.05),
        radius: 4,
        x: 0,
        y: 2
    )
    
    /// Dark mode prominent shadow
    public static let darkProminent = Shadow(
        color: .white.opacity(0.08),
        radius: 8,
        x: 0,
        y: 4
    )
    
    /// Dark mode strong shadow
    public static let darkStrong = Shadow(
        color: .white.opacity(0.12),
        radius: 12,
        x: 0,
        y: 6
    )
    
    /// Dark mode floating shadow
    public static let darkFloating = Shadow(
        color: .white.opacity(0.15),
        radius: 20,
        x: 0,
        y: 10
    )
}

/// Shadow configuration structure
public struct Shadow: Sendable {
    public let color: Color
    public let radius: CGFloat
    public let x: CGFloat
    public let y: CGFloat
    
    public init(color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
        self.color = color
        self.radius = radius
        self.x = x
        self.y = y
    }
}

// MARK: - AnimationTokens

/// Animation tokens for consistent motion design.
///
/// Provides standardized animation durations and curves
/// following Apple's motion design principles and respecting
/// accessibility preferences like Reduce Motion.
@available(iOS 26.0, *)
public struct AnimationTokens {
    /// 0.1s - Instant feedback for micro-interactions
    public static let instant: Double = 0.1
    
    /// 0.2s - Quick transitions for UI state changes
    public static let quick: Double = 0.2
    
    /// 0.3s - Standard transitions for navigation and interactions
    public static let standard: Double = 0.3
    
    /// 0.5s - Longer transitions for complex animations
    public static let slow: Double = 0.5
    
    /// 0.8s - Extended transitions for special effects
    public static let extended: Double = 0.8
    
    /// Spring animation with Apple's standard parameters
    public static let spring = Animation.spring(response: 0.3, dampingFraction: 0.6)
    
    /// Ease in-out curve for smooth transitions
    public static let easeInOut = Animation.easeInOut(duration: standard)
    
    /// Ease out curve for appearing elements
    public static let easeOut = Animation.easeOut(duration: standard)
    
    /// Ease in curve for disappearing elements
    public static let easeIn = Animation.easeIn(duration: standard)
    
    // MARK: - Accessibility-Aware Animations
    
    /// Animation that respects Reduce Motion setting
    /// Returns instant animation if Reduce Motion is enabled
    ///
    /// Note: For view-level usage, prefer the `.animation()` modifier with
    /// `@Environment(\.accessibilityReduceMotion)` to respect user preferences.
    /// These static methods are provided for compatibility but don't have
    /// access to environment values. Consider using view modifiers instead.
    public static func accessible(_ duration: Double) -> Animation {
        // Note: Static methods can't access @Environment values
        // For proper reduce motion support, use .animation() modifier in views
        // with @Environment(\.accessibilityReduceMotion)
        return .easeInOut(duration: duration)
    }
    
    /// Spring animation that respects Reduce Motion setting
    ///
    /// Note: For view-level usage, prefer the `.animation()` modifier with
    /// `@Environment(\.accessibilityReduceMotion)` to respect user preferences.
    public static var accessibleSpring: Animation {
        // Note: Static methods can't access @Environment values
        // For proper reduce motion support, use .animation() modifier in views
        return spring
    }
    
    /// Color transition animation that respects Reduce Motion
    public static var colorTransition: Animation {
        accessible(standard)
    }
    
    /// Shadow transition animation that respects Reduce Motion
    public static var shadowTransition: Animation {
        accessible(quick)
    }
}

// MARK: - IconSizeTokens

/// Icon size tokens following Apple's icon guidelines.
///
/// Provides consistent icon sizes that work well with
/// SF Symbols and maintain proper touch targets.
public struct IconSizeTokens: Sendable {
    /// 12pt - Extra small icons for compact UI
    public static let xs: CGFloat = 12
    
    /// 16pt - Small icons for secondary elements
    public static let sm: CGFloat = 16
    
    /// 20pt - Medium icons for standard elements
    public static let md: CGFloat = 20
    
    /// 24pt - Large icons for prominent elements
    public static let lg: CGFloat = 24
    
    /// 32pt - Extra large icons for headers and emphasis
    public static let xl: CGFloat = 32
    
    /// 48pt - Huge icons for empty states and illustrations
    public static let huge: CGFloat = 48
    
    /// 64pt - Massive icons for splash screens and hero elements
    public static let massive: CGFloat = 64
}

// MARK: - Liquid Glass Effects (iOS 26 Design)
@available(iOS 26.0, *)
public struct LiquidGlassModifier: ViewModifier {
    let style: LiquidGlassStyle
    
    public enum LiquidGlassStyle {
        case navigationBar
        case tabBar
        case floatingPanel
        case modal
    }
    
    public func body(content: Content) -> some View {
        switch style {
        case .navigationBar:
            content
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 0))
        case .tabBar:
            content
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 0))
        case .floatingPanel:
            content
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: BorderRadiusTokens.lg))
                .agoraShadow(ShadowTokens.prominent)
        case .modal:
            content
                .background(.thickMaterial, in: RoundedRectangle(cornerRadius: BorderRadiusTokens.xl))
                .agoraShadow(ShadowTokens.floating)
        }
    }
}

// MARK: - Dark Mode Environment Key
@available(iOS 26.0, *)
private struct DarkModeKey: EnvironmentKey {
    static let defaultValue: Bool = true // Default to dark mode
}

@available(iOS 26.0, *)
public extension EnvironmentValues {
    var isDarkMode: Bool {
        get { self[DarkModeKey.self] }
        set { self[DarkModeKey.self] = newValue }
    }
}

// MARK: - Adaptive Shadow Modifier
@available(iOS 26.0, *)
struct AdaptiveShadowModifier: ViewModifier {
    let lightShadow: Shadow
    let darkShadow: Shadow
    @Environment(\.colorScheme) private var colorScheme
    
    func body(content: Content) -> some View {
        content
            .shadow(
                color: colorScheme == .dark ? darkShadow.color : lightShadow.color,
                radius: colorScheme == .dark ? darkShadow.radius : lightShadow.radius,
                x: colorScheme == .dark ? darkShadow.x : lightShadow.x,
                y: colorScheme == .dark ? darkShadow.y : lightShadow.y
            )
    }
}

@available(iOS 26.0, *)
public extension View {
    func liquidGlass(_ style: LiquidGlassModifier.LiquidGlassStyle) -> some View {
        modifier(LiquidGlassModifier(style: style))
    }
    
    /// Apply a shadow using design system tokens
    func agoraShadow(_ shadow: Shadow) -> some View {
        self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
    
    /// Apply a subtle shadow for cards (adapts to color scheme)
    func agoraCardShadow() -> some View {
        self.modifier(AdaptiveShadowModifier(lightShadow: ShadowTokens.subtle, darkShadow: ShadowTokens.darkSubtle))
    }
    
    /// Apply a standard shadow for buttons (adapts to color scheme)
    func agoraButtonShadow() -> some View {
        self.modifier(AdaptiveShadowModifier(lightShadow: ShadowTokens.standard, darkShadow: ShadowTokens.darkStandard))
    }
    
    /// Apply a prominent shadow for modals (adapts to color scheme)
    func agoraModalShadow() -> some View {
        self.modifier(AdaptiveShadowModifier(lightShadow: ShadowTokens.prominent, darkShadow: ShadowTokens.darkProminent))
    }
    
    /// Apply a floating shadow for elevated elements (adapts to color scheme)
    func agoraFloatingShadow() -> some View {
        self.modifier(AdaptiveShadowModifier(lightShadow: ShadowTokens.floating, darkShadow: ShadowTokens.darkFloating))
    }
    
    /// Apply a strong shadow for overlays (adapts to color scheme)
    func agoraStrongShadow() -> some View {
        self.modifier(AdaptiveShadowModifier(lightShadow: ShadowTokens.strong, darkShadow: ShadowTokens.darkStrong))
    }
    
    // MARK: - Accessibility Support
    
    /// Apply high contrast styling when High Contrast is enabled
    func agoraHighContrast() -> some View {
        Group {
            #if canImport(UIKit)
            if DesignSystemBridge.isDarkerSystemColorsEnabled {
                self
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.primary, lineWidth: 2)
                    )
            } else {
                self
            }
            #else
            self
            #endif
        }
    }
    
    /// Apply reduced motion styling when Reduce Motion is enabled
    func agoraReducedMotion() -> some View {
        Group {
            #if canImport(UIKit)
            if DesignSystemBridge.isReduceMotionEnabled {
                self
                    .animation(nil, value: UUID()) // Disable all animations
            } else {
                self
            }
            #else
            self
            #endif
        }
    }
    
    /// Apply both high contrast and reduced motion accessibility features
    func agoraAccessible() -> some View {
        self
            .agoraHighContrast()
            .agoraReducedMotion()
    }
}

// MARK: - Skeleton Loading System

/// The skeleton loading system provides comprehensive loading state management
/// with placeholder content that matches final layout geometry.
///
/// Key components available:
/// - `SkeletonTheme` and `DefaultSkeletonTheme`: Design token integration
/// - `SkeletonViewStyle`: Styling variants for skeleton components  
/// - `.skeleton(isActive:)`: SwiftUI modifier for any view
/// - `ShimmerView`: Animated gradient with accessibility support
/// - `MotionPreferences`: Accessibility motion preference helpers
/// - `SkeletonA11y`: VoiceOver and accessibility utilities
/// - `SkeletonErrorView`: Error handling with retry functionality
///
/// The system automatically respects accessibility preferences including
/// Reduce Motion, Increase Contrast, and VoiceOver navigation.

// MARK: - Error Handling System

/// Error handling components for skeleton loading failures.
/// Provides inline error display with retry functionality for feed rows.
///
/// Key components:
/// - `SkeletonErrorView`: Configurable error display with retry actions
/// - Inline, full, and compact error styles
/// - User-friendly error message translation
/// - Accessibility support for error states
