import Foundation
import UIKit
import AppFoundation
import Supabase

/// Service for uploading files to Supabase Storage
public final class StorageService: Sendable {
    
    private let supabaseClient: AgoraSupabaseClient
    
    public init(supabaseClient: AgoraSupabaseClient = .shared) {
        self.supabaseClient = supabaseClient
    }
    
    // MARK: - Avatar Upload
    
    /// Upload a user's avatar image to Supabase Storage
    /// - Parameters:
    ///   - image: The UIImage to upload
    ///   - userId: The user's ID (used for folder organization)
    /// - Returns: The public URL of the uploaded image
    public func uploadAvatar(image: UIImage, userId: String) async throws -> String {
        // Resize image to reasonable size (max 512x512 for avatars)
        guard let resizedImage = image.resized(to: CGSize(width: 512, height: 512)),
              let imageData = resizedImage.jpegData(compressionQuality: 0.85) else {
            throw StorageError.imageProcessingFailed
        }
        
        // Generate unique filename
        let fileExtension = "jpg"
        let fileName = "\(userId)/avatar-\(UUID().uuidString).\(fileExtension)"
        
        // Upload to Supabase Storage
        _ = try await supabaseClient.storage
            .from("avatars")
            .upload(
                path: fileName,
                file: imageData,
                options: FileOptions(
                    contentType: "image/jpeg",
                    upsert: false
                )
            )
        
        // Get public URL using the file path we uploaded to
        let publicURL = try supabaseClient.storage
            .from("avatars")
            .getPublicURL(path: fileName)
        
        return publicURL.absoluteString
    }
    
    /// Delete a user's avatar from storage
    /// - Parameter avatarUrl: The full URL of the avatar to delete
    public func deleteAvatar(avatarUrl: String) async throws {
        // Extract path from URL (format: https://xxx.supabase.co/storage/v1/object/public/avatars/{path})
        guard let url = URL(string: avatarUrl),
              let path = extractStoragePath(from: url) else {
            throw StorageError.invalidURL
        }
        
        try await supabaseClient.storage
            .from("avatars")
            .remove(paths: [path])
    }
    
    // MARK: - Post Media Upload
    
    /// Upload a single post image to Supabase Storage
    /// - Parameters:
    ///   - image: The UIImage to upload
    ///   - userId: The user's ID (used for folder organization)
    /// - Returns: The public URL of the uploaded image
    public func uploadPostImage(image: UIImage, userId: String) async throws -> String {
        // Resize image to reasonable size (max 2048x2048 for posts)
        guard let resizedImage = image.resized(to: CGSize(width: 2048, height: 2048)),
              let imageData = resizedImage.jpegData(compressionQuality: 0.85) else {
            throw StorageError.imageProcessingFailed
        }
        
        // Generate unique filename
        let fileExtension = "jpg"
        let fileName = "\(userId)/post-\(UUID().uuidString).\(fileExtension)"
        
        // Upload to Supabase Storage
        _ = try await supabaseClient.storage
            .from("post-media")
            .upload(
                path: fileName,
                file: imageData,
                options: FileOptions(
                    contentType: "image/jpeg",
                    upsert: false
                )
            )
        
        // Get public URL using the file path we uploaded to
        let publicURL = try supabaseClient.storage
            .from("post-media")
            .getPublicURL(path: fileName)
        
        return publicURL.absoluteString
    }
    
    /// Upload multiple post images to Supabase Storage
    /// - Parameters:
    ///   - images: Array of UIImages to upload (max 4)
    ///   - userId: The user's ID (used for folder organization)
    /// - Returns: Array of public URLs for uploaded images
    public func uploadPostImages(images: [UIImage], userId: String) async throws -> [String] {
        guard images.count <= 4 else {
            throw StorageError.tooManyImages
        }
        
        var urls: [String] = []
        for image in images {
            let url = try await uploadPostImage(image: image, userId: userId)
            urls.append(url)
        }
        return urls
    }
    
