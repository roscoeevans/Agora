//
//  AgoraLoadingView.swift
//  Agora
//
//  Created by Agora Team on 2024.
//

import SwiftUI

/// A standardized loading view component for the Agora design system.
///
/// AgoraLoadingView provides consistent loading states and animations
/// following Apple's Human Interface Guidelines.
///
/// Example usage:
/// ```swift
/// AgoraLoadingView(message: "Loading your feed...")
/// ```
@available(iOS 26.0, *)
public struct AgoraLoadingView: View {
    /// Visual style variants for the loading view.
    public enum Style {
        /// Standard loading with progress indicator and message
        case standard
        /// Compact loading with just progress indicator
        case compact
        /// Overlay loading that covers the entire screen
        case overlay
        /// Inline loading for specific content areas
        case inline
    }
    
    let message: String?
    let style: Style
    let showProgressIndicator: Bool
    
    /// Creates a new AgoraLoadingView.
    ///
    /// - Parameters:
    ///   - message: Optional message to display below the progress indicator
    ///   - style: The visual style of the loading view. Defaults to `.standard`
    ///   - showProgressIndicator: Whether to show the progress indicator. Defaults to `true`
    public init(
        message: String? = nil,
        style: Style = .standard,
        showProgressIndicator: Bool = true
    ) {
        self.message = message
        self.style = style
        self.showProgressIndicator = showProgressIndicator
    }
    
    public var body: some View {
        Group {
            switch style {
            case .standard:
                standardLoadingView
            case .compact:
                compactLoadingView
            case .overlay:
                overlayLoadingView
            case .inline:
                inlineLoadingView
            }
        }
    }
    
    private var standardLoadingView: some View {
        VStack(spacing: SpacingTokens.md) {
            if showProgressIndicator {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(ColorTokens.agoraBrand)
            }
            
            if let message = message {
                Text(message)
                    .font(TypographyScale.callout)
                    .foregroundColor(ColorTokens.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(SpacingTokens.lg)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: BorderRadiusTokens.lg))
        .agoraShadow(ShadowTokens.prominent)
    }
    
    private var compactLoadingView: some View {
        HStack(spacing: SpacingTokens.sm) {
            if showProgressIndicator {
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(ColorTokens.agoraBrand)
            }
            
            if let message = message {
                Text(message)
                    .font(TypographyScale.footnote)
                    .foregroundColor(ColorTokens.secondaryText)
            }
        }
        .padding(SpacingTokens.sm)
    }
    
    private var overlayLoadingView: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: SpacingTokens.md) {
                if showProgressIndicator {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(ColorTokens.agoraBrand)
                }
                
                if let message = message {
                    Text(message)
                        .font(TypographyScale.callout)
                        .foregroundColor(ColorTokens.secondaryText)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(SpacingTokens.xl)
            .background(.thickMaterial, in: RoundedRectangle(cornerRadius: BorderRadiusTokens.xl))
            .agoraShadow(ShadowTokens.floating)
        }
    }
    
    private var inlineLoadingView: some View {
        HStack(spacing: SpacingTokens.sm) {
            if showProgressIndicator {
                ProgressView()
                    .scaleEffect(0.9)
                    .tint(ColorTokens.agoraBrand)
            }
            
            if let message = message {
                Text(message)
                    .font(TypographyScale.body)
                    .foregroundColor(ColorTokens.secondaryText)
            }
        }
        .padding(SpacingTokens.md)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: BorderRadiusTokens.sm))
        .agoraShadow(ShadowTokens.subtle)
    }
}

/// Convenience initializers for common loading states
@available(iOS 26.0, *)
public extension AgoraLoadingView {
    /// Creates a loading view for feed loading
    static func feedLoading() -> AgoraLoadingView {
        AgoraLoadingView(
            message: "Loading your feed...",
            style: .standard
        )
    }
    
    /// Creates a loading view for profile loading
    static func profileLoading() -> AgoraLoadingView {
        AgoraLoadingView(
            message: "Loading profile...",
            style: .standard
        )
    }
    
    /// Creates a loading view for posting
    static func posting() -> AgoraLoadingView {
        AgoraLoadingView(
            message: "Posting...",
            style: .overlay
        )
    }
    
    /// Creates a compact loading view for buttons
    static func buttonLoading() -> AgoraLoadingView {
        AgoraLoadingView(
            message: nil,
            style: .compact
        )
    }
    
    /// Creates an inline loading view for content areas
    static func contentLoading() -> AgoraLoadingView {
        AgoraLoadingView(
            message: "Loading...",
            style: .inline
        )
    }
}

#if DEBUG
@available(iOS 26.0, *)
struct AgoraLoadingView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: SpacingTokens.lg) {
            // Different styles
            AgoraLoadingView(message: "Standard Loading", style: .standard)
            AgoraLoadingView(message: "Compact Loading", style: .compact)
            AgoraLoadingView(message: "Inline Loading", style: .inline)
            
            // Convenience initializers
            AgoraLoadingView.feedLoading()
            AgoraLoadingView.profileLoading()
            AgoraLoadingView.buttonLoading()
            AgoraLoadingView.contentLoading()
        }
        .padding(SpacingTokens.md)
        .background(ColorTokens.background)
        .previewDisplayName("Light Mode")
        
        VStack(spacing: SpacingTokens.lg) {
            // Different styles
            AgoraLoadingView(message: "Standard Loading", style: .standard)
            AgoraLoadingView(message: "Compact Loading", style: .compact)
            AgoraLoadingView(message: "Inline Loading", style: .inline)
            
            // Convenience initializers
            AgoraLoadingView.feedLoading()
            AgoraLoadingView.profileLoading()
            AgoraLoadingView.buttonLoading()
            AgoraLoadingView.contentLoading()
        }
        .padding(SpacingTokens.md)
        .background(ColorTokens.background)
        .preferredColorScheme(.dark)
        .previewDisplayName("Dark Mode")
    }
}
#endif
