import Foundation
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
    ///   - imageData: The image data to upload
    ///   - userId: The user's ID (used for folder organization)
    /// - Returns: The public URL of the uploaded image
    public func uploadAvatar(imageData: Data, userId: String) async throws -> String {
        // Generate unique filename
        let fileExtension = "jpg"
        let fileName = "\(userId)/avatar-\(UUID().uuidString).\(fileExtension)"
        
        // Get raw Supabase client for advanced storage operations
        guard let rawClient = supabaseClient.client.rawClient as? SupabaseClient else {
            throw StorageError.uploadFailed
        }
        
        // Upload to Supabase Storage
        _ = try await rawClient.storage
            .from("avatars")
            .upload(
                fileName,
                data: imageData,
                options: FileOptions(
                    contentType: "image/jpeg",
                    upsert: false
                )
            )
        
        // Get public URL using the file path we uploaded to
        let publicURL = try rawClient.storage
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
        
        // Get raw Supabase client for advanced storage operations
        guard let rawClient = supabaseClient.client.rawClient as? SupabaseClient else {
            throw StorageError.uploadFailed
        }
        
        // Delete from Supabase Storage
        try await rawClient.storage
            .from("avatars")
            .remove(paths: [path])
    }
    
    // MARK: - Post Media Upload
    
    /// Upload a single post image to Supabase Storage
    /// - Parameters:
    ///   - imageData: The image data to upload
    ///   - userId: The user's ID (used for folder organization)
    /// - Returns: The public URL of the uploaded image
    public func uploadPostImage(imageData: Data, userId: String) async throws -> String {
        // Generate unique filename
        let fileExtension = "jpg"
        let fileName = "\(userId)/post-\(UUID().uuidString).\(fileExtension)"
        
        // Get raw Supabase client for advanced storage operations
        guard let rawClient = supabaseClient.client.rawClient as? SupabaseClient else {
            throw StorageError.uploadFailed
        }
        
        // Upload to Supabase Storage
        _ = try await rawClient.storage
            .from("post-media")
            .upload(
                fileName,
                data: imageData,
                options: FileOptions(
                    contentType: "image/jpeg",
                    upsert: false
                )
            )
        
        // Get public URL using the file path we uploaded to
        let publicURL = try rawClient.storage
            .from("post-media")
            .getPublicURL(path: fileName)
        
        return publicURL.absoluteString
    }
    
    /// Upload multiple post images to Supabase Storage
    /// - Parameters:
    ///   - imageDataArray: Array of image data to upload (max 4)
    ///   - userId: The user's ID (used for folder organization)
    /// - Returns: Array of public URLs for uploaded images
    public func uploadPostImages(imageDataArray: [Data], userId: String) async throws -> [String] {
        guard imageDataArray.count <= 4 else {
            throw StorageError.tooManyImages
        }
        
        var urls: [String] = []
        
        for imageData in imageDataArray {
            let url = try await uploadPostImage(imageData: imageData, userId: userId)
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
        
        // Generate unique filename
        let fileExtension = "mp4"
        let fileName = "\(userId)/video-\(UUID().uuidString).\(fileExtension)"
        
        // Get raw Supabase client for advanced storage operations
        guard let rawClient = supabaseClient.client.rawClient as? SupabaseClient else {
            throw StorageError.uploadFailed
        }
        
        // Upload to Supabase Storage
        _ = try await rawClient.storage
            .from("post-media")
            .upload(
                fileName,
                data: videoData,
                options: FileOptions(
                    contentType: "video/mp4",
                    upsert: false
                )
            )
        
        // Get public URL using the file path we uploaded to
        let publicURL = try rawClient.storage
            .from("post-media")
            .getPublicURL(path: fileName)
        
        return publicURL.absoluteString
    }
    
    // MARK: - Helper Methods
    
    /// Extract storage path from a public URL
    /// - Parameter url: The public URL
    /// - Returns: The storage path if valid
    private func extractStoragePath(from url: URL) -> String? {
        let pathComponents = url.pathComponents
        
        // Look for the pattern: /storage/v1/object/public/{bucket}/{path}
        guard let storageIndex = pathComponents.firstIndex(of: "storage"),
              storageIndex + 4 < pathComponents.count,
              pathComponents[storageIndex + 1] == "v1",
              pathComponents[storageIndex + 2] == "object",
              pathComponents[storageIndex + 3] == "public" else {
            return nil
        }
        
        // Extract everything after the bucket name
        let bucketIndex = storageIndex + 4
        let remainingComponents = Array(pathComponents.dropFirst(bucketIndex + 1))
        return remainingComponents.joined(separator: "/")
    }
}

// MARK: - Storage Errors

public enum StorageError: LocalizedError, Sendable {
    case imageProcessingFailed
    case tooManyImages
    case videoReadFailed
    case videoTooLarge
    case invalidURL
    case uploadFailed
    
    public var errorDescription: String? {
        switch self {
        case .imageProcessingFailed:
            return "Failed to process image data"
        case .tooManyImages:
            return "Too many images provided (maximum 4 allowed)"
        case .videoReadFailed:
            return "Failed to read video file"
        case .videoTooLarge:
            return "Video file is too large (maximum 50MB allowed)"
        case .invalidURL:
            return "Invalid storage URL provided"
        case .uploadFailed:
            return "Failed to upload file to storage"
        }
    }
}