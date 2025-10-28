//
//  LiquidGlassTransitions.swift
//  DesignSystem
//
//  Created by Agora Team on 2024.
//

import SwiftUI

/// Custom blur transition for Liquid Glass effects.
@available(iOS 26.0, *)
private struct BlurTransitionModifier: ViewModifier {
    let isActive: Bool
    
    func body(content: Content) -> some View {
        content
            .blur(radius: isActive ? 0 : 8)
    }
}

@available(iOS 26.0, *)
private extension AnyTransition {
    /// Blur transition that animates blur radius from 8 to 0.
    static var blurEffect: AnyTransition {
        .modifier(
            active: BlurTransitionModifier(isActive: false),
            identity: BlurTransitionModifier(isActive: true)
        )
    }
}

/// Liquid Glass design system transitions for smooth, material-based animations.
///
/// These transitions provide consistent animation patterns across the Agora app,
/// following the Liquid Glass design language with blur, scale, and material effects.
@available(iOS 26.0, *)
public extension AnyTransition {
    
    /// Standard Liquid Glass transition for content appearing/disappearing.
    ///
    /// Uses a combination of scale (95%), opacity, and blur to create a smooth
    /// material-based transition effect. Perfect for empty states, cards, and panels.
    ///
    /// Example usage:
    /// ```swift
    /// EmptyStateView()
    ///     .transition(.liquidGlass)
    /// ```
    static var liquidGlass: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.95, anchor: .center)
                .combined(with: .opacity)
                .combined(with: .blurEffect),
            removal: .opacity
        )
    }
    
    /// Prominent Liquid Glass transition with more pronounced scale effect.
    ///
    /// Uses larger scale (0.85) for more dramatic entrance animations.
    /// Best for full-screen modals, important announcements, or hero content.
    ///
    /// Example usage:
    /// ```swift
    /// OnboardingView()
    ///     .transition(.liquidGlassProminent)
    /// ```
    static var liquidGlassProminent: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.85, anchor: .center)
                .combined(with: .opacity)
                .combined(with: .blurEffect),
            removal: .scale(scale: 0.95)
                .combined(with: .opacity)
        )
    }
    
    /// Subtle Liquid Glass transition with minimal scale effect.
    ///
    /// Uses gentle scale (0.98) for subtle transitions.
    /// Perfect for list items, inline content, or frequent state changes.
    ///
    /// Example usage:
    /// ```swift
    /// NotificationRow()
    ///     .transition(.liquidGlassSubtle)
    /// ```
    static var liquidGlassSubtle: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.98, anchor: .center)
                .combined(with: .opacity)
                .combined(with: .blurEffect),
            removal: .opacity
        )
    }
    
    /// Directional Liquid Glass transition from bottom.
    ///
    /// Combines push from bottom with the standard Liquid Glass effects.
    /// Best for sheets, bottom panels, or contextual content.
    ///
    /// Example usage:
    /// ```swift
    /// ActionSheet()
    ///     .transition(.liquidGlassFromBottom)
    /// ```
    static var liquidGlassFromBottom: AnyTransition {
        .asymmetric(
            insertion: .push(from: .bottom)
                .combined(with: .opacity)
                .combined(with: .blurEffect),
            removal: .push(from: .top)
                .combined(with: .opacity)
        )
    }
    
    /// Directional Liquid Glass transition from top.
    ///
    /// Combines push from top with the standard Liquid Glass effects.
    /// Best for navigation bars, banners, or top-anchored content.
    ///
    /// Example usage:
    /// ```swift
    /// Banner()
    ///     .transition(.liquidGlassFromTop)
    /// ```
    static var liquidGlassFromTop: AnyTransition {
        .asymmetric(
            insertion: .push(from: .top)
                .combined(with: .opacity)
                .combined(with: .blurEffect),
            removal: .push(from: .bottom)
                .combined(with: .opacity)
        )
    }
}

