import Foundation
import AVFoundation

/// Video processing utilities for posts
public final class VideoProcessor: Sendable {
    public static let shared = VideoProcessor()
    
    private init() {}
    
    // MARK: - Video Validation
    
    /// Validate video file and extract metadata
    /// - Parameter videoURL: Local URL of the video file
    /// - Returns: Video metadata (dimensions, duration)
    public func validateAndExtractMetadata(_ videoURL: URL) async throws -> VideoMetadata {
        let asset = AVURLAsset(url: videoURL)
        
        // Check if file exists and is readable
        guard asset.isReadable else {
            throw VideoError.invalidFile
        }
        
        // Get video tracks
        let videoTracks = try await asset.loadTracks(withMediaType: .video)
        guard let videoTrack = videoTracks.first else {
            throw VideoError.noVideoTrack
        }
        
        // Get dimensions
        let naturalSize = try await videoTrack.load(.naturalSize)
        let dimensions = (width: Int(abs(naturalSize.width)), height: Int(abs(naturalSize.height)))
        
        // Get duration
        let duration = try await asset.load(.duration)
        let durationSeconds = CMTimeGetSeconds(duration)
        
        // Validate dimensions (minimum 480p, maximum 4K)
        guard dimensions.width >= 480 && dimensions.height >= 480 else {
            throw VideoError.resolutionTooLow
        }
        
        guard dimensions.width <= 3840 && dimensions.height <= 2160 else {
            throw VideoError.resolutionTooHigh
        }
        
        // Validate duration (minimum 1 second, maximum 5 minutes)
        guard durationSeconds >= 1.0 else {
            throw VideoError.durationTooShort
        }
        
        guard durationSeconds <= 300.0 else {
            throw VideoError.durationTooLong
        }
        
        return VideoMetadata(
            width: dimensions.width,
            height: dimensions.height,
            duration: durationSeconds
        )
    }
    
    // MARK: - Thumbnail Generation
    
    /// Generate thumbnail image from video
    /// - Parameters:
    ///   - videoURL: Local URL of the video file
    ///   - time: Time in video to capture (default: 1 second)
    /// - Returns: CGImage thumbnail
    public func generateThumbnail(from videoURL: URL, at time: TimeInterval = 1.0) async throws -> CGImage {
        let asset = AVURLAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.requestedTimeToleranceAfter = .zero
        imageGenerator.requestedTimeToleranceBefore = .zero
        
        let time = CMTime(seconds: time, preferredTimescale: 600)
        
        return try await withCheckedThrowingContinuation { continuation in
            imageGenerator.generateCGImageAsynchronously(for: time) { cgImage, _, error in
                if let error = error {
                    continuation.resume(throwing: VideoError.thumbnailGenerationFailed(error))
                    return
                }
                
                guard let cgImage = cgImage else {
                    continuation.resume(throwing: VideoError.thumbnailGenerationFailed(nil))
                    return
                }
                
                continuation.resume(returning: cgImage)
            }
        }
    }
    
    // MARK: - Compression
    
    /// Compress video if it exceeds size limit
    /// - Parameters:
    ///   - videoURL: Local URL of the video file
    ///   - maxSizeBytes: Maximum file size in bytes (default: 50MB)
    /// - Returns: URL of compressed video (may be same as input if no compression needed)
    public func compressIfNeeded(videoURL: URL, maxSizeBytes: Int = 50 * 1024 * 1024) async throws -> URL {
        let fileSize = try videoURL.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
        
        // If file is already small enough, return original
        if fileSize <= maxSizeBytes {
            return videoURL
        }
        
        // For now, return original URL
        // TODO: Implement actual video compression using AVAssetExportSession
        return videoURL
    }
}

// MARK: - Video Metadata

public struct VideoMetadata: Sendable {
    public let width: Int
    public let height: Int
    public let duration: TimeInterval
    
    public init(width: Int, height: Int, duration: TimeInterval) {
        self.width = width
        self.height = height
        self.duration = duration
    }
}

// MARK: - Video Errors

public enum VideoError: LocalizedError, Sendable {
    case invalidFile
    case noVideoTrack
    case resolutionTooLow
    case resolutionTooHigh
    case durationTooShort
    case durationTooLong
    case thumbnailGenerationFailed(Error?)
    case compressionFailed(Error?)
    
    public var errorDescription: String? {
        switch self {
        case .invalidFile:
            return "Invalid or unreadable video file"
        case .noVideoTrack:
            return "No video track found in file"
        case .resolutionTooLow:
            return "Video resolution too low (minimum 480p required)"
        case .resolutionTooHigh:
            return "Video resolution too high (maximum 4K allowed)"
        case .durationTooShort:
            return "Video duration too short (minimum 1 second required)"
        case .durationTooLong:
            return "Video duration too long (maximum 5 minutes allowed)"
        case .thumbnailGenerationFailed(let error):
            return "Failed to generate thumbnail: \(error?.localizedDescription ?? "Unknown error")"
        case .compressionFailed(let error):
            return "Failed to compress video: \(error?.localizedDescription ?? "Unknown error")"
        }
    }
}