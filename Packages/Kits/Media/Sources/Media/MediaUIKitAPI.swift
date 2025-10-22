import Foundation
import UIKitBridge

#if os(iOS)
import UIKit

/// UIKit-specific API for the Media package
/// This provides UIImage-based convenience methods that bridge to the platform-agnostic Media API
public extension StorageService {
    
    /// Upload a user's avatar image to Supabase Storage (UIKit version)
    /// - Parameters:
    ///   - image: The UIImage to upload
    ///   - userId: The user's ID (used for folder organization)
    /// - Returns: The public URL of the uploaded image
    func uploadAvatar(image: UIImage, userId: String) async throws -> String {
        guard let imageData = MediaBridge.data(from: image) else {
            throw StorageError.imageProcessingFailed
        }
        return try await uploadAvatar(imageData: imageData, userId: userId)
    }
    
    /// Upload a single post image to Supabase Storage (UIKit version)
    /// - Parameters:
    ///   - image: The UIImage to upload
    ///   - userId: The user's ID (used for folder organization)
    /// - Returns: The public URL of the uploaded image
    func uploadPostImage(image: UIImage, userId: String) async throws -> String {
        guard let imageData = MediaBridge.data(from: image) else {
            throw StorageError.imageProcessingFailed
        }
        return try await uploadPostImage(imageData: imageData, userId: userId)
    }
    
    /// Upload multiple post images to Supabase Storage (UIKit version)
    /// - Parameters:
    ///   - images: Array of UIImages to upload (max 4)
    ///   - userId: The user's ID (used for folder organization)
    /// - Returns: Array of public URLs for uploaded images
    func uploadPostImages(images: [UIImage], userId: String) async throws -> [String] {
        let imageDataArray = MediaBridge.dataArray(from: images)
        return try await uploadPostImages(imageDataArray: imageDataArray, userId: userId)
    }
}

public extension MediaBundleService {
    
    /// Create a media bundle from images (UIKit version)
    /// - Parameters:
    ///   - images: Array of UIImages (1-4 images)
    ///   - userId: User ID for storage path
    /// - Returns: Media bundle ID
    func createImageBundle(images: [UIImage], userId: String) async throws -> String {
        let imageDataArray = MediaBridge.dataArray(from: images)
        return try await createImageBundle(imageDataArray: imageDataArray, userId: userId)
    }
}

public extension VideoProcessor {
    
    /// Generate thumbnail image from video (UIKit version)
    /// - Parameters:
    ///   - videoURL: Local URL of the video file
    ///   - time: Time in video to capture (default: 1 second)
    /// - Returns: UIImage thumbnail
    func generateThumbnailImage(from videoURL: URL, at time: TimeInterval = 1.0) async throws -> UIImage {
        let cgImage = try await generateThumbnail(from: videoURL, at: time)
        return MediaBridge.uiImage(from: cgImage)
    }
}

public extension MediaProcessor {
    
    /// Process and validate image data (UIKit version)
    /// - Parameters:
    ///   - image: UIImage to process
    ///   - maxSize: Maximum dimensions
    /// - Returns: Processed UIImage
    func processImage(_ image: UIImage, maxSize: CGSize = CGSize(width: 2048, height: 2048)) async throws -> UIImage {
        guard let imageData = MediaBridge.data(from: image) else {
            throw MediaError.invalidImageData
        }
        
        let processedData = try await processImageData(imageData, maxSize: maxSize)
        guard let processedImage = MediaBridge.uiImage(from: processedData) else {
            throw MediaError.imageProcessingFailed
        }
        
        return processedImage
    }
    
    /// Generate thumbnail from image (UIKit version)
    /// - Parameters:
    ///   - image: UIImage to generate thumbnail from
    ///   - maxSize: Maximum thumbnail size
    /// - Returns: Thumbnail UIImage
    func generateThumbnailImage(from image: UIImage, maxSize: CGSize = CGSize(width: 300, height: 300)) async throws -> UIImage {
        guard let imageData = MediaBridge.data(from: image) else {
            throw MediaError.invalidImageData
        }
        
        let cgImage = try await generateThumbnail(from: imageData, maxSize: maxSize)
        return MediaBridge.uiImage(from: cgImage)
    }
}
#endif
