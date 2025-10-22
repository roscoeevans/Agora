//
//  SkeletonErrorView.swift
//  DesignSystem
//
//  Created by Agora Team on 2024.
//

import SwiftUI

/// Error view component specifically designed for skeleton loading failures.
/// Provides inline error display with retry functionality for feed rows.
@available(iOS 26.0, *)
public struct SkeletonErrorView: View {
    /// Error display style variants
    public enum Style {
        /// Inline error for individual feed rows
        case inline
        /// Full error for entire feed failure
        case full
        /// Compact error for smaller areas
        case compact
    }
    
    let error: Error
    let style: Style
    let retryAction: (() -> Void)?
    
    /// Creates a new SkeletonErrorView.
    ///
    /// - Parameters:
    ///   - error: The error that occurred
    ///   - style: The visual style of the error view
    ///   - retryAction: Optional retry action
    public init(
        error: Error,
        style: Style = .inline,
        retryAction: (() -> Void)? = nil
    ) {
        self.error = error
        self.style = style
        self.retryAction = retryAction
    }
    
    public var body: some View {
        switch style {
        case .inline:
            inlineErrorView
        case .full:
            fullErrorView
        case .compact:
            compactErrorView
        }
    }
    
    private var inlineErrorView: some View {
        HStack(spacing: SpacingTokens.sm) {
            // Error icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: IconSizeTokens.sm))
                .foregroundColor(ColorTokens.error)
            
            // Error message
            VStack(alignment: .leading, spacing: SpacingTokens.xxs) {
                Text("Failed to load")
                    .font(TypographyScale.calloutEmphasized)
                    .foregroundColor(ColorTokens.primaryText)
                
                Text(errorMessage)
                    .font(TypographyScale.caption1)
                    .foregroundColor(ColorTokens.secondaryText)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Retry button
            if let retryAction = retryAction {
                AgoraButton(
                    "Retry",
                    style: .secondary,
                    size: .small,
                    action: retryAction
                )
                .frame(width: 60)
            }
        }
        .padding(SpacingTokens.md)
        .background(ColorTokens.errorBackground)
        .cornerRadius(BorderRadiusTokens.md)
        .overlay(
            RoundedRectangle(cornerRadius: BorderRadiusTokens.md)
                .stroke(ColorTokens.error.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var fullErrorView: some View {
        VStack(spacing: SpacingTokens.lg) {
            // Error icon
            Image(systemName: "wifi.slash")
                .font(.system(size: IconSizeTokens.huge))
                .foregroundColor(ColorTokens.error)
                .symbolEffect(.pulse, isActive: true)
            
            // Error content
            VStack(spacing: SpacingTokens.sm) {
                Text("Couldn't Load Feed")
                    .font(TypographyScale.title2)
                    .foregroundColor(ColorTokens.primaryText)
                    .multilineTextAlignment(.center)
                
                Text(errorMessage)
                    .font(TypographyScale.body)
                    .foregroundColor(ColorTokens.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
            
            // Retry button
            if let retryAction = retryAction {
                AgoraButton(
                    "Try Again",
                    style: .primary,
                    action: retryAction
                )
                .frame(maxWidth: 200)
            }
        }
        .padding(SpacingTokens.xl)
        .background(.regularMaterial)
        .cornerRadius(BorderRadiusTokens.lg)
        .agoraShadow(ShadowTokens.standard)
    }
    
    private var compactErrorView: some View {
        HStack(spacing: SpacingTokens.xs) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: IconSizeTokens.xs))
                .foregroundColor(ColorTokens.error)
            
            Text("Error")
                .font(TypographyScale.caption1)
                .foregroundColor(ColorTokens.error)
            
            if let retryAction = retryAction {
                Button("Retry") {
                    retryAction()
                }
                .font(TypographyScale.caption1)
                .foregroundColor(ColorTokens.agoraBrand)
            }
        }
        .padding(.horizontal, SpacingTokens.sm)
        .padding(.vertical, SpacingTokens.xs)
        .background(ColorTokens.errorBackground)
        .cornerRadius(BorderRadiusTokens.sm)
    }
    
    private var errorMessage: String {
        // Provide user-friendly error messages
        if error.localizedDescription.contains("network") || 
           error.localizedDescription.contains("connection") ||
           error.localizedDescription.contains("internet") {
            return "Check your connection and try again."
        } else if error.localizedDescription.contains("timeout") {
            return "Request timed out. Please try again."
        } else if error.localizedDescription.contains("server") ||
                  error.localizedDescription.contains("500") {
            return "Server error. Please try again later."
        } else {
            return "Something went wrong. Please try again."
        }
    }
}

/// Convenience initializers for common error scenarios
@available(iOS 26.0, *)
public extension SkeletonErrorView {
    /// Creates an inline error for individual feed row failures
    static func feedRowError(
        error: Error,
        retryAction: @escaping () -> Void
    ) -> SkeletonErrorView {
        SkeletonErrorView(
            error: error,
            style: .inline,
            retryAction: retryAction
        )
    }
    
    /// Creates a full error for complete feed failures
    static func feedError(
        error: Error,
        retryAction: @escaping () -> Void
    ) -> SkeletonErrorView {
        SkeletonErrorView(
            error: error,
            style: .full,
            retryAction: retryAction
        )
    }
    
    /// Creates a compact error for pagination failures
    static func paginationError(
        error: Error,
        retryAction: @escaping () -> Void
    ) -> SkeletonErrorView {
        SkeletonErrorView(
            error: error,
            style: .compact,
            retryAction: retryAction
        )
    }
}

#if DEBUG
@available(iOS 26.0, *)
struct SkeletonErrorView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: SpacingTokens.lg) {
            // Inline error
            SkeletonErrorView.feedRowError(
                error: NSError(domain: "NetworkError", code: -1009, userInfo: [
                    NSLocalizedDescriptionKey: "The Internet connection appears to be offline."
                ]),
                retryAction: { print("Retry tapped") }
            )
            
            // Full error
            SkeletonErrorView.feedError(
                error: NSError(domain: "ServerError", code: 500, userInfo: [
                    NSLocalizedDescriptionKey: "Internal server error"
                ]),
                retryAction: { print("Retry tapped") }
            )
            
            // Compact error
            SkeletonErrorView.paginationError(
                error: NSError(domain: "TimeoutError", code: -1001, userInfo: [
                    NSLocalizedDescriptionKey: "Request timeout"
                ]),
                retryAction: { print("Retry tapped") }
            )
        }
        .padding(SpacingTokens.md)
        .background(ColorTokens.background)
        .previewDisplayName("Light Mode")
        
        VStack(spacing: SpacingTokens.lg) {
            // Inline error
            SkeletonErrorView.feedRowError(
                error: NSError(domain: "NetworkError", code: -1009, userInfo: [
                    NSLocalizedDescriptionKey: "The Internet connection appears to be offline."
                ]),
                retryAction: { print("Retry tapped") }
            )
            
            // Full error
            SkeletonErrorView.feedError(
                error: NSError(domain: "ServerError", code: 500, userInfo: [
                    NSLocalizedDescriptionKey: "Internal server error"
                ]),
                retryAction: { print("Retry tapped") }
            )
            
            // Compact error
            SkeletonErrorView.paginationError(
                error: NSError(domain: "TimeoutError", code: -1001, userInfo: [
                    NSLocalizedDescriptionKey: "Request timeout"
                ]),
                retryAction: { print("Retry tapped") }
            )
        }
        .padding(SpacingTokens.md)
        .background(ColorTokens.background)
        .preferredColorScheme(.dark)
        .previewDisplayName("Dark Mode")
    }
}
#endif