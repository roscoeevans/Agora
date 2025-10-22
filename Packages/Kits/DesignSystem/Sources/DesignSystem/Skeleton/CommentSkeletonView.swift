//
//  CommentSkeletonView.swift
//  DesignSystem
//
//  Created by Agora Team on 2024.
//

import SwiftUI

/// Skeleton placeholder component for comment/reply interfaces.
///
/// CommentSkeletonView provides a compact placeholder with 32×32pt avatar
/// and 100pt name width, designed for reply interfaces and comment sheets
/// where space is more constrained than main feed posts.
@available(iOS 26.0, *)
public struct CommentSkeletonView: View {
    @Environment(\.skeletonTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityDifferentiateWithoutColor) private var increaseContrast
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacingScale.xs) {
            // Header Section (more compact than feed posts)
            headerSection
            
            // Body Section (1-2 lines for comments)
            bodySection
            
            // Footer Section (minimal engagement buttons)
            footerSection
        }
        .padding(.horizontal, theme.spacingScale.md) // 16pt horizontal padding
        .padding(.vertical, theme.spacingScale.xs) // 8pt vertical padding (more compact)
        .background(theme.backgroundColor)
        .skeletonAccessibilityHidden(true)
        .skeletonAccessibilityLabel(
            isActive: true,
            loadingLabel: "Loading comment content"
        )
        .skeletonDynamicType(isActive: true)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading comment")
        .accessibilityAddTraits(.updatesFrequently)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack(spacing: theme.spacingScale.xs) { // Smaller spacing for compact layout
            // 32×32pt circular avatar placeholder (smaller than feed posts)
            avatarPlaceholder
            
            VStack(alignment: .leading, spacing: 2) { // Tighter spacing
                // 100pt width name line (shorter than feed posts)
                namePlaceholder
                
                HStack(spacing: theme.spacingScale.xxs) {
                    // 70pt handle placeholder (shorter)
                    handlePlaceholder
                    
                    // Separator dot
                    Circle()
                        .fill(placeholderColor)
                        .frame(width: 2, height: 2) // Smaller dot
                    
                    // 50pt timestamp placeholder (shorter)
                    timestampPlaceholder
                }
            }
            
            Spacer()
            
            // More button placeholder (smaller)
            moreButtonPlaceholder
        }
    }
    
    private var avatarPlaceholder: some View {
        Circle()
            .fill(placeholderColor)
            .frame(width: theme.avatarSizes.sm, height: theme.avatarSizes.sm) // 32×32pt
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
            .frame(width: 100, height: 14) // 100pt name width, smaller height
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
            .frame(width: 70, height: 12) // 70pt handle width, smaller
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
            .frame(width: 50, height: 12) // 50pt timestamp width, smaller
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
            .frame(width: 16, height: 16) // Smaller than feed posts
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
        VStack(alignment: .leading, spacing: 4) {
            // 1-2 text line placeholders for comment content
            textLinePlaceholder(width: .infinity) // 100% width
            textLinePlaceholder(width: 0.75) // 75% width (shorter than posts)
        }
        .padding(.leading, theme.avatarSizes.sm + theme.spacingScale.xs) // Align with content, not avatar
    }
    
    private func textLinePlaceholder(width: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: theme.cornerRadii.xs)
            .fill(placeholderColor)
            .frame(height: 16) // Smaller line height for comments
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
        HStack(spacing: theme.spacingScale.md) {
            // Minimal engagement buttons for comments
            commentEngagementButtonPlaceholder // Like
            commentEngagementButtonPlaceholder // Reply
            
            Spacer()
        }
        .frame(height: 32) // Smaller touch target for comments
        .padding(.leading, theme.avatarSizes.sm + theme.spacingScale.xs) // Align with content
    }
    
    private var commentEngagementButtonPlaceholder: some View {
        HStack(spacing: theme.spacingScale.xxs) {
            // 14pt icon placeholder (smaller than feed posts)
            RoundedRectangle(cornerRadius: theme.cornerRadii.xs)
                .fill(placeholderColor)
                .frame(width: 14, height: 14)
                .overlay(
                    Group {
                        if shouldShowShimmer {
                            ShimmerView(theme: theme)
                                .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadii.xs))
                        }
                    }
                )
            
            // Count placeholder (smaller)
            RoundedRectangle(cornerRadius: theme.cornerRadii.xs)
                .fill(placeholderColor)
                .frame(width: 16, height: 10)
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
struct CommentSkeletonView_Previews: PreviewProvider {
    static var previews: some View {
        let theme = DefaultSkeletonTheme()
        
        ScrollView {
            LazyVStack(spacing: 0) {
                // Parent post placeholder (could be actual content)
                VStack(alignment: .leading, spacing: SpacingTokens.sm) {
                    Text("Parent Post Content")
                        .font(TypographyScale.body)
                        .foregroundColor(ColorTokens.primaryText)
                        .padding(.horizontal, SpacingTokens.md)
                    
                    Divider()
                }
                
                // Comment skeleton placeholders
                ForEach(0..<6, id: \.self) { index in
                    CommentSkeletonView()
                    
                    if index < 5 {
                        Divider()
                            .padding(.horizontal, SpacingTokens.md)
                    }
                }
            }
        }
        .background(ColorTokens.background)
        .skeletonTheme(theme)
        .previewDisplayName("Light Mode - Comment Thread")
        
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(0..<4, id: \.self) { index in
                    CommentSkeletonView()
                    
                    if index < 3 {
                        Divider()
                            .padding(.horizontal, SpacingTokens.md)
                    }
                }
            }
        }
        .background(ColorTokens.background)
        .skeletonTheme(theme)
        .preferredColorScheme(.dark)
        .previewDisplayName("Dark Mode - Comments")
        
        VStack(spacing: SpacingTokens.md) {
            Text("Single Comment Skeleton")
                .font(TypographyScale.headline)
                .foregroundColor(ColorTokens.primaryText)
            
            CommentSkeletonView()
                .background(ColorTokens.secondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: BorderRadiusTokens.sm))
        }
        .padding(SpacingTokens.lg)
        .background(ColorTokens.background)
        .skeletonTheme(theme)
        .previewDisplayName("Single Comment")
        
        VStack(spacing: SpacingTokens.sm) {
            Text("Size Comparison")
                .font(TypographyScale.headline)
                .foregroundColor(ColorTokens.primaryText)
            
            VStack(alignment: .leading, spacing: SpacingTokens.md) {
                VStack(alignment: .leading, spacing: SpacingTokens.xs) {
                    Text("Feed Post Skeleton (40×40pt avatar)")
                        .font(TypographyScale.caption1)
                        .foregroundColor(ColorTokens.secondaryText)
                    
                    FeedPostSkeletonView()
                        .background(ColorTokens.tertiaryBackground)
                        .clipShape(RoundedRectangle(cornerRadius: BorderRadiusTokens.sm))
                }
                
                VStack(alignment: .leading, spacing: SpacingTokens.xs) {
                    Text("Comment Skeleton (32×32pt avatar)")
                        .font(TypographyScale.caption1)
                        .foregroundColor(ColorTokens.secondaryText)
                    
                    CommentSkeletonView()
                        .background(ColorTokens.tertiaryBackground)
                        .clipShape(RoundedRectangle(cornerRadius: BorderRadiusTokens.sm))
                }
            }
        }
        .padding(SpacingTokens.lg)
        .background(ColorTokens.background)
        .skeletonTheme(theme)
        .previewDisplayName("Size Comparison")
        
        VStack(spacing: SpacingTokens.md) {
            Text("Accessibility States")
                .font(TypographyScale.headline)
                .foregroundColor(ColorTokens.primaryText)
            
            VStack(spacing: SpacingTokens.sm) {
                Text("Reduced Motion")
                    .font(TypographyScale.caption1)
                CommentSkeletonView()
                
                Text("Increased Contrast")
                    .font(TypographyScale.caption1)
                CommentSkeletonView()
            }
        }
        .padding(SpacingTokens.lg)
        .background(ColorTokens.background)
        .skeletonTheme(theme)
        .previewDisplayName("Accessibility States")
    }
}
#endif