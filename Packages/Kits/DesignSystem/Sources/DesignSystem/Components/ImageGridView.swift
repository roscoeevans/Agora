//
//  ImageGridView.swift
//  Agora
//
//  Smart grid layout for 1-4 images
//

import SwiftUI

/// Smart image grid that adapts layout based on image count
public struct ImageGridView: View {
    let imageUrls: [String]
    let onImageTap: (Int) -> Void
    
    public init(imageUrls: [String], onImageTap: @escaping (Int) -> Void = { _ in }) {
        self.imageUrls = imageUrls
        self.onImageTap = onImageTap
    }
    
    public var body: some View {
        Group {
            switch imageUrls.count {
            case 1:
                singleImageLayout
            case 2:
                twoImageLayout
            case 3:
                threeImageLayout
            case 4:
                fourImageLayout
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
    
    // MARK: - Two Image Layout (Side by Side)
    
    private var twoImageLayout: some View {
        HStack(spacing: 2) {
            ImageCell(url: imageUrls[0], index: 0, onTap: onImageTap)
            ImageCell(url: imageUrls[1], index: 1, onTap: onImageTap)
        }
        .frame(height: 250)
        .clipShape(RoundedRectangle(cornerRadius: BorderRadiusTokens.md))
    }
    
    // MARK: - Three Image Layout (1 large + 2 stacked)
    
    private var threeImageLayout: some View {
        HStack(spacing: 2) {
            // Large left image
            ImageCell(url: imageUrls[0], index: 0, onTap: onImageTap)
            
            // Two stacked right images
            VStack(spacing: 2) {
                ImageCell(url: imageUrls[1], index: 1, onTap: onImageTap)
                ImageCell(url: imageUrls[2], index: 2, onTap: onImageTap)
            }
        }
        .frame(height: 250)
        .clipShape(RoundedRectangle(cornerRadius: BorderRadiusTokens.md))
    }
    
    // MARK: - Four Image Layout (2x2 Grid)
    
    private var fourImageLayout: some View {
        VStack(spacing: 2) {
            HStack(spacing: 2) {
                ImageCell(url: imageUrls[0], index: 0, onTap: onImageTap)
                ImageCell(url: imageUrls[1], index: 1, onTap: onImageTap)
            }
            HStack(spacing: 2) {
                ImageCell(url: imageUrls[2], index: 2, onTap: onImageTap)
                ImageCell(url: imageUrls[3], index: 3, onTap: onImageTap)
            }
        }
        .frame(height: 250)
        .clipShape(RoundedRectangle(cornerRadius: BorderRadiusTokens.md))
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
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
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

#Preview("Single Image") {
    ImageGridView(imageUrls: [
        "https://picsum.photos/800/600"
    ])
    .padding()
}

#Preview("Two Images") {
    ImageGridView(imageUrls: [
        "https://picsum.photos/800/600",
        "https://picsum.photos/800/601"
    ])
    .padding()
}

#Preview("Three Images") {
    ImageGridView(imageUrls: [
        "https://picsum.photos/800/600",
        "https://picsum.photos/800/601",
        "https://picsum.photos/800/602"
    ])
    .padding()
}

#Preview("Four Images") {
    ImageGridView(imageUrls: [
        "https://picsum.photos/800/600",
        "https://picsum.photos/800/601",
        "https://picsum.photos/800/602",
        "https://picsum.photos/800/603"
    ])
    .padding()
}

