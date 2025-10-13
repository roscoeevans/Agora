//
//  PostDetailEmptyStateView.swift
//  Agora
//
//  Created by Agora Team on 2024.
//

import SwiftUI
import DesignSystem

/// An empty state view displayed when a post is not found or unavailable
struct PostDetailEmptyStateView: View {
    var body: some View {
        VStack(spacing: SpacingTokens.lg) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(ColorTokens.warning)
                .symbolEffect(.pulse, isActive: true)
            
            Text("Post Not Found")
                .font(TypographyScale.title2)
                .foregroundColor(ColorTokens.primaryText)
            
            Text("This post may have been deleted or is no longer available.")
                .font(TypographyScale.body)
                .foregroundColor(ColorTokens.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(SpacingTokens.xl)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(ColorTokens.separator.opacity(0.2), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Post not found. This post may have been deleted or is no longer available.")
    }
}

#Preview("Empty State View") {
    PostDetailEmptyStateView()
        .padding()
}

#Preview("Empty State View - In Scroll View") {
    ScrollView {
        PostDetailEmptyStateView()
            .padding()
    }
}

#Preview("Empty State View - Dark Mode") {
    PostDetailEmptyStateView()
        .padding()
        .preferredColorScheme(.dark)
}

