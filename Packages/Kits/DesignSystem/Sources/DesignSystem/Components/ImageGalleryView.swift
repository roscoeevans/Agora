//
//  ImageGalleryView.swift
//  DesignSystem
//
//  Fullscreen image gallery with swipe navigation
//

import SwiftUI

/// Fullscreen image gallery with swipe navigation
public struct ImageGalleryView: View {
    let imageUrls: [String]
    let initialIndex: Int
    
    @State private var currentIndex: Int
    @Environment(\.dismiss) private var dismiss
    
    public init(imageUrls: [String], initialIndex: Int = 0) {
        self.imageUrls = imageUrls
        self.initialIndex = initialIndex
        self._currentIndex = State(initialValue: initialIndex)
    }
    
    public var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea()
            
            // Image carousel
            TabView(selection: $currentIndex) {
                ForEach(Array(imageUrls.enumerated()), id: \.offset) { index, url in
                    AsyncImage(url: URL(string: url)) { phase in
                        switch phase {
                        case .empty:
                            loadingView
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .ignoresSafeArea()
                        case .failure:
                            errorView
                        @unknown default:
                            loadingView
                        }
                    }
                    .tag(index)
                }
            }
            #if os(iOS)
            .tabViewStyle(.page(indexDisplayMode: .never))
            #endif
            .ignoresSafeArea()
            
            // Top controls
            VStack {
                HStack {
                    // Close button
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    // Image counter
                    Text("\(currentIndex + 1) of \(imageUrls.count)")
                        .font(TypographyScale.callout)
                        .foregroundColor(.white)
                        .padding(.horizontal, SpacingTokens.sm)
                        .padding(.vertical, SpacingTokens.xs)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Capsule())
                }
                .padding(.horizontal, SpacingTokens.md)
                .padding(.top, SpacingTokens.md)
                
                Spacer()
            }
        }
        #if os(iOS)
        .navigationBarHidden(true)
        #endif
        .onAppear {
            currentIndex = initialIndex
        }
    }
    
    private var loadingView: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .ignoresSafeArea()
            .overlay {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(.white)
            }
    }
    
    private var errorView: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .ignoresSafeArea()
            .overlay {
                VStack(spacing: SpacingTokens.sm) {
                    Image(systemName: "photo")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                    
                    Text("Unable to load image")
                        .font(TypographyScale.callout)
                        .foregroundColor(.white)
                }
            }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Image Gallery") {
    NavigationStack {
        ImageGalleryView(
            imageUrls: [
                "https://picsum.photos/800/600",
                "https://picsum.photos/800/601",
                "https://picsum.photos/800/602",
                "https://picsum.photos/800/603"
            ],
            initialIndex: 0
        )
    }
}
#endif
