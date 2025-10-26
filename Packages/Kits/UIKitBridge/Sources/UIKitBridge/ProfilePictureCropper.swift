//
//  ProfilePictureCropper.swift
//  UIKitBridge
//
//  Created by Agora Team on 2024.
//

import SwiftUI

#if canImport(UIKit)
import UIKit

/// SwiftUI view for cropping profile pictures with smart defaults and square output
@available(iOS 26.0, *)
public struct ProfilePictureCropper: View {
    let image: UIImage
    let onCrop: (UIImage) -> Void
    let onCancel: () -> Void
    
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var lastScale: CGFloat = 1.0
    
    private let cropSize: CGFloat = 320
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
            
            Button("Done") {
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
                                    let constrainedOffset = constrainOffset(newOffset, geometry: geometry)
                                    offset = constrainedOffset
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                },
                            
                            // Pinch gesture
                            MagnificationGesture()
                                .onChanged { value in
                                    let newScale = lastScale * value
                                    let constrainedScale = constrainScale(newScale, geometry: geometry)
                                    scale = constrainedScale
                                    
                                    // Adjust offset when scaling to keep crop area filled
                                    let scaleDelta = constrainedScale / lastScale
                                    offset = CGSize(
                                        width: offset.width * scaleDelta,
                                        height: offset.height * scaleDelta
                                    )
                                }
                                .onEnded { _ in
                                    lastScale = scale
                                    lastOffset = offset
                                }
                        )
                    )
                
                // Circular crop overlay (what the user sees)
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
                setupSmartInitialScale(geometry: geometry)
            }
            .onChange(of: geometry.size) { _, _ in
                setupSmartInitialScale(geometry: geometry)
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
    
    /// Calculate smart initial scale that ensures crop area is filled with no empty space
    private func setupSmartInitialScale(geometry: GeometryProxy) {
        print("🔧 [ProfilePictureCropper] Setting up initial scale")
        let imageSize = image.size
        let imageAspectRatio = imageSize.width / imageSize.height
        print("🔧 [ProfilePictureCropper] Image size: \(imageSize.width)x\(imageSize.height), aspect ratio: \(imageAspectRatio)")
        
        // Calculate scale needed to fill the circular crop area completely
        // For a circular crop, we need to ensure the image covers the entire circle
        let scaleToFill: CGFloat
        if imageAspectRatio > 1.0 {
            // Image is wider than tall - scale based on height to fill circle
            scaleToFill = cropSize / imageSize.height
            print("🔧 [ProfilePictureCropper] Wide image, scaling based on height: \(scaleToFill)")
        } else {
            // Image is taller than wide - scale based on width to fill circle
            scaleToFill = cropSize / imageSize.width
            print("🔧 [ProfilePictureCropper] Tall image, scaling based on width: \(scaleToFill)")
        }
        
        // Set the scale to exactly fill the crop area (no buffer to avoid empty space)
        let finalScale = min(maxScale, max(minScale, scaleToFill))
        print("🔧 [ProfilePictureCropper] Final scale: \(finalScale) (was: \(scale))")
        scale = finalScale
        lastScale = scale
        
        // Center the image initially
        offset = .zero
        lastOffset = .zero
        print("🔧 [ProfilePictureCropper] Setup complete - scale: \(scale), offset: \(offset)")
    }
    
    /// Constrain scale to keep crop area filled and within bounds
    private func constrainScale(_ newScale: CGFloat, geometry: GeometryProxy) -> CGFloat {
        let imageSize = image.size
        let imageAspectRatio = imageSize.width / imageSize.height
        
        // Calculate minimum scale to fill circular crop area
        let minScaleToFill: CGFloat
        if imageAspectRatio > 1.0 {
            // Image is wider than tall - scale based on height to fill circle
            minScaleToFill = cropSize / imageSize.height
        } else {
            // Image is taller than wide - scale based on width to fill circle
            minScaleToFill = cropSize / imageSize.width
        }
        
        // Ensure we don't go below the minimum scale needed to fill the crop area
        let effectiveMinScale = max(minScale, minScaleToFill)
        
        return min(maxScale, max(effectiveMinScale, newScale))
    }
    
    /// Constrain offset to keep crop area filled
    private func constrainOffset(_ newOffset: CGSize, geometry: GeometryProxy) -> CGSize {
        let imageSize = image.size
        let scaledImageSize = CGSize(
            width: imageSize.width * scale,
            height: imageSize.height * scale
        )
        
        // Calculate maximum offset to keep crop area filled
        let maxOffsetX = max(0, (scaledImageSize.width - cropSize) / 2)
        let maxOffsetY = max(0, (scaledImageSize.height - cropSize) / 2)
        
        return CGSize(
            width: min(maxOffsetX, max(-maxOffsetX, newOffset.width)),
            height: min(maxOffsetY, max(-maxOffsetY, newOffset.height))
        )
    }
    
    private func resetCrop() {
        withAnimation(.easeInOut(duration: 0.3)) {
            scale = 1.0
            offset = .zero
            lastScale = 1.0
            lastOffset = .zero
        }
    }
    
    /// Crop the image to a square format (not circular)
    private func cropImage() {
        print("✂️ [ProfilePictureCropper] Starting image crop")
        print("✂️ [ProfilePictureCropper] Current scale: \(scale), offset: \(offset)")
        
        // Calculate crop rect in image coordinates
        let imageSize = image.size
        let scaleFactor = imageSize.width / (image.size.width * scale)
        
        let cropRect = CGRect(
            x: (offset.width + (image.size.width * scale - cropSize) / 2) * scaleFactor,
            y: (offset.height + (image.size.height * scale - cropSize) / 2) * scaleFactor,
            width: cropSize * scaleFactor,
            height: cropSize * scaleFactor
        )
        
        print("✂️ [ProfilePictureCropper] Calculated crop rect: \(cropRect)")
        
        // Ensure crop rect is within image bounds
        let clampedRect = CGRect(
            x: max(0, min(cropRect.origin.x, imageSize.width - cropRect.width)),
            y: max(0, min(cropRect.origin.y, imageSize.height - cropRect.height)),
            width: min(cropRect.width, imageSize.width),
            height: min(cropRect.height, imageSize.height)
        )
        
        print("✂️ [ProfilePictureCropper] Clamped crop rect: \(clampedRect)")
        
        // Crop the image to square format
        guard let cgImage = image.cgImage?.cropping(to: clampedRect) else {
            print("❌ [ProfilePictureCropper] Failed to crop image - CGImage cropping failed")
            onCancel()
            return
        }
        
        let croppedImage = UIImage(cgImage: cgImage)
        print("✅ [ProfilePictureCropper] Image cropped successfully, size: \(croppedImage.size.width)x\(croppedImage.size.height)")
        onCrop(croppedImage)
    }
}

#endif
