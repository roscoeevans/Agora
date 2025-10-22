//
//  LinkPreviewDisplayCard.swift
//  DesignSystem
//
//  Link preview display card for posts (read-only)
//

import SwiftUI
import UIKitBridge

/// Link preview display card for posts (read-only, tappable)
public struct LinkPreviewDisplayCard: View {
    let url: String
    let title: String?
    let description: String?
    let imageUrl: String?
    let siteName: String?
    
    @State private var isPressed = false
    
    public init(
        url: String,
        title: String? = nil,
        description: String? = nil,
        imageUrl: String? = nil,
        siteName: String? = nil
    ) {
        self.url = url
        self.title = title
        self.description = description
        self.imageUrl = imageUrl
        self.siteName = siteName
    }
    
    public var body: some View {
        Button {
            DesignSystemBridge.lightImpact()
            openURL()
        } label: {
            HStack(alignment: .top, spacing: SpacingTokens.sm) {
                // Preview image (if available)
                if let imageUrl = imageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            placeholderImage
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            placeholderImage
                        @unknown default:
                            placeholderImage
                        }
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: BorderRadiusTokens.sm))
                } else {
                    placeholderImage
                        .frame(width: 80, height: 80)
                }
                
                // Text content
                VStack(alignment: .leading, spacing: SpacingTokens.xxs) {
                    if let title = title {
                        Text(title)
                            .font(TypographyScale.callout)
                            .fontWeight(.medium)
                            .foregroundColor(ColorTokens.primaryText)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    
                    if let description = description {
                        Text(description)
                            .font(TypographyScale.caption1)
                            .foregroundColor(ColorTokens.secondaryText)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    
                    if let siteName = siteName {
                        Text(siteName)
                            .font(TypographyScale.caption2)
                            .foregroundColor(ColorTokens.tertiaryText)
                    }
                }
                
                Spacer()
                
                // External link icon
                Image(systemName: "arrow.up.right.square")
                    .font(.system(size: 16))
                    .foregroundColor(ColorTokens.tertiaryText)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding(SpacingTokens.md)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: BorderRadiusTokens.md))
        .overlay(
            RoundedRectangle(cornerRadius: BorderRadiusTokens.md)
                .stroke(ColorTokens.separator.opacity(0.3), lineWidth: 1)
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .accessibilityLabel("Open link: \(title ?? url)")
    }
    
    private var placeholderImage: some View {
        RoundedRectangle(cornerRadius: BorderRadiusTokens.sm)
            .fill(ColorTokens.separator.opacity(0.2))
            .overlay {
                Image(systemName: "link")
                    .foregroundColor(ColorTokens.tertiaryText)
            }
    }
    
    private func openURL() {
        guard let url = URL(string: url) else { return }
        
        #if os(iOS)
        UIApplication.shared.open(url)
        #endif
    }
}

// MARK: - Convenience Initializer

// MARK: - Supporting Types

public struct LinkPreview {
    let url: String
    let title: String?
    let description: String?
    let imageUrl: String?
    let siteName: String?
}

extension LinkPreviewDisplayCard {
    /// Create from LinkPreview struct
    public init(preview: LinkPreview) {
        self.init(
            url: preview.url,
            title: preview.title,
            description: preview.description,
            imageUrl: preview.imageUrl,
            siteName: preview.siteName
        )
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Link Preview Display Card") {
    VStack(spacing: SpacingTokens.lg) {
        LinkPreviewDisplayCard(
            url: "https://example.com",
            title: "Example Website - Learn More About Our Product",
            description: "A comprehensive guide to getting started with our amazing product that will change your life forever.",
            imageUrl: "https://picsum.photos/200/200",
            siteName: "example.com"
        )
        
        LinkPreviewDisplayCard(
            url: "https://apple.com",
            title: "Apple",
            description: nil,
            imageUrl: nil,
            siteName: "apple.com"
        )
        
        LinkPreviewDisplayCard(
            url: "https://youtube.com/watch?v=example",
            title: "Amazing Video Tutorial",
            description: "Learn how to build amazing apps with this step-by-step tutorial",
            imageUrl: "https://picsum.photos/300/200",
            siteName: "YouTube"
        )
    }
    .padding()
    .background(ColorTokens.background)
}
#endif
