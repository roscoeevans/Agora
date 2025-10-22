//
//  SkeletonModifier.swift
//  DesignSystem
//
//  Created by Agora Team on 2024.
//

import SwiftUI

/// SwiftUI modifier that applies skeleton loading state to any view.
///
/// The skeleton modifier integrates redaction and shimmer animation to create
/// smooth loading placeholders that respect accessibility preferences.
@available(iOS 26.0, *)
public struct SkeletonModifier: ViewModifier {
    let isActive: Bool
    
    @Environment(\.skeletonTheme) private var theme
    @Environment(\.skeletonViewStyle) private var style
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    public init(isActive: Bool) {
        self.isActive = isActive
    }
    
    public func body(content: Content) -> some View {
        let configuration = SkeletonStyleConfiguration(
            isActive: isActive,
            content: AnyView(content),
            theme: theme,
            shimmerEnabled: !reduceMotion
        )
        
        AnyView(style.makeBody(configuration: configuration))
            .skeletonAccessibilityHidden(isActive)
            .skeletonDynamicType(isActive: isActive)
    }
}

@available(iOS 26.0, *)
public extension View {
    /// Applies skeleton loading state to this view.
    ///
    /// When `isActive` is true, the view will be replaced with a skeleton placeholder
    /// that includes redaction and optional shimmer animation. The skeleton automatically
    /// respects accessibility preferences like Reduce Motion.
    ///
    /// Example usage:
    /// ```swift
    /// Text("Hello, World!")
    ///     .skeleton(isActive: isLoading)
    /// ```
    ///
    /// - Parameter isActive: Whether the skeleton should be displayed
    /// - Returns: A view that shows skeleton loading when active
    func skeleton(isActive: Bool) -> some View {
        modifier(SkeletonModifier(isActive: isActive))
    }
}

/// Specialized skeleton modifier for text content
@available(iOS 26.0, *)
public struct TextSkeletonModifier: ViewModifier {
    let isActive: Bool
    let lineCount: Int
    let lastLineWidth: CGFloat
    
    @Environment(\.skeletonTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    public init(isActive: Bool, lineCount: Int = 1, lastLineWidth: CGFloat = 0.6) {
        self.isActive = isActive
        self.lineCount = lineCount
        self.lastLineWidth = lastLineWidth
    }
    
    public func body(content: Content) -> some View {
        Group {
            if isActive {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(0..<lineCount, id: \.self) { index in
                        RoundedRectangle(cornerRadius: theme.cornerRadii.xs)
                            .fill(theme.placeholderColor)
                            .frame(height: 16)
                            .frame(maxWidth: index == lineCount - 1 ? .infinity : nil)
                            .scaleEffect(x: index == lineCount - 1 ? lastLineWidth : 1.0, anchor: .leading)
                            .overlay(
                                Group {
                                    if !reduceMotion {
                                        ShimmerView(theme: theme)
                                            .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadii.xs))
                                    }
                                }
                            )
                    }
                }
                .skeletonAccessibilityHidden(true)
                .skeletonDynamicType(isActive: true)
                .animation(.easeInOut(duration: theme.crossfadeDuration), value: isActive)
            } else {
                content
                    .animation(.easeInOut(duration: theme.crossfadeDuration), value: isActive)
            }
        }
    }
}

@available(iOS 26.0, *)
public extension View {
    /// Applies skeleton loading specifically designed for text content.
    ///
    /// This modifier creates multiple lines of skeleton placeholders with
    /// natural text-like proportions.
    ///
    /// - Parameters:
    ///   - isActive: Whether the skeleton should be displayed
    ///   - lineCount: Number of skeleton lines to display
    ///   - lastLineWidth: Width ratio of the last line (0.0 to 1.0)
    /// - Returns: A view that shows text skeleton loading when active
    func textSkeleton(
        isActive: Bool,
        lineCount: Int = 1,
        lastLineWidth: CGFloat = 0.6
    ) -> some View {
        modifier(TextSkeletonModifier(
            isActive: isActive,
            lineCount: lineCount,
            lastLineWidth: lastLineWidth
        ))
    }
}

