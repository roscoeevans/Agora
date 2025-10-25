//
//  ImageCropperView.swift
//  UIKitBridge
//
//  Created by Agora Team on 2024.
//

import SwiftUI

#if canImport(UIKit)
import UIKit

/// SwiftUI view for cropping images with circular preview
@available(iOS 26.0, *)
public struct ImageCropperView: View {
    let image: UIImage
    let onCrop: (UIImage) -> Void
    let onCancel: () -> Void
    
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var lastScale: CGFloat = 1.0
    
    private let cropSize: CGFloat = 280
    private let minScale: CGFloat = 0.5
    private let maxScale: CGFloat = 3.0
    
    public init(
        image: UIImage,
        onCrop: @escaping (UIImage) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.image = image
        self.onCrop = onCrop
        self.onCancel = onCancel
    }
    
    public var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.black
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    headerView
                    
                    // Cropping area
                    croppingArea
                    
                    // Controls
                    controlsView
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private var headerView: some View {
        HStack {
            Button("Cancel") {
                onCancel()
            }
            .foregroundColor(.white)
            .font(.system(size: 17, weight: .medium))
            
            Spacer()
            
            Text("Adjust Photo")
                .foregroundColor(.white)
                .font(.system(size: 17, weight: .semibold))
            
            Spacer()
            
            Button("Crop") {
                cropImage()
            }
            .foregroundColor(.blue)
            .font(.system(size: 17, weight: .semibold))
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    private var croppingArea: some View {
        GeometryReader { geometry in
            ZStack {
                // Image with zoom and pan
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        SimultaneousGesture(
                            // Pan gesture
                            DragGesture()
                                .onChanged { value in
                                    let newOffset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                    
                                    // Constrain offset to keep crop area filled
                                    let maxOffsetX = max(0, (image.size.width * scale - cropSize) / 2)
                                    let maxOffsetY = max(0, (image.size.height * scale - cropSize) / 2)
                                    
                                    offset = CGSize(
                                        width: min(maxOffsetX, max(-maxOffsetX, newOffset.width)),
                                        height: min(maxOffsetY, max(-maxOffsetY, newOffset.height))
                                    )
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                },
                            
                            // Pinch gesture
                            MagnificationGesture()
                                .onChanged { value in
                                    let newScale = lastScale * value
                                    scale = min(maxScale, max(minScale, newScale))
                                }
                                .onEnded { _ in
                                    lastScale = scale
                                }
                        )
                    )
                
                // Circular crop overlay
                Circle()
                    .stroke(Color.white, lineWidth: 2)
                    .frame(width: cropSize, height: cropSize)
                    .allowsHitTesting(false)
                
                // Dark overlay outside crop area
                Rectangle()
                    .fill(Color.black.opacity(0.5))
                    .mask(
                        Circle()
                            .frame(width: cropSize, height: cropSize)
                            .blendMode(.destinationOut)
                    )
                    .allowsHitTesting(false)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                setupInitialScale(geometry: geometry)
            }
        }
    }
    
    private var controlsView: some View {
        VStack(spacing: 20) {
            // Instructions
            Text("Drag to reposition • Pinch to zoom")
                .foregroundColor(.white.opacity(0.7))
                .font(.system(size: 14))
            
            // Reset button
            Button("Reset") {
                resetCrop()
            }
            .foregroundColor(.white)
            .font(.system(size: 16, weight: .medium))
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.2))
            .cornerRadius(20)
        }
        .padding(.bottom, 40)
    }
    
    private func setupInitialScale(geometry: GeometryProxy) {
        let imageAspectRatio = image.size.width / image.size.height
        let cropAspectRatio: CGFloat = 1.0 // Square crop
        
        let scaleToFit: CGFloat
        if imageAspectRatio > cropAspectRatio {
            // Image is wider than crop area
            scaleToFit = cropSize / image.size.height
        } else {
            // Image is taller than crop area
            scaleToFit = cropSize / image.size.width
        }
        
        // Set initial scale to fill crop area with some padding
        scale = max(scaleToFit * 1.2, minScale)
        lastScale = scale
    }
    
    private func resetCrop() {
        withAnimation(.easeInOut(duration: 0.3)) {
            scale = 1.0
            offset = .zero
            lastScale = 1.0
            lastOffset = .zero
        }
    }
    
    private func cropImage() {
        // Calculate crop rect in image coordinates
        let imageSize = image.size
        let scaleFactor = imageSize.width / (image.size.width * scale)
        
        let cropRect = CGRect(
            x: (offset.width + (image.size.width * scale - cropSize) / 2) * scaleFactor,
            y: (offset.height + (image.size.height * scale - cropSize) / 2) * scaleFactor,
            width: cropSize * scaleFactor,
            height: cropSize * scaleFactor
        )
        
        // Ensure crop rect is within image bounds
        let clampedRect = CGRect(
            x: max(0, min(cropRect.origin.x, imageSize.width - cropRect.width)),
            y: max(0, min(cropRect.origin.y, imageSize.height - cropRect.height)),
            width: min(cropRect.width, imageSize.width),
            height: min(cropRect.height, imageSize.height)
        )
        
        // Crop the image
        guard let cgImage = image.cgImage?.cropping(to: clampedRect) else {
            onCancel()
            return
        }
        
        let croppedImage = UIImage(cgImage: cgImage)
        onCrop(croppedImage)
    }
}

#endif


