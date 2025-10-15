import Foundation
import AVFoundation
import UIKit

/// Video processing utilities for posts
public final class VideoProcessor: Sendable {
    public static let shared = VideoProcessor()
    
    private init() {}
    
    // MARK: - Validation
    
    /// Validate video duration (max 5 minutes)
    /// - Parameter videoURL: Local URL of the video file
    /// - Returns: Duration in seconds
    /// - Throws: VideoError if duration exceeds 5 minutes or cannot be read
    public func validateDuration(_ videoURL: URL) async throws -> TimeInterval {
        let asset = AVURLAsset(url: videoURL)
        
        let duration = try await asset.load(.duration)
        let durationSeconds = CMTimeGetSeconds(duration)
        
        guard durationSeconds > 0 else {
            throw VideoError.invalidDuration
        }
        
        let maxDuration: TimeInterval = 5 * 60 // 5 minutes
        guard durationSeconds <= maxDuration else {
            throw VideoError.durationTooLong(actual: durationSeconds, max: maxDuration)
        }
        
        return durationSeconds
    }
    
    /// Extract video dimensions
    /// - Parameter videoURL: Local URL of the video file
    /// - Returns: Tuple of (width, height)
    public func extractDimensions(_ videoURL: URL) async throws -> (width: Int, height: Int) {
        let asset = AVURLAsset(url: videoURL)
        
        guard let track = try await asset.loadTracks(withMediaType: .video).first else {
            throw VideoError.noVideoTrack
        }
        
        let naturalSize = try await track.load(.naturalSize)
        let transform = try await track.load(.preferredTransform)
        
        // Apply transform to get actual display size
        let size = naturalSize.applying(transform)
        
        return (width: Int(abs(size.width)), height: Int(abs(size.height)))
    }
    
    // MARK: - Thumbnail Generation
    
    /// Generate thumbnail image from video
    /// - Parameters:
    ///   - videoURL: Local URL of the video file
    ///   - time: Time in video to capture (default: 1 second)
    /// - Returns: UIImage thumbnail
    public func generateThumbnail(from videoURL: URL, at time: TimeInterval = 1.0) async throws -> UIImage {
        let asset = AVURLAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.requestedTimeToleranceAfter = .zero
        imageGenerator.requestedTimeToleranceBefore = .zero
        
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        
        return try await withCheckedThrowingContinuation { continuation in
            imageGenerator.generateCGImageAsynchronously(for: cmTime) { cgImage, actualTime, error in
                if let error = error {
                    continuation.resume(throwing: VideoError.thumbnailGenerationFailed(error))
                    return
                }
                
                guard let cgImage = cgImage else {
                    continuation.resume(throwing: VideoError.thumbnailGenerationFailed(nil))
                    return
                }
                
                let image = UIImage(cgImage: cgImage)
                continuation.resume(returning: image)
            }
        }
    }
    
    // MARK: - Compression
    
    /// Compress video if it exceeds size limit
    /// - Parameters:
    ///   - videoURL: Local URL of the video file
    ///   - maxSizeBytes: Maximum file size in bytes (default: 50MB)
    /// - Returns: URL of compressed video, or original if no compression needed
    public func compressIfNeeded(_ videoURL: URL, maxSizeBytes: Int = 50 * 1024 * 1024) async throws -> URL {
        // Check current file size
        let fileAttributes = try FileManager.default.attributesOfItem(atPath: videoURL.path)
        guard let fileSize = fileAttributes[.size] as? Int else {
            throw VideoError.cannotReadFileSize
        }
        
        // If under limit, return original
        if fileSize <= maxSizeBytes {
            return videoURL
        }
        
        // Compress video
        let asset = AVURLAsset(url: videoURL)
        
        // Create export session with medium quality preset
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetMediumQuality) else {
            throw VideoError.compressionFailed
        }
        
        // Output path
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp4")
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        
        await exportSession.export()
        
        guard exportSession.status == .completed else {
            throw VideoError.compressionFailed
        }
        
        return outputURL
    }
    
    // MARK: - Validation Helper
    
    /// Perform all validation checks on a video
    /// - Parameter videoURL: Local URL of the video file
    /// - Returns: VideoMetadata with duration, dimensions
    public func validateAndExtractMetadata(_ videoURL: URL) async throws -> VideoMetadata {
        let duration = try await validateDuration(videoURL)
        let dimensions = try await extractDimensions(videoURL)
        
        return VideoMetadata(
            duration: duration,
            width: dimensions.width,
            height: dimensions.height
        )
    }
}

// MARK: - Video Metadata

public struct VideoMetadata: Sendable {
    public let duration: TimeInterval
    public let width: Int
    public let height: Int
    
    public init(duration: TimeInterval, width: Int, height: Int) {
        self.duration = duration
        self.width = width
        self.height = height
    }
}

// MARK: - Video Errors

public enum VideoError: LocalizedError, Sendable {
    case invalidDuration
    case durationTooLong(actual: TimeInterval, max: TimeInterval)
    case noVideoTrack
    case thumbnailGenerationFailed(Error?)
    case cannotReadFileSize
    case compressionFailed
    
    public var errorDescription: String? {
        switch self {
        case .invalidDuration:
            return "Video has invalid duration"
        case .durationTooLong(let actual, let max):
            let actualMinutes = Int(actual / 60)
            let maxMinutes = Int(max / 60)
            return "Video is too long (\(actualMinutes)m). Maximum duration is \(maxMinutes) minutes."
        case .noVideoTrack:
            return "Video file has no video track"
        case .thumbnailGenerationFailed:
            return "Failed to generate video thumbnail"
        case .cannotReadFileSize:
            return "Cannot read video file size"
        case .compressionFailed:
            return "Video compression failed"
        }
    }
}