/// Specialized skeleton modifier for circular content like avatars
@available(iOS 26.0, *)
public struct CircularSkeletonModifier: ViewModifier {
    let isActive: Bool
    let size: CGFloat
    
    @Environment(\.skeletonTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    public init(isActive: Bool, size: CGFloat) {
        self.isActive = isActive
        self.size = size
    }
    
    public func body(content: Content) -> some View {
        Group {
            if isActive {
                Circle()
                    .fill(theme.placeholderColor)
                    .frame(width: size, height: size)
                    .overlay(
                        Group {
                            if !reduceMotion {
                                ShimmerView(theme: theme)
                                    .clipShape(Circle())
                            }
                        }
                    )
                    .skeletonAccessibilityHidden(true)
                    .skeletonDynamicType(isActive: true)
                    .animation(.easeInOut(duration: theme.crossfadeDuration), value: isActive)
            } else {
                content
                    .animation(.easeInOut(duration: theme.crossfadeDuration), value: isActive)
            }
        }
    }
}

@available(iOS 26.0, *)
public extension View {
    /// Applies skeleton loading specifically designed for circular content.
    ///
    /// This modifier creates a circular skeleton placeholder, ideal for avatars
    /// and profile images.
    ///
    /// - Parameters:
    ///   - isActive: Whether the skeleton should be displayed
    ///   - size: The diameter of the circular skeleton
    /// - Returns: A view that shows circular skeleton loading when active
    func circularSkeleton(isActive: Bool, size: CGFloat) -> some View {
        modifier(CircularSkeletonModifier(isActive: isActive, size: size))
    }
}

#if DEBUG
@available(iOS 26.0, *)
struct SkeletonModifier_Previews: PreviewProvider {
    static var previews: some View {
        let theme = DefaultSkeletonTheme()
        
        VStack(spacing: SpacingTokens.lg) {
            // Basic skeleton
            Text("This is some sample text")
                .font(TypographyScale.body)
                .skeleton(isActive: true)
            
            // Text skeleton with multiple lines
            VStack(alignment: .leading) {
                Text("Title")
                    .font(TypographyScale.headline)
                    .textSkeleton(isActive: true, lineCount: 1)
                
                Text("Body content")
                    .font(TypographyScale.body)
                    .textSkeleton(isActive: true, lineCount: 3, lastLineWidth: 0.7)
            }
            
            // Circular skeleton for avatar
            AsyncImage(url: URL(string: "https://example.com/avatar.jpg")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray
            }
            .circularSkeleton(isActive: true, size: 40)
            
            // Loaded content examples
            Group {
                Text("This content is loaded")
                    .font(TypographyScale.body)
                    .skeleton(isActive: false)
                
                Text("Multi-line loaded content that shows how the skeleton transitions to real content")
                    .font(TypographyScale.body)
                    .textSkeleton(isActive: false, lineCount: 2)
            }
        }
        .padding(SpacingTokens.lg)
        .background(ColorTokens.background)
        .skeletonTheme(theme)
        .previewDisplayName("Light Mode")
        
        VStack(spacing: SpacingTokens.lg) {
            // Basic skeleton
            Text("This is some sample text")
                .font(TypographyScale.body)
                .skeleton(isActive: true)
            
            // Text skeleton with multiple lines
            VStack(alignment: .leading) {
                Text("Title")
                    .font(TypographyScale.headline)
                    .textSkeleton(isActive: true, lineCount: 1)
                
                Text("Body content")
                    .font(TypographyScale.body)
                    .textSkeleton(isActive: true, lineCount: 3, lastLineWidth: 0.7)
            }
            
            // Circular skeleton for avatar
            AsyncImage(url: URL(string: "https://example.com/avatar.jpg")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray
            }
            .circularSkeleton(isActive: true, size: 40)
        }
        .padding(SpacingTokens.lg)
        .background(ColorTokens.background)
        .skeletonTheme(theme)
        .preferredColorScheme(.dark)
        .previewDisplayName("Dark Mode")
    }
}
#endif