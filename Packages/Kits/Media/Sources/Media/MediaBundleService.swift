import Foundation
import AppFoundation
import Supabase

/// Service for creating and managing media bundles
public final class MediaBundleService: MediaBundleServiceProtocol {
    private let supabaseClient: AgoraSupabaseClient
    private let storageService: StorageService
    private let videoProcessor: VideoProcessor
    
    // Thread-safe cache using actor for Sendable conformance
    private let cacheActor = MediaBundleCacheActor()
    
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
    
    /// Create a media bundle from image data
    /// - Parameters:
    ///   - imageDataArray: Array of image data (1-4 images)
    ///   - userId: User ID for storage path
    /// - Returns: Media bundle ID
    public func createImageBundle(imageDataArray: [Data], userId: String) async throws -> String {
        guard !imageDataArray.isEmpty && imageDataArray.count <= 4 else {
            throw MediaBundleError.invalidImageCount
        }
        
        // Upload all images
        let urls = try await storageService.uploadPostImages(imageDataArray: imageDataArray, userId: userId)
        
        // Get dimensions from first image (we'll need to decode it)
        // For now, use default dimensions - this should be handled by the bridge
        let width = 1920 // Default width
        let height = 1080 // Default height
        
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
        
        // Get raw Supabase client for advanced database operations
        guard let rawClient = supabaseClient.client.rawClient as? SupabaseClient else {
            throw MediaBundleError.creationFailed
        }
        
        let result: MediaBundleResponse = try await rawClient
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
        let finalVideoURL = try await videoProcessor.compressIfNeeded(videoURL: videoURL)
        
        // Upload video
        let videoStorageURL = try await storageService.uploadPostVideo(videoURL: finalVideoURL, userId: userId)
        
        // Generate and upload thumbnail
        _ = try await videoProcessor.generateThumbnail(from: finalVideoURL)
        // TODO: Convert CGImage to Data for upload - this should be handled by the bridge
        // For now, we'll skip thumbnail upload
        let thumbnailURL = "" // Placeholder
        
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
        
        // Get raw Supabase client for advanced database operations
        guard let rawClient = supabaseClient.client.rawClient as? SupabaseClient else {
            throw MediaBundleError.creationFailed
        }
        
        let result: MediaBundleResponse = try await rawClient
            .from("media_bundles")
            .insert(bundle)
            .select()
            .single()
            .execute()
            .value
        
        return result.id
    }
    
    // MARK: - Bundle Retrieval
    
    /// Get media URLs from a bundle ID with caching
    /// - Parameter bundleId: Media bundle ID
    /// - Returns: MediaBundleInfo with type, URLs, and metadata
    public func getMediaBundleInfo(bundleId: String) async throws -> MediaBundleInfo {
        // Check cache first
        if let cachedItem = await cacheActor.get(key: bundleId) {
            return cachedItem
        }
        
        // Get raw Supabase client for advanced database operations
        guard let rawClient = supabaseClient.client.rawClient as? SupabaseClient else {
            throw MediaBundleError.creationFailed
        }
        
        let result: MediaBundleResponse = try await rawClient
            .from("media_bundles")
            .select()
            .eq("id", value: bundleId)
            .single()
            .execute()
            .value
        
        // Parse URLs from cf_image_id or cf_stream_id
        var urls: [String] = []
        var type: MediaBundleType = .image
        
        if let urlsString = result.cf_image_id ?? result.cf_stream_id,
           let urlsData = urlsString.data(using: .utf8),
           let parsedUrls = try? JSONDecoder().decode([String].self, from: urlsData) {
            urls = parsedUrls
            type = result.cf_image_id != nil ? .image : .video
        }
        
        let bundleInfo = MediaBundleInfo(
            id: bundleId,
            type: type,
            urls: urls,
            width: result.width,
            height: result.height,
            duration: result.duration_sec.map { TimeInterval($0) }
        )
        
        // Cache the result
        await cacheActor.set(key: bundleId, value: bundleInfo)
        
        return bundleInfo
    }
    
    /// Get media URLs from a bundle ID (legacy method for backward compatibility)
    /// - Parameter bundleId: Media bundle ID
    /// - Returns: Array of media URLs
    public func getMediaURLs(bundleId: String) async throws -> [String] {
        let bundleInfo = try await getMediaBundleInfo(bundleId: bundleId)
        return bundleInfo.urls
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
    let width: Int?
    let height: Int?
    let duration_sec: Int?
}

// MARK: - Cache Support

/// Thread-safe cache actor for media bundles
private actor MediaBundleCacheActor {
    private var cache: [String: MediaBundleInfo] = [:]
    private let maxCacheSize = 100
    
    func get(key: String) -> MediaBundleInfo? {
        return cache[key]
    }
    
    func set(key: String, value: MediaBundleInfo) {
        // Simple LRU: remove oldest if at capacity
        if cache.count >= maxCacheSize {
            let firstKey = cache.keys.first!
            cache.removeValue(forKey: firstKey)
        }
        cache[key] = value
    }
    
    func remove(key: String) {
        cache.removeValue(forKey: key)
    }
    
    func clear() {
        cache.removeAll()
    }
}

// MARK: - Public Types
// Note: MediaBundleInfo, MediaBundleType, and MediaBundleError are now defined in AppFoundation
// to avoid circular dependencies. The NoOpMediaBundleService is also defined there.