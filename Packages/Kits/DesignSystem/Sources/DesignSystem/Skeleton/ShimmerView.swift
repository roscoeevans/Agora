//
//  ShimmerView.swift
//  DesignSystem
//
//  Created by Agora Team on 2024.
//

import SwiftUI

/// A shimmer animation view that respects accessibility preferences.
///
/// ShimmerView provides a smooth animated gradient effect that moves across
/// skeleton placeholders to indicate loading state. The animation automatically
/// disables when Reduce Motion is enabled and adjusts contrast based on
/// accessibility preferences.
@available(iOS 26.0, *)
public struct ShimmerView: View {
    private let theme: any SkeletonTheme
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityDifferentiateWithoutColor) private var increaseContrast
    
    @State private var animationOffset: CGFloat = -1.0
    
    /// Creates a new ShimmerView with the specified theme.
    ///
    /// - Parameter theme: The skeleton theme containing animation parameters and colors
    public init(theme: any SkeletonTheme) {
        self.theme = theme
    }
    
    public var body: some View {
        GeometryReader { geometry in
            if reduceMotion {
                // Static placeholder with increased contrast if needed
                RoundedRectangle(cornerRadius: theme.cornerRadii.sm)
                    .fill(staticPlaceholderColor)
            } else {
                // Animated shimmer using TimelineView for smooth 60/120 FPS animation
                TimelineView(.animation) { timeline in
                    shimmerGradient(width: geometry.size.width)
                        .onAppear {
                            withAnimation(
                                .linear(duration: theme.shimmerDuration)
                                .repeatForever(autoreverses: false)
                            ) {
                                animationOffset = 1.0
                            }
                        }
                }
            }
        }
    }
    
    /// Static placeholder color that respects accessibility preferences
    private var staticPlaceholderColor: Color {
        if increaseContrast {
            return ColorTokens.separator
        } else {
            return theme.placeholderColor
        }
    }
    
    /// Creates the animated shimmer gradient
    private func shimmerGradient(width: CGFloat) -> some View {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: theme.placeholderColor.opacity(0.3), location: 0.0),
                .init(color: theme.placeholderColor.opacity(0.8), location: 0.5),
                .init(color: theme.placeholderColor.opacity(0.3), location: 1.0)
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
        .mask(
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(stops: createMaskStops()),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
    }
    
    /// Creates valid gradient stops for the shimmer mask
    private func createMaskStops() -> [Gradient.Stop] {
        let startLocation = max(0.0, animationOffset - 0.3)
        let centerLocation = max(0.0, min(1.0, animationOffset))
        let endLocation = min(1.0, animationOffset + 0.3)
        
        // Ensure locations are ordered and valid
        var stops: [Gradient.Stop] = []
        
        if startLocation < centerLocation {
            stops.append(.init(color: .clear, location: startLocation))
        }
        
        if centerLocation > startLocation && centerLocation < endLocation {
            stops.append(.init(color: .white, location: centerLocation))
        }
        
        if endLocation > centerLocation {
            stops.append(.init(color: .clear, location: endLocation))
        }
        
        // Ensure we always have at least one stop
        if stops.isEmpty {
            stops.append(.init(color: .clear, location: 0.0))
        }
        
        return stops
    }
}

/// Convenience shimmer view that uses the environment skeleton theme
@available(iOS 26.0, *)
public struct EnvironmentShimmerView: View {
    @Environment(\.skeletonTheme) private var theme
    
    public init() {}
    
    public var body: some View {
        ShimmerView(theme: theme)
    }
}

#if DEBUG
@available(iOS 26.0, *)
struct ShimmerView_Previews: PreviewProvider {
    static var previews: some View {
        let theme = DefaultSkeletonTheme()
        
        VStack(spacing: SpacingTokens.md) {
            // Different shapes with shimmer
            ShimmerView(theme: theme)
                .frame(width: 200, height: 20)
                .clipShape(RoundedRectangle(cornerRadius: BorderRadiusTokens.sm))
            
            ShimmerView(theme: theme)
                .frame(width: 150, height: 16)
                .clipShape(RoundedRectangle(cornerRadius: BorderRadiusTokens.sm))
            
            ShimmerView(theme: theme)
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            
            // Environment shimmer view
            EnvironmentShimmerView()
                .frame(width: 180, height: 18)
                .clipShape(RoundedRectangle(cornerRadius: BorderRadiusTokens.sm))
        }
        .padding(SpacingTokens.lg)
        .background(ColorTokens.background)
        .skeletonTheme(theme)
        .previewDisplayName("Light Mode")
        
        VStack(spacing: SpacingTokens.md) {
            // Different shapes with shimmer
            ShimmerView(theme: theme)
                .frame(width: 200, height: 20)
                .clipShape(RoundedRectangle(cornerRadius: BorderRadiusTokens.sm))
            
            ShimmerView(theme: theme)
                .frame(width: 150, height: 16)
                .clipShape(RoundedRectangle(cornerRadius: BorderRadiusTokens.sm))
            
            ShimmerView(theme: theme)
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            
            // Environment shimmer view
            EnvironmentShimmerView()
                .frame(width: 180, height: 18)
                .clipShape(RoundedRectangle(cornerRadius: BorderRadiusTokens.sm))
        }
        .padding(SpacingTokens.lg)
        .background(ColorTokens.background)
        .skeletonTheme(theme)
        .preferredColorScheme(.dark)
        .previewDisplayName("Dark Mode")
        
        VStack(spacing: SpacingTokens.md) {
            // Reduced motion preview - static placeholder
            RoundedRectangle(cornerRadius: BorderRadiusTokens.sm)
                .fill(ColorTokens.separator.opacity(0.3))
                .frame(width: 200, height: 20)
            
            Text("Reduce Motion Enabled")
                .font(TypographyScale.caption1)
                .foregroundColor(ColorTokens.secondaryText)
        }
        .padding(SpacingTokens.lg)
        .background(ColorTokens.background)
        .skeletonTheme(theme)
        .previewDisplayName("Reduce Motion")
    }
}
#endif