import Foundation
import ImageIO
import CoreGraphics
import UniformTypeIdentifiers

/// Media processing utilities for posts
public final class MediaProcessor: Sendable {
    public static let shared = MediaProcessor()
    
    private init() {}
    
    // MARK: - Image Processing
    
    /// Process and validate image data
    /// - Parameters:
    ///   - data: Image data
    ///   - maxSize: Maximum dimensions
    /// - Returns: Processed image data
    public func processImageData(_ data: Data, maxSize: CGSize = CGSize(width: 2048, height: 2048)) async throws -> Data {
        // Validate image data
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil) else {
            throw MediaError.invalidImageData
        }
        
        // Get image properties
        guard let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any] else {
            throw MediaError.invalidImageData
        }
        
        // Check dimensions
        let width = properties[kCGImagePropertyPixelWidth] as? Int ?? 0
        let height = properties[kCGImagePropertyPixelHeight] as? Int ?? 0
        
        guard width > 0 && height > 0 else {
            throw MediaError.invalidImageData
        }
        
        // Check if resizing is needed
        let currentSize = CGSize(width: width, height: height)
        if currentSize.width <= maxSize.width && currentSize.height <= maxSize.height {
            return data // No resizing needed
        }
        
        // Resize image
        return try await resizeImageData(data, maxSize: maxSize)
    }
    
    /// Resize image data to fit within specified dimensions
    /// - Parameters:
    ///   - data: Original image data
    ///   - maxSize: Maximum dimensions
    /// - Returns: Resized image data
    private func resizeImageData(_ data: Data, maxSize: CGSize) async throws -> Data {
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            throw MediaError.imageProcessingFailed
        }
        
        // Calculate new size maintaining aspect ratio
        let originalSize = CGSize(width: cgImage.width, height: cgImage.height)
        let aspectRatio = originalSize.width / originalSize.height
        
        let newSize: CGSize
        if aspectRatio > 1 {
            // Landscape
            newSize = CGSize(
                width: min(maxSize.width, originalSize.width),
                height: min(maxSize.width / aspectRatio, originalSize.height)
            )
        } else {
            // Portrait or square
            newSize = CGSize(
                width: min(maxSize.height * aspectRatio, originalSize.width),
                height: min(maxSize.height, originalSize.height)
            )
        }
        
        // Create resized image
        let resizedImage = try await resizeCGImage(cgImage, to: newSize)
        
        // Convert back to data
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.85) else {
            throw MediaError.imageProcessingFailed
        }
        
        return imageData
    }
    
    /// Resize CGImage to specified size
    /// - Parameters:
    ///   - image: Original CGImage
    ///   - size: Target size
    /// - Returns: Resized CGImage
    private func resizeCGImage(_ image: CGImage, to size: CGSize) async throws -> CGImage {
        let width = Int(size.width)
        let height = Int(size.height)
        
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw MediaError.imageProcessingFailed
        }
        
        context.interpolationQuality = .high
        context.draw(image, in: CGRect(origin: .zero, size: size))
        
        guard let resizedImage = context.makeImage() else {
            throw MediaError.imageProcessingFailed
        }
        
        return resizedImage
    }
    
    /// Generate thumbnail from image data
    /// - Parameters:
    ///   - data: Image data
    ///   - maxSize: Maximum thumbnail size
    /// - Returns: Thumbnail CGImage
    public func generateThumbnail(from data: Data, maxSize: CGSize = CGSize(width: 300, height: 300)) async throws -> CGImage {
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            throw MediaError.invalidImageData
        }
        
        return try await resizeCGImage(cgImage, to: maxSize)
    }
    
    /// Get image dimensions from data
    /// - Parameter data: Image data
    /// - Returns: Image dimensions
    public func getImageDimensions(from data: Data) throws -> CGSize {
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any] else {
            throw MediaError.invalidImageData
        }
        
        let width = properties[kCGImagePropertyPixelWidth] as? Int ?? 0
        let height = properties[kCGImagePropertyPixelHeight] as? Int ?? 0
        
        return CGSize(width: width, height: height)
    }
}

// MARK: - Media Errors

public enum MediaError: LocalizedError, Sendable {
    case invalidImageData
    case imageProcessingFailed
    case unsupportedFormat
    
    public var errorDescription: String? {
        switch self {
        case .invalidImageData:
            return "Invalid or corrupted image data"
        case .imageProcessingFailed:
            return "Failed to process image"
        case .unsupportedFormat:
            return "Unsupported image format"
        }
    }
}

// MARK: - CGImage Extensions

extension CGImage {
    /// Convert CGImage to JPEG data
    /// - Parameter compressionQuality: JPEG compression quality (0.0 to 1.0)
    /// - Returns: JPEG data
    public func jpegData(compressionQuality: CGFloat) -> Data? {
        guard let mutableData = CFDataCreateMutable(nil, 0),
              let destination = CGImageDestinationCreateWithData(mutableData, UTType.jpeg.identifier as CFString, 1, nil) else {
            return nil
        }
        
        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: compressionQuality
        ]
        
        CGImageDestinationAddImage(destination, self, options as CFDictionary)
        CGImageDestinationFinalize(destination)
        
        return mutableData as Data
    }
}