//
//  MediaSkeletonView.swift
//  DesignSystem
//
//  Created by Agora Team on 2024.
//

import SwiftUI

/// Skeleton placeholder component for media content (images and videos).
///
/// MediaSkeletonView provides a placeholder that matches the geometry
/// of media content with proper aspect ratios and loading states.
@available(iOS 26.0, *)
public struct MediaSkeletonView: View {
    let aspectRatio: CGFloat
    let cornerRadius: CGFloat
    
    @Environment(\.skeletonTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityDifferentiateWithoutColor) private var increaseContrast
    
    public init(aspectRatio: CGFloat = 16/9, cornerRadius: CGFloat? = nil) {
        self.aspectRatio = aspectRatio
        self.cornerRadius = cornerRadius ?? BorderRadiusTokens.md
    }
    
    public var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(placeholderColor)
            .aspectRatio(aspectRatio, contentMode: .fit)
            .overlay(
                Group {
                    if shouldShowShimmer {
                        ShimmerView(theme: theme)
                            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    }
                }
            )
            .overlay(
                // Media type indicator (play button for video, image icon for image)
                mediaTypeIndicator
            )
            .skeletonAccessibilityHidden(true)
            .skeletonAccessibilityLabel(
                isActive: true,
                loadingLabel: "Loading media content"
            )
            .skeletonDynamicType(isActive: true)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Loading media")
            .accessibilityAddTraits(.updatesFrequently)
    }
    
    // MARK: - Media Type Indicator
    
    private var mediaTypeIndicator: some View {
        VStack(spacing: SpacingTokens.xs) {
            // Play button or image icon placeholder
            Circle()
                .fill(placeholderColor.opacity(0.8))
                .frame(width: 40, height: 40)
                .overlay(
                    Group {
                        if shouldShowShimmer {
                            ShimmerView(theme: theme)
                                .clipShape(Circle())
                        }
                    }
                )
            
            // Optional duration text for videos
            if aspectRatio < 1.5 { // Assume video if aspect ratio is closer to square
                RoundedRectangle(cornerRadius: theme.cornerRadii.xs)
                    .fill(placeholderColor.opacity(0.6))
                    .frame(width: 30, height: 12)
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
struct MediaSkeletonView_Previews: PreviewProvider {
    static var previews: some View {
        let theme = DefaultSkeletonTheme()
        
        VStack(spacing: SpacingTokens.lg) {
            Text("Media Skeleton Loading")
                .font(TypographyScale.headline)
                .foregroundColor(ColorTokens.primaryText)
            
            // Image skeleton (16:9 aspect ratio)
            MediaSkeletonView(aspectRatio: 16/9)
                .frame(maxHeight: 200)
            
            // Video skeleton (4:3 aspect ratio)
            MediaSkeletonView(aspectRatio: 4/3)
                .frame(maxHeight: 200)
            
            // Square skeleton (1:1 aspect ratio)
            MediaSkeletonView(aspectRatio: 1)
                .frame(maxHeight: 200)
        }
        .padding(SpacingTokens.lg)
        .background(ColorTokens.background)
        .skeletonTheme(theme)
        .previewDisplayName("Light Mode - Various Aspect Ratios")
        
        VStack(spacing: SpacingTokens.lg) {
            Text("Media Skeleton Loading")
                .font(TypographyScale.headline)
                .foregroundColor(ColorTokens.primaryText)
            
            // Image skeleton (16:9 aspect ratio)
            MediaSkeletonView(aspectRatio: 16/9)
                .frame(maxHeight: 200)
            
            // Video skeleton (4:3 aspect ratio)
            MediaSkeletonView(aspectRatio: 4/3)
                .frame(maxHeight: 200)
            
            // Square skeleton (1:1 aspect ratio)
            MediaSkeletonView(aspectRatio: 1)
                .frame(maxHeight: 200)
        }
        .padding(SpacingTokens.lg)
        .background(ColorTokens.background)
        .skeletonTheme(theme)
        .preferredColorScheme(.dark)
        .previewDisplayName("Dark Mode - Various Aspect Ratios")
        
        VStack(spacing: SpacingTokens.lg) {
            Text("Reduced Motion")
                .font(TypographyScale.headline)
                .foregroundColor(ColorTokens.primaryText)
            
            MediaSkeletonView(aspectRatio: 16/9)
                .frame(maxHeight: 200)
        }
        .padding(SpacingTokens.lg)
        .background(ColorTokens.background)
        .skeletonTheme(theme)
        .previewDisplayName("Reduce Motion Enabled")
        
        VStack(spacing: SpacingTokens.lg) {
            Text("Increased Contrast")
                .font(TypographyScale.headline)
                .foregroundColor(ColorTokens.primaryText)
            
            MediaSkeletonView(aspectRatio: 16/9)
                .frame(maxHeight: 200)
        }
        .padding(SpacingTokens.lg)
        .background(ColorTokens.background)
        .skeletonTheme(theme)
        .previewDisplayName("Increase Contrast Enabled")
    }
}
#endif

