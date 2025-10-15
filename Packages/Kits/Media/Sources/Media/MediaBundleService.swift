import Foundation
import UIKit
import AppFoundation
import Supabase

/// Service for creating and managing media bundles
public final class MediaBundleService: Sendable {
    private let supabaseClient: AgoraSupabaseClient
    private let storageService: StorageService
    private let videoProcessor: VideoProcessor
    
    public init(
        supabaseClient: AgoraSupabaseClient = .shared,
        storageService: StorageService = StorageService(),
        videoProcessor: VideoProcessor = .shared
    ) {
        self.supabaseClient = supabaseClient
        self.storageService = storageService
        self.videoProcessor = videoProcessor
    }
    
    // MARK: - Image Bundle Creation
    
    /// Create a media bundle from images
    /// - Parameters:
    ///   - images: Array of UIImages (1-4 images)
    ///   - userId: User ID for storage path
    /// - Returns: Media bundle ID
    public func createImageBundle(images: [UIImage], userId: String) async throws -> String {
        guard !images.isEmpty && images.count <= 4 else {
            throw MediaBundleError.invalidImageCount
        }
        
        // Upload all images
        let urls = try await storageService.uploadPostImages(images: images, userId: userId)
        
        // Get dimensions from first image
        let width = Int(images[0].size.width)
        let height = Int(images[0].size.height)
        
        // Create bundle record
        // Note: Storing URLs as JSON in cf_image_id field since schema expects Cloudflare
        let urlsJSON = try JSONEncoder().encode(urls)
        let urlsString = String(data: urlsJSON, encoding: .utf8) ?? "[]"
        
        let bundle = ImageBundleInput(
            type: "image",
            cf_image_id: urlsString,
            width: width,
            height: height
        )
        
        let result: MediaBundleResponse = try await supabaseClient.database
            .from("media_bundles")
            .insert(bundle)
            .select()
            .single()
            .execute()
            .value
        
        return result.id
    }
    
    // MARK: - Video Bundle Creation
    
    /// Create a media bundle from a video
    /// - Parameters:
    ///   - videoURL: Local URL of video file
    ///   - userId: User ID for storage path
    /// - Returns: Media bundle ID
    public func createVideoBundle(videoURL: URL, userId: String) async throws -> String {
        // Validate and extract metadata
        let metadata = try await videoProcessor.validateAndExtractMetadata(videoURL)
        
        // Compress if needed
        let finalVideoURL = try await videoProcessor.compressIfNeeded(videoURL)
        
        // Upload video
        let videoStorageURL = try await storageService.uploadPostVideo(videoURL: finalVideoURL, userId: userId)
        
        // Generate and upload thumbnail
        let thumbnail = try await videoProcessor.generateThumbnail(from: finalVideoURL)
        let thumbnailURL = try await storageService.uploadPostImage(image: thumbnail, userId: userId)
        
        // Create bundle record
        let urls = [videoStorageURL, thumbnailURL]
        let urlsJSON = try JSONEncoder().encode(urls)
        let urlsString = String(data: urlsJSON, encoding: .utf8) ?? "[]"
        
        let bundle = VideoBundleInput(
            type: "video",
            cf_stream_id: urlsString,
            width: metadata.width,
            height: metadata.height,
            duration_sec: Int(metadata.duration)
        )
        
        let result: MediaBundleResponse = try await supabaseClient.database
            .from("media_bundles")
            .insert(bundle)
            .select()
            .single()
            .execute()
            .value
        
        return result.id
    }
    
    // MARK: - Bundle Retrieval
    
    /// Get media URLs from a bundle ID
    /// - Parameter bundleId: Media bundle ID
    /// - Returns: Array of media URLs
    public func getMediaURLs(bundleId: String) async throws -> [String] {
        let result: MediaBundleResponse = try await supabaseClient.database
            .from("media_bundles")
            .select()
            .eq("id", value: bundleId)
            .single()
            .execute()
            .value
        
        // Try to extract URLs from cf_image_id or cf_stream_id
        if let urlsString = result.cf_image_id ?? result.cf_stream_id,
           let urlsData = urlsString.data(using: .utf8),
           let urls = try? JSONDecoder().decode([String].self, from: urlsData) {
            return urls
        }
        
        return []
    }
}

// MARK: - Internal Models

private struct ImageBundleInput: Encodable {
    let type: String
    let cf_image_id: String
    let width: Int
    let height: Int
}

private struct VideoBundleInput: Encodable {
    let type: String
    let cf_stream_id: String
    let width: Int
    let height: Int
    let duration_sec: Int
}

private struct MediaBundleResponse: Decodable {
    let id: String
    let type: String?
    let cf_image_id: String?
    let cf_stream_id: String?
}

// MARK: - Media Bundle Errors

public enum MediaBundleError: LocalizedError, Sendable {
    case invalidImageCount
    case creationFailed
    case notFound
    
    public var errorDescription: String? {
        switch self {
        case .invalidImageCount:
            return "Must provide 1-4 images for image bundle"
        case .creationFailed:
            return "Failed to create media bundle"
        case .notFound:
            return "Media bundle not found"
        }
    }
}

