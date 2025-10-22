//
//  FeedPostSkeletonView.swift
//  DesignSystem
//
//  Created by Agora Team on 2024.
//

import SwiftUI

/// Skeleton placeholder component that approximates FeedPostView geometry.
///
/// FeedPostSkeletonView provides a generic post-shaped placeholder with
/// 40×40pt avatar, 120pt name width, and 16pt padding that matches the
/// layout structure of actual feed posts without content-specific mirroring.
@available(iOS 26.0, *)
public struct FeedPostSkeletonView: View {
    @Environment(\.skeletonTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityDifferentiateWithoutColor) private var increaseContrast
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacingScale.xs) {
            // Header Section
            headerSection
            
            // Body Section
            bodySection
            
            // Footer Section
            footerSection
        }
        .padding(.horizontal, theme.spacingScale.md) // 16pt horizontal padding
        .padding(.vertical, theme.spacingScale.sm) // 12pt vertical padding
        .background(theme.backgroundColor)
        .skeletonAccessibilityHidden(true)
        .skeletonAccessibilityLabel(
            isActive: true,
            loadingLabel: "Loading post content"
        )
        .skeletonDynamicType(isActive: true)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading post")
        .accessibilityAddTraits(.updatesFrequently)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack(spacing: theme.spacingScale.sm) {
            // 40×40pt circular avatar placeholder
            avatarPlaceholder
            
            VStack(alignment: .leading, spacing: 4) {
                // 120pt width name line
                namePlaceholder
                
                HStack(spacing: theme.spacingScale.xs) {
                    // 80pt handle placeholder
                    handlePlaceholder
                    
                    // Separator dot
                    Circle()
                        .fill(placeholderColor)
                        .frame(width: 3, height: 3)
                    
                    // 60pt timestamp placeholder
                    timestampPlaceholder
                }
            }
            
            Spacer()
            
            // More button placeholder
            moreButtonPlaceholder
        }
    }
    
    private var avatarPlaceholder: some View {
        Circle()
            .fill(placeholderColor)
            .frame(width: theme.avatarSizes.md, height: theme.avatarSizes.md) // 40×40pt
            .overlay(
                Group {
                    if shouldShowShimmer {
                        ShimmerView(theme: theme)
                            .clipShape(Circle())
                    }
                }
            )
    }
    
    private var namePlaceholder: some View {
        RoundedRectangle(cornerRadius: theme.cornerRadii.xs)
            .fill(placeholderColor)
            .frame(width: 120, height: 16) // 120pt name width
            .overlay(
                Group {
                    if shouldShowShimmer {
                        ShimmerView(theme: theme)
                            .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadii.xs))
                    }
                }
            )
    }
    
    private var handlePlaceholder: some View {
        RoundedRectangle(cornerRadius: theme.cornerRadii.xs)
            .fill(placeholderColor)
            .frame(width: 80, height: 14) // 80pt handle width
            .overlay(
                Group {
                    if shouldShowShimmer {
                        ShimmerView(theme: theme)
                            .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadii.xs))
                    }
                }
            )
    }
    
    private var timestampPlaceholder: some View {
        RoundedRectangle(cornerRadius: theme.cornerRadii.xs)
            .fill(placeholderColor)
            .frame(width: 60, height: 14) // 60pt timestamp width
            .overlay(
                Group {
                    if shouldShowShimmer {
                        ShimmerView(theme: theme)
                            .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadii.xs))
                    }
                }
            )
    }
    
    private var moreButtonPlaceholder: some View {
        Circle()
            .fill(placeholderColor)
            .frame(width: 20, height: 20)
            .overlay(
                Group {
                    if shouldShowShimmer {
                        ShimmerView(theme: theme)
                            .clipShape(Circle())
                    }
                }
            )
    }
    
    // MARK: - Body Section
    
    private var bodySection: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 2-3 text line placeholders with natural text appearance
            textLinePlaceholder(width: .infinity) // 100% width
            textLinePlaceholder(width: 0.85) // 85% width
            textLinePlaceholder(width: 0.60) // 60% width
        }
        .padding(.leading, theme.avatarSizes.md + theme.spacingScale.sm) // Align with content, not avatar
    }
    
    private func textLinePlaceholder(width: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: theme.cornerRadii.xs)
            .fill(placeholderColor)
            .frame(height: 20) // Match TypographyScale.body line height
            .frame(maxWidth: width == .infinity ? nil : .infinity)
            .scaleEffect(x: width == .infinity ? 1.0 : width, anchor: .leading)
            .overlay(
                Group {
                    if shouldShowShimmer {
                        ShimmerView(theme: theme)
                            .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadii.xs))
                    }
                }
            )
    }
    
    // MARK: - Footer Section
    
    private var footerSection: some View {
        HStack(spacing: theme.spacingScale.lg) {
            // Engagement button row with 44pt height for touch targets
            engagementButtonPlaceholder
            engagementButtonPlaceholder
            engagementButtonPlaceholder
            
            Spacer()
            
            // Share button placeholder
            engagementButtonPlaceholder
        }
        .frame(height: 44) // 44pt touch target height
        .padding(.leading, theme.avatarSizes.md + theme.spacingScale.sm) // Align with content
    }
    
    private var engagementButtonPlaceholder: some View {
        HStack(spacing: theme.spacingScale.xs) {
            // 16pt icon placeholder
            RoundedRectangle(cornerRadius: theme.cornerRadii.xs)
                .fill(placeholderColor)
                .frame(width: 16, height: 16)
                .overlay(
                    Group {
                        if shouldShowShimmer {
                            ShimmerView(theme: theme)
                                .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadii.xs))
                        }
                    }
                )
            
            // Count placeholder (optional)
            RoundedRectangle(cornerRadius: theme.cornerRadii.xs)
                .fill(placeholderColor)
                .frame(width: 20, height: 12)
                .overlay(
                    Group {
                        if shouldShowShimmer {
                            ShimmerView(theme: theme)
                                .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadii.xs))
                        }
                    }
                )
        }
    }
    
    // MARK: - Computed Properties
    
    private var shouldShowShimmer: Bool {
        !reduceMotion
    }
    
    private var placeholderColor: Color {
        if increaseContrast {
            return ColorTokens.separator
        } else {
            return theme.placeholderColor
        }
    }
}

