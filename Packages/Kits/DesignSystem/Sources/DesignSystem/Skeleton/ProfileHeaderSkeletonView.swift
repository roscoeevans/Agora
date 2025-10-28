//
//  ProfileHeaderSkeletonView.swift
//  DesignSystem
//
//  Created by Agora Team on 2024.
//

import SwiftUI

/// Skeleton placeholder component for profile header.
///
/// ProfileHeaderSkeletonView provides a skeleton representation of the profile
/// header including avatar, name, handle, and stats sections.
@available(iOS 26.0, *)
public struct ProfileHeaderSkeletonView: View {
    @Environment(\.skeletonTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityDifferentiateWithoutColor) private var increaseContrast
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: theme.spacingScale.md) {
            // Avatar skeleton (80pt circle)
            Circle()
                .fill(theme.placeholderColor)
                .frame(width: theme.avatarSizes.lg, height: theme.avatarSizes.lg)
            
            // Name and handle section
            VStack(spacing: theme.spacingScale.xxs) {
                // Display name skeleton
                RoundedRectangle(cornerRadius: theme.cornerRadii.xs)
                    .fill(theme.placeholderColor)
                    .frame(width: 140, height: 28) // title2 approximate height
                
                // Handle skeleton
                RoundedRectangle(cornerRadius: theme.cornerRadii.xs)
                    .fill(theme.placeholderColor)
                    .frame(width: 100, height: 18) // callout approximate height
            }
            
            // Bio skeleton (optional, shown for visual consistency)
            RoundedRectangle(cornerRadius: theme.cornerRadii.xs)
                .fill(theme.placeholderColor)
                .frame(width: 200, height: 40) // 2-3 lines of body text
                .padding(.horizontal, theme.spacingScale.md)
            
            // Stats section skeleton
            HStack(spacing: theme.spacingScale.xl) {
                StatSkeletonView()
                StatSkeletonView()
                StatSkeletonView()
            }
            
            // Action button skeleton
            RoundedRectangle(cornerRadius: theme.cornerRadii.sm)
                .fill(theme.placeholderColor)
                .frame(height: 44) // Standard button height
                .padding(.horizontal, theme.spacingScale.md)
        }
        .padding(theme.spacingScale.md)
        .skeletonAccessibilityHidden(true)
        .skeletonAccessibilityLabel(
            isActive: true,
            loadingLabel: "Loading profile information"
        )
        .skeletonDynamicType(isActive: true)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading profile")
        .accessibilityAddTraits(.updatesFrequently)
    }
}

/// Skeleton view for a single stat (Posts/Following/Followers)
@available(iOS 26.0, *)
private struct StatSkeletonView: View {
    @Environment(\.skeletonTheme) private var theme
    
    var body: some View {
        VStack(spacing: theme.spacingScale.xxs) {
            // Count skeleton
            RoundedRectangle(cornerRadius: theme.cornerRadii.xs)
                .fill(theme.placeholderColor)
                .frame(width: 40, height: 24) // title3 approximate height
            
            // Label skeleton
            RoundedRectangle(cornerRadius: theme.cornerRadii.xs)
                .fill(theme.placeholderColor)
                .frame(width: 60, height: 14) // caption1 approximate height
        }
        .frame(maxWidth: .infinity)
    }
}

#if DEBUG
@available(iOS 26.0, *)
#Preview("Profile Header Skeleton") {
    ProfileHeaderSkeletonView()
        .skeletonTheme(DefaultSkeletonTheme())
        .skeleton(isActive: true)
}

@available(iOS 26.0, *)
#Preview("Profile Header Skeleton - Dark Mode") {
    ProfileHeaderSkeletonView()
        .skeletonTheme(DefaultSkeletonTheme())
        .skeleton(isActive: true)
        .preferredColorScheme(.dark)
}
#endif



