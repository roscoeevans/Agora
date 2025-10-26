//
//  SimpleImageCropper.swift
//  UIKitBridge
//
//  Created by Agora Team on 2024.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

/// Simple SwiftUI-native image cropper for circular avatars
@available(iOS 26.0, *)
public struct SimpleImageCropper: View {
    let image: UIImage
    let onCrop: (UIImage?) -> Void
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
        onCrop: @escaping (UIImage?) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.image = image
        self.onCrop = onCrop
        self.onCancel = onCancel
    }
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black.ignoresSafeArea()
                
                // Image with gestures
                imageView(geometry: geometry)
                
                // Crop overlay
                cropOverlay
                
                // Controls
                controlsView
            }
            .onAppear {
                setupInitialScale(geometry: geometry)
            }
        }
    }
    
    private func imageView(geometry: GeometryProxy) -> some View {
        Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .scaleEffect(scale)
            .offset(offset)
            .gesture(
                SimultaneousGesture(
                    MagnificationGesture()
                        .onChanged { value in
                            let newScale = lastScale * value
                            scale = constrainScale(newScale, geometry: geometry)
                        }
                        .onEnded { _ in
                            lastScale = scale
                        },
                    
                    DragGesture()
                        .onChanged { value in
                            let newOffset = CGSize(
                                width: lastOffset.width + value.translation.width,
                                height: lastOffset.height + value.translation.height
                            )
                            offset = constrainOffset(newOffset, geometry: geometry)
                        }
                        .onEnded { _ in
                            lastOffset = offset
                        }
                )
            )
    }
    
    private var cropOverlay: some View {
        ZStack {
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
    }
    
    private var controlsView: some View {
        VStack {
            Spacer()
            
            HStack(spacing: 20) {
                // Cancel button
                Button("Cancel") {
                    onCancel()
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                
                Spacer()
                
                // Done button
                Button("Done") {
                    cropImage()
                }
                .foregroundColor(.white)
                .fontWeight(.semibold)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }
    
    private func setupInitialScale(geometry: GeometryProxy) {
        let imageSize = image.size
        let imageAspectRatio = imageSize.width / imageSize.height
        
        // Calculate scale needed to fill the circular crop area
        let scaleToFill: CGFloat
        if imageAspectRatio > 1.0 {
            // Image is wider than tall - scale based on height to fill circle
            scaleToFill = cropSize / imageSize.height
        } else {
            // Image is taller than wide - scale based on width to fill circle
            scaleToFill = cropSize / imageSize.width
        }
        
        // Set the scale to fill the crop area
        scale = min(maxScale, max(minScale, scaleToFill))
        lastScale = scale
        
        // Center the image initially
        offset = .zero
        lastOffset = .zero
    }
    
    private func constrainScale(_ newScale: CGFloat, geometry: GeometryProxy) -> CGFloat {
        let imageSize = image.size
        let imageAspectRatio = imageSize.width / imageSize.height
        
        // Calculate minimum scale to fill circular crop area
        let minScaleToFill: CGFloat
        if imageAspectRatio > 1.0 {
            minScaleToFill = cropSize / imageSize.height
        } else {
            minScaleToFill = cropSize / imageSize.width
        }
        
        let effectiveMinScale = max(minScale, minScaleToFill)
        return min(maxScale, max(effectiveMinScale, newScale))
    }
    
    private func constrainOffset(_ newOffset: CGSize, geometry: GeometryProxy) -> CGSize {
        let imageSize = image.size
        let scaledSize = CGSize(
            width: imageSize.width * scale,
            height: imageSize.height * scale
        )
        
        let maxOffsetX = max(0, (scaledSize.width - cropSize) / 2)
        let maxOffsetY = max(0, (scaledSize.height - cropSize) / 2)
        
        return CGSize(
            width: min(maxOffsetX, max(-maxOffsetX, newOffset.width)),
            height: min(maxOffsetY, max(-maxOffsetY, newOffset.height))
        )
    }
    
    private func cropImage() {
        print("✂️ [SimpleImageCropper] Starting image crop")
        
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
        
        // Crop the image to square format
        guard let cgImage = image.cgImage?.cropping(to: clampedRect) else {
            print("❌ [SimpleImageCropper] Failed to crop image")
            onCancel()
            return
        }
        
        let croppedImage = UIImage(cgImage: cgImage)
        print("✅ [SimpleImageCropper] Image cropped successfully, size: \(croppedImage.size.width)x\(croppedImage.size.height)")
        onCrop(croppedImage)
    }
}