    /// Upload a post video to Supabase Storage
    /// - Parameters:
    ///   - videoURL: Local URL of the video file
    ///   - userId: The user's ID (used for folder organization)
    /// - Returns: The public URL of the uploaded video
    public func uploadPostVideo(videoURL: URL, userId: String) async throws -> String {
        // Read video data
        guard let videoData = try? Data(contentsOf: videoURL) else {
            throw StorageError.videoReadFailed
        }
        
        // Check file size (max 50MB)
        let maxSize = 50 * 1024 * 1024 // 50MB
        guard videoData.count <= maxSize else {
            throw StorageError.videoTooLarge
        }
        
        // Determine content type from file extension
        let fileExtension = videoURL.pathExtension.lowercased()
        let contentType: String
        switch fileExtension {
        case "mp4", "m4v":
            contentType = "video/mp4"
        case "mov":
            contentType = "video/quicktime"
        default:
            contentType = "video/mp4"
        }
        
        // Generate unique filename
        let fileName = "\(userId)/video-\(UUID().uuidString).\(fileExtension)"
        
        // Upload to Supabase Storage
        _ = try await supabaseClient.storage
            .from("post-media")
            .upload(
                path: fileName,
                file: videoData,
                options: FileOptions(
                    contentType: contentType,
                    upsert: false
                )
            )
        
        // Get public URL
        let publicURL = try supabaseClient.storage
            .from("post-media")
            .getPublicURL(path: fileName)
        
        return publicURL.absoluteString
    }
    
    /// Delete post media from storage
    /// - Parameter urls: Array of media URLs to delete
    public func deletePostMedia(urls: [String]) async throws {
        var paths: [String] = []
        
        for urlString in urls {
            guard let url = URL(string: urlString),
                  let path = extractStoragePath(from: url, bucket: "post-media") else {
                continue
            }
            paths.append(path)
        }
        
        guard !paths.isEmpty else { return }
        
        try await supabaseClient.storage
            .from("post-media")
            .remove(paths: paths)
    }
    
    // MARK: - Private Helpers
    
    /// Extract the storage path from a full Supabase storage URL
    private func extractStoragePath(from url: URL, bucket: String = "avatars") -> String? {
        // URL format: https://xxx.supabase.co/storage/v1/object/public/{bucket}/{path}
        let components = url.pathComponents
        guard let bucketIndex = components.firstIndex(of: bucket),
              bucketIndex + 1 < components.count else {
            return nil
        }
        
        // Get everything after "{bucket}/"
        let pathComponents = Array(components[(bucketIndex + 1)...])
        return pathComponents.joined(separator: "/")
    }
}

// MARK: - Storage Errors

public enum StorageError: LocalizedError, Sendable {
    case imageProcessingFailed
    case uploadFailed
    case invalidURL
    case deleteFailed
    case tooManyImages
    case videoReadFailed
    case videoTooLarge
    
    public var errorDescription: String? {
        switch self {
        case .imageProcessingFailed:
            return "Failed to process image for upload"
        case .uploadFailed:
            return "Failed to upload image to storage"
        case .invalidURL:
            return "Invalid storage URL"
        case .deleteFailed:
            return "Failed to delete image from storage"
        case .tooManyImages:
            return "Cannot upload more than 4 images per post"
        case .videoReadFailed:
            return "Failed to read video file"
        case .videoTooLarge:
            return "Video file exceeds 50MB limit"
        }
    }
}

// MARK: - UIImage Helpers

extension UIImage {
    /// Resize image to fit within the specified size while maintaining aspect ratio
    func resized(to targetSize: CGSize) -> UIImage? {
        let size = self.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // Use the smaller ratio to ensure the image fits within bounds
        let scaleFactor = min(widthRatio, heightRatio)
        
        let scaledSize = CGSize(
            width: size.width * scaleFactor,
            height: size.height * scaleFactor
        )
        
        let renderer = UIGraphicsImageRenderer(size: scaledSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: scaledSize))
        }
    }
}

