//
//  LinkPreviewCard.swift
//  Agora
//
//  Link preview card for compose view
//

import SwiftUI
import UIKitBridge
import DesignSystem

/// Link preview card component for compose
public struct LinkPreviewCard: View {
    let preview: LinkPreview
    let onRemove: () -> Void
    @State private var isPressed = false
    
    public init(preview: LinkPreview, onRemove: @escaping () -> Void) {
        self.preview = preview
        self.onRemove = onRemove
    }
    
    public var body: some View {
        HStack(alignment: .top, spacing: SpacingTokens.sm) {
            // Preview image (if available)
            if let imageUrl = preview.imageUrl, let url = URL(string: imageUrl) {
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
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: BorderRadiusTokens.sm))
            }
            
            // Text content
            VStack(alignment: .leading, spacing: SpacingTokens.xxs) {
                if let title = preview.title {
                    Text(title)
                        .font(TypographyScale.callout)
                        .fontWeight(.medium)
                        .foregroundColor(ColorTokens.primaryText)
                        .lineLimit(2)
                }
                
                if let siteName = preview.siteName {
                    Text(siteName)
                        .font(TypographyScale.caption1)
                        .foregroundColor(ColorTokens.tertiaryText)
                }
            }
            
            Spacer()
            
            // Remove button
            Button {
                // Add haptic feedback
                DesignSystemBridge.lightImpact()
                
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: IconSizeTokens.md))
                    .foregroundColor(ColorTokens.tertiaryText)
                    .frame(width: 44, height: 44) // Ensure adequate touch target
            }
            .accessibilityLabel("Remove link preview")
        }
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
    }
    
    private var placeholderImage: some View {
        RoundedRectangle(cornerRadius: BorderRadiusTokens.sm)
            .fill(ColorTokens.separator.opacity(0.2))
            .frame(width: 60, height: 60)
            .overlay {
                Image(systemName: "link")
                    .foregroundColor(ColorTokens.tertiaryText)
            }
    }
}

#Preview("Link Preview Card") {
    VStack(spacing: SpacingTokens.lg) {
        LinkPreviewCard(
            preview: LinkPreview(
                url: "https://example.com",
                title: "Example Website - Learn More About Our Product",
                description: "A comprehensive guide to getting started",
                imageUrl: nil,
                siteName: "example.com"
            ),
            onRemove: {}
        )
        
        LinkPreviewCard(
            preview: LinkPreview(
                url: "https://apple.com",
                title: "Apple",
                description: nil,
                imageUrl: nil,
                siteName: "apple.com"
            ),
            onRemove: {}
        )
    }
    .padding()
}

