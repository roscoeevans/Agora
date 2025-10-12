import SwiftUI
import DesignSystem

/// Simple loading view shown during auth state initialization
struct LoadingView: View {
    var body: some View {
        ZStack {
            ColorTokens.background
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // App icon or logo
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(ColorTokens.primary)
                    .symbolRenderingMode(.hierarchical)
                
                ProgressView()
                    .controlSize(.large)
                    .tint(ColorTokens.primary)
            }
        }
        .accessibilityLabel("Loading")
    }
}

#Preview {
    LoadingView()
}

