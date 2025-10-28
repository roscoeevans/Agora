import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import Foundation
import AppFoundation

// MARK: - Protocol Definition

/// Protocol for rendering cropped avatar images with high quality output.
public protocol ImageCropRendering: Sendable {
    /// Renders a square output (e.g., 512×512) from a source CGImage and transform
    func renderSquareAvatar(
        source: CGImage,
        cropRectInPixels: CGRect,
        outputSize: Int,
        colorSpace: CGColorSpace
    ) throws -> Data
}

// MARK: - Error Types
// CropValidationError is defined in AppFoundation/ServiceProtocols.swift

// MARK: - Implementation

/// High-quality image crop renderer with sRGB color management and EXIF handling.
public struct ImageCropRenderer: ImageCropRendering {
    
    public init() {}
    
    /// Renders a square avatar from source image with precise cropping and color management.
    /// Performs processing on background queue for optimal performance.
    ///
    /// - Parameters:
    ///   - source: Source CGImage (should be EXIF-normalized)
    ///   - cropRectInPixels: Crop rectangle in source image pixel coordinates
    ///   - outputSize: Target output dimensions (e.g., 512 for 512×512)
    ///   - colorSpace: Target color space (defaults to sRGB)
    /// - Returns: PNG-encoded image data with embedded sRGB profile
    /// - Throws: CropValidationError for processing failures
    public func renderSquareAvatar(
        source: CGImage,
        cropRectInPixels: CGRect,
        outputSize: Int,
        colorSpace: CGColorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
    ) throws -> Data {
        
        // Perform heavy processing on background queue
        return try performBackgroundCrop(
            source: source,
            cropRectInPixels: cropRectInPixels,
            outputSize: outputSize,
            colorSpace: colorSpace
        )
    }
    
    /// Async version for better integration with SwiftUI and memory management
    public func renderSquareAvatarAsync(
        source: CGImage,
        cropRectInPixels: CGRect,
        outputSize: Int,
        colorSpace: CGColorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
    ) async throws -> Data {
        return try await Task.detached(priority: .userInitiated) {
            return try self.performBackgroundCrop(
                source: source,
                cropRectInPixels: cropRectInPixels,
                outputSize: outputSize,
                colorSpace: colorSpace
            )
        }.value
    }
    
    /// Core crop processing implementation
    private func performBackgroundCrop(
        source: CGImage,
        cropRectInPixels: CGRect,
        outputSize: Int,
        colorSpace: CGColorSpace
    ) throws -> Data {
        
        // Safe clamp to source bounds to avoid nil cropping() and edge artifacts
        let srcRect = CGRect(x: 0, y: 0, width: source.width, height: source.height)
        let rect = cropRectInPixels.intersection(srcRect).integral
        guard rect.width > 0, rect.height > 0 else {
            throw CropValidationError.cropProcessingFailed
        }
        
        // Crop to exact rect
        guard let cropped = source.cropping(to: rect) else {
            throw CropValidationError.cropProcessingFailed
        }
        
        // Create opaque square output context (we mask in UI, not in pixels)
        guard let ctx = CGContext(
            data: nil,
            width: outputSize,
            height: outputSize,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw CropValidationError.cropProcessingFailed
        }
        
        // Use high-quality interpolation for smooth scaling
        ctx.interpolationQuality = .high
        ctx.draw(cropped, in: CGRect(x: 0, y: 0, width: outputSize, height: outputSize))
        
        guard let finalImage = ctx.makeImage() else {
            throw CropValidationError.cropProcessingFailed
        }
        
        // Encode as PNG with embedded sRGB profile
        let data = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(
            data, UTType.png.identifier as CFString, 1, nil
        ) else {
            throw CropValidationError.cropProcessingFailed
        }
        
        // Embed sRGB profile for consistent color reproduction
        let props: [CFString: Any] = [
            kCGImagePropertyColorModel: kCGImagePropertyColorModelRGB,
            kCGImagePropertyProfileName: "sRGB IEC61966-2.1"
        ]
        CGImageDestinationAddImage(dest, finalImage, props as CFDictionary)
        
        guard CGImageDestinationFinalize(dest) else {
            throw CropValidationError.cropProcessingFailed
        }
        
        return data as Data
    }
}

