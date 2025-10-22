//
//  ImageGridView.swift
//  DesignSystem
//
//  Image carousel with magnetic snapping using native SwiftUI TabView
//

import SwiftUI
import UIKitBridge

/// Image carousel that uses native TabView with magnetic snapping
public struct ImageGridView: View {
    let imageUrls: [String]
    let onImageTap: (Int) -> Void
    
    @State private var currentIndex = 0
    
    public init(imageUrls: [String], onImageTap: @escaping (Int) -> Void = { _ in }) {
        self.imageUrls = imageUrls
        self.onImageTap = onImageTap
    }
    
    public var body: some View {
        Group {
            switch imageUrls.count {
            case 1:
                singleImageLayout
            case 2...4:
                carouselLayout
            default:
                EmptyView()
            }
        }
    }
    
    // MARK: - Single Image Layout
    
    private var singleImageLayout: some View {
        ImageCell(url: imageUrls[0], index: 0, onTap: onImageTap)
            .aspectRatio(contentMode: .fit)
            .frame(maxHeight: 400)
            .clipShape(RoundedRectangle(cornerRadius: BorderRadiusTokens.md))
    }
    
    // MARK: - Carousel Layout (2-4 images)
    
    private var carouselLayout: some View {
        VStack(spacing: SpacingTokens.xs) {
            TabView(selection: $currentIndex) {
                ForEach(Array(imageUrls.enumerated()), id: \.offset) { index, url in
                    ImageCell(url: url, index: index, onTap: onImageTap)
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 250)
                        .clipShape(RoundedRectangle(cornerRadius: BorderRadiusTokens.md))
                        .tag(index)
                }
            }
            #if os(iOS)
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            #endif
            .frame(height: 250)
            
            // Custom page indicators for better control
            if imageUrls.count > 1 {
                HStack(spacing: SpacingTokens.xxs) {
                    ForEach(0..<imageUrls.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentIndex ? ColorTokens.agoraBrand : ColorTokens.separator)
                            .frame(width: 6, height: 6)
                            .animation(.easeInOut(duration: 0.2), value: currentIndex)
                    }
                }
                .padding(.top, SpacingTokens.xs)
            }
        }
    }
}

/// Individual image cell with tap handling
struct ImageCell: View {
    let url: String
    let index: Int
    let onTap: (Int) -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button {
            DesignSystemBridge.lightImpact()
            onTap(index)
        } label: {
            AsyncImage(url: URL(string: url)) { phase in
                switch phase {
                case .empty:
                    placeholderView
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    errorView
                @unknown default:
                    placeholderView
                }
            }
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
    
    private var placeholderView: some View {
        Rectangle()
            .fill(ColorTokens.separator.opacity(0.2))
            .overlay {
                ProgressView()
            }
    }
    
    private var errorView: some View {
        Rectangle()
            .fill(ColorTokens.separator.opacity(0.2))
            .overlay {
                Image(systemName: "photo")
                    .foregroundColor(ColorTokens.tertiaryText)
            }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Single Image") {
    ImageGridView(imageUrls: [
        "https://picsum.photos/800/600"
    ])
    .padding()
}

#Preview("Two Images Carousel") {
    ImageGridView(imageUrls: [
        "https://picsum.photos/800/600",
        "https://picsum.photos/800/601"
    ])
    .padding()
}

#Preview("Three Images Carousel") {
    ImageGridView(imageUrls: [
        "https://picsum.photos/800/600",
        "https://picsum.photos/800/601",
        "https://picsum.photos/800/602"
    ])
    .padding()
}

#Preview("Four Images Carousel") {
    ImageGridView(imageUrls: [
        "https://picsum.photos/800/600",
        "https://picsum.photos/800/601",
        "https://picsum.photos/800/602",
        "https://picsum.photos/800/603"
    ])
    .padding()
}
#endif