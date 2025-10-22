import Foundation

#if os(iOS)
import UIKit

/// Image validation result
public enum ImageValidationResult {
    case valid
    case tooSmall(minSize: CGSize)
    case tooLarge(maxSize: CGSize)
    case unsupportedFormat
    case fileTooLarge(maxSize: Int)
}

/// Processed profile image data
public struct ProcessedProfileImage {
    public let original: Data
    public let thumbnail120: Data
    public let thumbnail320: Data
    public let metadata: ImageMetadata
    
    public init(original: Data, thumbnail120: Data, thumbnail320: Data, metadata: ImageMetadata) {
        self.original = original
        self.thumbnail120 = thumbnail120
        self.thumbnail320 = thumbnail320
        self.metadata = metadata
    }
}

/// Image metadata
public struct ImageMetadata {
    public let originalSize: CGSize
    public let processedSize: CGSize
    public let fileSize: Int
    public let format: ImageFormat
    public let quality: Double
    
    public init(originalSize: CGSize, processedSize: CGSize, fileSize: Int, format: ImageFormat, quality: Double) {
        self.originalSize = originalSize
        self.processedSize = processedSize
        self.fileSize = fileSize
        self.format = format
        self.quality = quality
    }
}

/// Image format
public enum ImageFormat {
    case jpeg
    case png
}

/// Bridge between UIKit UIImage and platform-agnostic image processing
public struct ImageProcessingBridge {
    
    /// Convert UIImage to JPEG data with compression
    /// - Parameters:
    ///   - image: The UIImage to convert
    ///   - compressionQuality: JPEG compression quality (0.0 to 1.0)
    /// - Returns: JPEG data
    public static func jpegData(from image: UIImage, compressionQuality: CGFloat = 0.85) -> Data? {
        return image.jpegData(compressionQuality: compressionQuality)
    }
    
    /// Resize UIImage to fit within specified dimensions
    /// - Parameters:
    ///   - image: The UIImage to resize
    ///   - maxSize: Maximum dimensions
    /// - Returns: Resized UIImage
    public static func resizeImage(_ image: UIImage, maxSize: CGSize) -> UIImage? {
        return image.resized(to: maxSize)
    }
    
    /// Get image dimensions from UIImage
    /// - Parameter image: The UIImage
    /// - Returns: Image dimensions
    public static func imageDimensions(from image: UIImage) -> CGSize {
        return image.size
    }
    
    /// Convert UIImage to CGImage
    /// - Parameter image: The UIImage to convert
    /// - Returns: CGImage representation
    public static func cgImage(from image: UIImage) -> CGImage? {
        return image.cgImage
    }
    
    /// Create UIImage from CGImage
    /// - Parameter cgImage: The CGImage to convert
    /// - Returns: UIImage representation
    public static func uiImage(from cgImage: CGImage) -> UIImage {
        return UIImage(cgImage: cgImage)
    }
    
    /// Create UIImage from data
    /// - Parameter data: Image data
    /// - Returns: UIImage if data is valid image data
    public static func uiImage(from data: Data) -> UIImage? {
        return UIImage(data: data)
    }
    
    // MARK: - Profile Image Validation
    
    /// Validate image for profile picture use
    /// - Parameters:
    ///   - image: The UIImage to validate
    ///   - data: Optional image data for file size validation
    /// - Returns: Validation result
    public static func validateProfileImage(_ image: UIImage, data: Data? = nil) -> ImageValidationResult {
        let size = image.size
        let minSize = CGSize(width: 320, height: 320)
        let maxFileSize = 2 * 1024 * 1024 // 2MB
        
        // Check minimum size - this is the only hard requirement
        if size.width < minSize.width || size.height < minSize.height {
            return .tooSmall(minSize: minSize)
        }
        
        // Check file size if data provided - this is also a hard requirement
        if let data = data, data.count > maxFileSize {
            return .fileTooLarge(maxSize: maxFileSize)
        }
        
        // Large images are OK - we'll downscale them during processing
        return .valid
    }
    
    /// Get user-friendly error message for validation result
    /// - Parameter result: The validation result
    /// - Returns: Human-readable error message
    public static func errorMessage(for result: ImageValidationResult) -> String {
        switch result {
        case .valid:
            return ""
        case .tooSmall(let minSize):
            return "Image too small. Please select an image at least \(Int(minSize.width))×\(Int(minSize.height)) pixels."
        case .tooLarge(let maxSize):
            return "Image too large. Please select an image no larger than \(Int(maxSize.width))×\(Int(maxSize.height)) pixels."
        case .unsupportedFormat:
            return "Unsupported format. Please select a JPEG or PNG image."
        case .fileTooLarge(let maxSize):
            let maxSizeMB = maxSize / (1024 * 1024)
            return "File too large. Please select an image smaller than \(maxSizeMB)MB."
        }
    }
    
    // MARK: - Profile Image Processing
    
    /// Process image for profile picture use
    /// - Parameter image: The UIImage to process
    /// - Returns: Processed profile image data
    public static func processProfileImage(_ image: UIImage) async throws -> ProcessedProfileImage {
        let originalSize = image.size
        
        // Determine target size based on original image size
        let targetSize: CGSize
        if originalSize.width > 2048 || originalSize.height > 2048 {
            // For very large images, use 1080x1080
            targetSize = CGSize(width: 1080, height: 1080)
        } else if originalSize.width > 1080 || originalSize.height > 1080 {
            // For large images, use 1080x1080
            targetSize = CGSize(width: 1080, height: 1080)
        } else {
            // For smaller images, keep original size
            targetSize = originalSize
        }
        
        let processedImage = image.resized(to: targetSize) ?? image
        let processedSize = processedImage.size
        
        // Convert to JPEG with 85% quality
        guard let originalData = processedImage.jpegData(compressionQuality: 0.85) else {
            throw ImageProcessingError.compressionFailed
        }
        
        // Generate thumbnails
        let thumbnail120 = try await generateThumbnail(from: processedImage, size: CGSize(width: 120, height: 120))
        let thumbnail320 = try await generateThumbnail(from: processedImage, size: CGSize(width: 320, height: 320))
        
        // Create metadata
        let metadata = ImageMetadata(
            originalSize: originalSize,
            processedSize: processedSize,
            fileSize: originalData.count,
            format: .jpeg,
            quality: 0.85
        )
        
        return ProcessedProfileImage(
            original: originalData,
            thumbnail120: thumbnail120,
            thumbnail320: thumbnail320,
            metadata: metadata
        )
    }
    
    /// Generate thumbnail from image
    /// - Parameters:
    ///   - image: Source image
    ///   - size: Target thumbnail size
    /// - Returns: Thumbnail image data
    private static func generateThumbnail(from image: UIImage, size: CGSize) async throws -> Data {
        guard let thumbnail = image.resized(to: size) else {
            throw ImageProcessingError.thumbnailGenerationFailed
        }
        
        guard let data = thumbnail.jpegData(compressionQuality: 0.8) else {
            throw ImageProcessingError.compressionFailed
        }
        
        return data
    }
}

/// Image processing errors
public enum ImageProcessingError: Error, LocalizedError {
    case compressionFailed
    case thumbnailGenerationFailed
    case invalidImageData
    
    public var errorDescription: String? {
        switch self {
        case .compressionFailed:
            return "Failed to compress image"
        case .thumbnailGenerationFailed:
            return "Failed to generate thumbnail"
        case .invalidImageData:
            return "Invalid image data"
        }
    }
}
#endif
