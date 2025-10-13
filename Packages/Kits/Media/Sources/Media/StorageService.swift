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
    
    // MARK: - Private Helpers
    
    /// Extract the storage path from a full Supabase storage URL
    private func extractStoragePath(from url: URL) -> String? {
        // URL format: https://xxx.supabase.co/storage/v1/object/public/avatars/{path}
        let components = url.pathComponents
        guard let avatarsIndex = components.firstIndex(of: "avatars"),
              avatarsIndex + 1 < components.count else {
            return nil
        }
        
        // Get everything after "avatars/"
        let pathComponents = Array(components[(avatarsIndex + 1)...])
        return pathComponents.joined(separator: "/")
    }
}

// MARK: - Storage Errors

public enum StorageError: LocalizedError, Sendable {
    case imageProcessingFailed
    case uploadFailed
    case invalidURL
    case deleteFailed
    
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