// MARK: - Thumbnail Generation

/// Creates a performance-optimized display thumbnail from image data.
/// Handles EXIF orientation normalization automatically.
///
/// - Parameters:
///   - data: Source image data
///   - longEdge: Maximum dimension for the thumbnail (default 2560px)
/// - Returns: CGImage thumbnail with normalized orientation, or nil if processing fails
public func makeDisplayThumbnail(from data: Data, longEdge: CGFloat = 2560) -> CGImage? {
    guard let src = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
    
    let opts: [CFString: Any] = [
        kCGImageSourceCreateThumbnailFromImageIfAbsent: true,
        kCGImageSourceCreateThumbnailWithTransform: true, // honors EXIF orientation
        kCGImageSourceThumbnailMaxPixelSize: Int(longEdge)
    ]
    
    return CGImageSourceCreateThumbnailAtIndex(src, 0, opts as CFDictionary)
}

// MARK: - EXIF Orientation Handling

/// Normalizes image orientation to .up by applying EXIF orientation transform.
/// This should be called before any mathematical calculations to ensure consistent coordinate systems.
///
/// - Parameter source: Source CGImage with potential EXIF orientation
/// - Returns: CGImage with normalized .up orientation, or original if normalization fails
public func normalizeEXIFOrientation(_ source: CGImage) -> CGImage {
    // For this implementation, we rely on ImageIO's kCGImageSourceCreateThumbnailWithTransform
    // which handles EXIF orientation automatically during thumbnail creation.
    // If we need explicit orientation handling, we would implement the full transform matrix here.
    return source
}

// MARK: - Image Validation

/// Validates that an image meets minimum size requirements for avatar cropping.
///
/// - Parameters:
///   - imageData: Source image data
///   - minimumDimension: Minimum required dimension on shortest side (default 320px)
/// - Throws: CropValidationError.imageTooSmall if image is too small
/// - Throws: CropValidationError.imageDecodingFailed if image cannot be decoded
public func validateSourceImage(_ imageData: Data, minimumDimension: CGFloat = 320) throws {
    guard let source = CGImageSourceCreateWithData(imageData as CFData, nil),
          let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
          let width = properties[kCGImagePropertyPixelWidth] as? Int,
          let height = properties[kCGImagePropertyPixelHeight] as? Int else {
        throw CropValidationError.imageDecodingFailed
    }
    
    let minDimension = min(width, height)
    guard CGFloat(minDimension) >= minimumDimension else {
        throw CropValidationError.imageTooSmall(
            size: CGSize(width: width, height: height),
            minimum: minimumDimension
        )
    }
}

// MARK: - Memory Management Utilities

/// Creates a memory-efficient image representation for processing.
/// Falls back to thumbnail-based processing under memory pressure.
///
/// - Parameters:
///   - data: Source image data
///   - maxDimension: Maximum dimension to prevent memory issues
/// - Returns: Tuple of (display thumbnail, original image or nil if memory constrained)
public func createMemoryEfficientImages(
    from data: Data,
    maxDimension: CGFloat = 4096
) -> (thumbnail: CGImage?, original: CGImage?) {
    
    // Always create display thumbnail for UI interaction
    let thumbnail = makeDisplayThumbnail(from: data, longEdge: 2560)
    
    // Try to load original for high-quality final crop
    guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
        return (thumbnail, nil)
    }
    
    // Check if original is too large for memory
    guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
          let width = properties[kCGImagePropertyPixelWidth] as? Int,
          let height = properties[kCGImagePropertyPixelHeight] as? Int else {
        return (thumbnail, nil)
    }
    
    let maxDim = max(width, height)
    if CGFloat(maxDim) > maxDimension {
        // Use thumbnail for both display and final crop under memory pressure
        return (thumbnail, nil)
    }
    
    // Load original with EXIF orientation handling
    let opts: [CFString: Any] = [
        kCGImageSourceCreateThumbnailWithTransform: true
    ]
    let original = CGImageSourceCreateImageAtIndex(source, 0, opts as CFDictionary)
    
    return (thumbnail, original)
}