/// Standard animation curves for Liquid Glass transitions.
///
/// These animation values are tuned for smooth, natural-feeling transitions
/// that match iOS 26 system animations and the Liquid Glass design language.
@available(iOS 26.0, *)
public extension Animation {
    
    /// Standard spring animation for Liquid Glass transitions.
    ///
    /// Response: 0.5s, Damping: 0.8 (slightly bouncy)
    /// Use for most transitions, empty states, and content changes.
    static let liquidGlass = Animation.spring(response: 0.5, dampingFraction: 0.8)
    
    /// Gentle spring animation for subtle Liquid Glass transitions.
    ///
    /// Response: 0.4s, Damping: 0.9 (minimal bounce)
    /// Use for list items, inline content, or frequent state changes.
    static let liquidGlassSubtle = Animation.spring(response: 0.4, dampingFraction: 0.9)
    
    /// Prominent spring animation for dramatic Liquid Glass transitions.
    ///
    /// Response: 0.6s, Damping: 0.7 (more bouncy)
    /// Use for modals, onboarding, or important announcements.
    static let liquidGlassProminent = Animation.spring(response: 0.6, dampingFraction: 0.7)
    
    /// Smooth ease-in-out animation for Liquid Glass transitions.
    ///
    /// Duration: 0.35s
    /// Use when you need predictable timing without spring physics.
    static let liquidGlassSmooth = Animation.easeInOut(duration: 0.35)
}

/// View modifier for applying Liquid Glass transitions with consistent animations.
@available(iOS 26.0, *)
public struct LiquidGlassTransitionModifier: ViewModifier {
    let transition: AnyTransition
    let animation: Animation
    
    public func body(content: Content) -> some View {
        content
            .transition(transition)
    }
}

@available(iOS 26.0, *)
public extension View {
    /// Applies a Liquid Glass transition to this view.
    ///
    /// Example usage:
    /// ```swift
    /// EmptyStateView()
    ///     .liquidGlassTransition(.liquidGlass)
    /// ```
    ///
    /// - Parameters:
    ///   - transition: The Liquid Glass transition to apply
    ///   - animation: The animation curve (defaults to `.liquidGlass`)
    func liquidGlassTransition(
        _ transition: AnyTransition = .liquidGlass,
        animation: Animation = .liquidGlass
    ) -> some View {
        self.modifier(LiquidGlassTransitionModifier(transition: transition, animation: animation))
    }
}

#if DEBUG
@available(iOS 26.0, *)
struct LiquidGlassTransitions_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: SpacingTokens.xl) {
            TransitionDemoView(
                title: "Standard",
                transition: .liquidGlass,
                animation: .liquidGlass
            )
            
            TransitionDemoView(
                title: "Prominent",
                transition: .liquidGlassProminent,
                animation: .liquidGlassProminent
            )
            
            TransitionDemoView(
                title: "Subtle",
                transition: .liquidGlassSubtle,
                animation: .liquidGlassSubtle
            )
            
            TransitionDemoView(
                title: "From Bottom",
                transition: .liquidGlassFromBottom,
                animation: .liquidGlass
            )
        }
        .padding(SpacingTokens.lg)
        .background(ColorTokens.background)
    }
}

@available(iOS 26.0, *)
private struct TransitionDemoView: View {
    let title: String
    let transition: AnyTransition
    let animation: Animation
    
    @State private var isVisible = false
    
    var body: some View {
        VStack(spacing: SpacingTokens.md) {
            Text(title)
                .font(TypographyScale.headline)
            
            Button("Toggle") {
                withAnimation(animation) {
                    isVisible.toggle()
                }
            }
            
            if isVisible {
                RoundedRectangle(cornerRadius: BorderRadiusTokens.md)
                    .fill(.thinMaterial)
                    .frame(height: 100)
                    .overlay {
                        Text("Content")
                            .foregroundColor(ColorTokens.primaryText)
                    }
                    .transition(transition)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(SpacingTokens.md)
        .background(ColorTokens.secondaryBackground)
        .cornerRadius(BorderRadiusTokens.lg)
    }
}
#endif

