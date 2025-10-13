//
//  PostDetailLoadingView.swift
//  Agora
//
//  Created by Agora Team on 2024.
//

import SwiftUI
import DesignSystem

/// A loading state view displayed while fetching post details
struct PostDetailLoadingView: View {
    var body: some View {
        VStack(spacing: SpacingTokens.md) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading post...")
                .font(TypographyScale.callout)
                .foregroundColor(ColorTokens.secondaryText)
        }
        .padding(SpacingTokens.xl)
    }
}

#Preview("Loading View") {
    PostDetailLoadingView()
}

#Preview("Loading View - In Scroll View") {
    ScrollView {
        PostDetailLoadingView()
    }
}

#Preview("Loading View - Dark Mode") {
    PostDetailLoadingView()
        .preferredColorScheme(.dark)
}

