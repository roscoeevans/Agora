//
//  MotionPreferences.swift
//  DesignSystem
//
//  Created by Agora Team on 2024.
//

import SwiftUI

/// Helper utilities for querying accessibility motion preferences.
///
/// MotionPreferences provides convenient access to system accessibility
/// settings that affect animation behavior in skeleton loading.
@available(iOS 26.0, *)
public struct MotionPreferences {
    /// Checks if Reduce Motion accessibility setting is enabled.
    ///
    /// When Reduce Motion is enabled, skeleton animations should be disabled
    /// to respect user preferences for reduced visual motion.
    ///
    /// - Returns: True if Reduce Motion is enabled
    public static func isReduceMotionEnabled() -> Bool {
        #if canImport(UIKit)
        return UIAccessibility.isReduceMotionEnabled
        #else
        return false
        #endif
    }
    
    /// Checks if Increase Contrast accessibility setting is enabled.
    ///
    /// When Increase Contrast is enabled, skeleton placeholders should use
    /// higher contrast colors for better visibility.
    ///
    /// - Returns: True if Increase Contrast is enabled
    public static func isIncreaseContrastEnabled() -> Bool {
        #if canImport(UIKit)
        return UIAccessibility.isDarkerSystemColorsEnabled
        #else
        return false
        #endif
    }
    
    /// Checks if VoiceOver is currently running.
    ///
    /// When VoiceOver is active, skeleton placeholders should be hidden
    /// from the accessibility tree to prevent confusing navigation.
    ///
    /// - Returns: True if VoiceOver is running
    public static func isVoiceOverRunning() -> Bool {
        #if canImport(UIKit)
        return UIAccessibility.isVoiceOverRunning
        #else
        return false
        #endif
    }
    
    /// Determines if shimmer animation should be enabled based on accessibility preferences.
    ///
    /// Shimmer is disabled when Reduce Motion is enabled to respect user preferences.
    ///
    /// - Returns: True if shimmer animation should be enabled
    public static func shouldEnableShimmer() -> Bool {
        return !isReduceMotionEnabled()
    }
    
    /// Gets the appropriate placeholder color based on accessibility preferences.
    ///
    /// Returns higher contrast color when Increase Contrast is enabled.
    ///
    /// - Parameter theme: The skeleton theme to use for color selection
    /// - Returns: Appropriate placeholder color for current accessibility settings
    public static func placeholderColor(for theme: any SkeletonTheme) -> Color {
        if isIncreaseContrastEnabled() {
            return ColorTokens.separator
        } else {
            return theme.placeholderColor
        }
    }
}

/// SwiftUI environment values extension for motion preferences
@available(iOS 26.0, *)
public extension EnvironmentValues {
    /// Convenience accessor for Reduce Motion preference
    var isReduceMotionEnabled: Bool {
        accessibilityReduceMotion
    }
    
    /// Convenience accessor for Increase Contrast preference
    var isIncreaseContrastEnabled: Bool {
        accessibilityDifferentiateWithoutColor
    }
}

/// View modifier that automatically adjusts skeleton behavior based on motion preferences
@available(iOS 26.0, *)
public struct MotionAwareSkeletonModifier: ViewModifier {
    let isActive: Bool
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityDifferentiateWithoutColor) private var increaseContrast
    @Environment(\.skeletonTheme) private var theme
    
    public init(isActive: Bool) {
        self.isActive = isActive
    }
    
    public func body(content: Content) -> some View {
        content
            .skeleton(isActive: isActive)
    }
}

@available(iOS 26.0, *)
public extension View {
    /// Applies skeleton loading with automatic motion preference handling.
    ///
    /// This modifier automatically respects Reduce Motion and Increase Contrast
    /// accessibility preferences when displaying skeleton loading states.
    ///
    /// - Parameter isActive: Whether the skeleton should be displayed
    /// - Returns: A view with motion-aware skeleton loading
    func motionAwareSkeleton(isActive: Bool) -> some View {
        modifier(MotionAwareSkeletonModifier(isActive: isActive))
    }
}

#if DEBUG
@available(iOS 26.0, *)
struct MotionPreferences_Previews: PreviewProvider {
    static var previews: some View {
        let theme = DefaultSkeletonTheme()
        
        VStack(spacing: SpacingTokens.md) {
            // Motion preferences info
            VStack(alignment: .leading, spacing: SpacingTokens.xs) {
                Text("Motion Preferences")
                    .font(TypographyScale.headline)
                
                Text("Reduce Motion: \(MotionPreferences.isReduceMotionEnabled() ? "Enabled" : "Disabled")")
                    .font(TypographyScale.caption1)
                
                Text("Increase Contrast: \(MotionPreferences.isIncreaseContrastEnabled() ? "Enabled" : "Disabled")")
                    .font(TypographyScale.caption1)
                
                Text("VoiceOver: \(MotionPreferences.isVoiceOverRunning() ? "Running" : "Not Running")")
                    .font(TypographyScale.caption1)
                
                Text("Shimmer Enabled: \(MotionPreferences.shouldEnableShimmer() ? "Yes" : "No")")
                    .font(TypographyScale.caption1)
            }
            
            Divider()
            
            // Example skeleton with motion awareness
            VStack(spacing: SpacingTokens.sm) {
                Text("Motion-Aware Skeleton Example")
                    .font(TypographyScale.subheadline)
                
                RoundedRectangle(cornerRadius: BorderRadiusTokens.sm)
                    .fill(MotionPreferences.placeholderColor(for: theme))
                    .frame(height: 20)
                    .motionAwareSkeleton(isActive: true)
                
                RoundedRectangle(cornerRadius: BorderRadiusTokens.sm)
                    .fill(MotionPreferences.placeholderColor(for: theme))
                    .frame(height: 16)
                    .scaleEffect(x: 0.7, anchor: .leading)
                    .motionAwareSkeleton(isActive: true)
            }
        }
        .padding(SpacingTokens.lg)
        .background(ColorTokens.background)
        .skeletonTheme(theme)
        .previewDisplayName("Motion Preferences")
    }
}
#endif