#if DEBUG
@available(iOS 26.0, *)
struct FeedPostSkeletonView_Previews: PreviewProvider {
    static var previews: some View {
        let theme = DefaultSkeletonTheme()
        
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(0..<5, id: \.self) { _ in
                    FeedPostSkeletonView()
                    
                    Divider()
                        .padding(.horizontal, SpacingTokens.md)
                }
            }
        }
        .background(ColorTokens.background)
        .skeletonTheme(theme)
        .previewDisplayName("Light Mode - Multiple Posts")
        
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(0..<3, id: \.self) { _ in
                    FeedPostSkeletonView()
                    
                    Divider()
                        .padding(.horizontal, SpacingTokens.md)
                }
            }
        }
        .background(ColorTokens.background)
        .skeletonTheme(theme)
        .preferredColorScheme(.dark)
        .previewDisplayName("Dark Mode - Multiple Posts")
        
        VStack(spacing: SpacingTokens.md) {
            Text("Single Post Skeleton")
                .font(TypographyScale.headline)
                .foregroundColor(ColorTokens.primaryText)
            
            FeedPostSkeletonView()
                .background(ColorTokens.secondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: BorderRadiusTokens.md))
        }
        .padding(SpacingTokens.lg)
        .background(ColorTokens.background)
        .skeletonTheme(theme)
        .previewDisplayName("Single Post Card")
        
        VStack(spacing: SpacingTokens.md) {
            Text("Reduced Motion")
                .font(TypographyScale.headline)
                .foregroundColor(ColorTokens.primaryText)
            
            FeedPostSkeletonView()
        }
        .padding(SpacingTokens.lg)
        .background(ColorTokens.background)
        .skeletonTheme(theme)
        .previewDisplayName("Reduce Motion Enabled")
        
        VStack(spacing: SpacingTokens.md) {
            Text("Increased Contrast")
                .font(TypographyScale.headline)
                .foregroundColor(ColorTokens.primaryText)
            
            FeedPostSkeletonView()
        }
        .padding(SpacingTokens.lg)
        .background(ColorTokens.background)
        .skeletonTheme(theme)
        .previewDisplayName("Increase Contrast Enabled")
    }
}
#endif