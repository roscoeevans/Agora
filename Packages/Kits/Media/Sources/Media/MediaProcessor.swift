import Foundation
#if canImport(UIKit)
import UIKit
#endif
import AVFoundation
import UniformTypeIdentifiers

/// Configuration for media processing
public struct MediaProcessingConfig: Sendable {
    public let maxImageSize: CGSize
    public let imageCompressionQuality: CGFloat
    public let maxVideoSize: CGSize
    public let videoCompressionPreset: String
    
    public init(
        maxImageSize: CGSize = CGSize(width: 1920, height: 1920),
        imageCompressionQuality: CGFloat = 0.8,
        maxVideoSize: CGSize = CGSize(width: 1920, height: 1080),
        videoCompressionPreset: String = AVAssetExportPresetMediumQuality
    ) {
        self.maxImageSize = maxImageSize
        self.imageCompressionQuality = imageCompressionQuality
        self.maxVideoSize = maxVideoSize
        self.videoCompressionPreset = videoCompressionPreset
    }
    
    public static let `default` = MediaProcessingConfig()
}

/// Processed media result
public struct ProcessedMedia {
    public let originalURL: URL?
    public let processedData: Data
    public let processedURL: URL?
    public let type: MediaType
    public let size: CGSize?
    public let duration: TimeInterval?
    
    public init(
        originalURL: URL? = nil,
        processedData: Data,
        processedURL: URL? = nil,
        type: MediaType,
        size: CGSize? = nil,
        duration: TimeInterval? = nil
    ) {
        self.originalURL = originalURL
        self.processedData = processedData
        self.processedURL = processedURL
        self.type = type
        self.size = size
        self.duration = duration
    }
}

/// Media processing errors
public enum MediaProcessingError: LocalizedError {
    case invalidImageData
    case invalidVideoURL
    case compressionFailed
    case unsupportedMediaType
    case processingTimeout
    
    public var errorDescription: String? {
        switch self {
        case .invalidImageData:
            return "Invalid image data provided"
        case .invalidVideoURL:
            return "Invalid video URL provided"
        case .compressionFailed:
            return "Media compression failed"
        case .unsupportedMediaType:
            return "Unsupported media type"
        case .processingTimeout:
            return "Media processing timed out"
        }
    }
}

/// Handles image and video compression and processing
@available(iOS 26.0, macOS 12.0, *)
@MainActor
public final class MediaProcessor {
    public static let shared = MediaProcessor()
    
    private init() {}
    
    /// Processes image data with compression and resizing
    public func processImage(
        data: Data,
        config: MediaProcessingConfig = .default
    ) async throws -> ProcessedMedia {
        #if canImport(UIKit)
        guard let image = UIImage(data: data) else {
            throw MediaProcessingError.invalidImageData
        }
        
        // Resize image if needed
        let resizedImage = await resizeImage(image, maxSize: config.maxImageSize)
        
        // Compress image
        guard let compressedData = resizedImage.jpegData(compressionQuality: config.imageCompressionQuality) else {
            throw MediaProcessingError.compressionFailed
        }
        
        return ProcessedMedia(
            processedData: compressedData,
            type: .image,
            size: resizedImage.size
        )
        #else
        // macOS fallback - basic processing without UIKit
        return ProcessedMedia(
            processedData: data,
            type: .image,
            size: nil
        )
        #endif
    }
    
    /// Processes video from URL with compression
    @available(iOS 26.0, macOS 12.0, *)
    public func processVideo(
        url: URL,
        config: MediaProcessingConfig = .default
    ) async throws -> ProcessedMedia {
        let asset = AVAsset(url: url)
        
        // Get video dimensions and duration
        let tracks = try await asset.loadTracks(withMediaType: .video)
        guard let videoTrack = tracks.first else {
            throw MediaProcessingError.invalidVideoURL
        }
        
        let naturalSize = try await videoTrack.load(.naturalSize)
        let duration = try await asset.load(.duration)
        
        // Create export session
        guard let exportSession = AVAssetExportSession(
            asset: asset,
            presetName: config.videoCompressionPreset
        ) else {
            throw MediaProcessingError.compressionFailed
        }
        
        // Configure output
        let outputURL = createTemporaryVideoURL()
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        
        // Export video
        await exportSession.export()
        
        guard exportSession.status == .completed,
              let outputURL = exportSession.outputURL else {
            throw MediaProcessingError.compressionFailed
        }
        
        // Read processed data
        let processedData = try Data(contentsOf: outputURL)
        
        return ProcessedMedia(
            originalURL: url,
            processedData: processedData,
            processedURL: outputURL,
            type: .video,
            size: naturalSize,
            duration: duration.seconds
        )
    }
    
    /// Generates thumbnail from video
    #if canImport(UIKit)
    public func generateVideoThumbnail(
        url: URL,
        time: CMTime = CMTime(seconds: 1, preferredTimescale: 60)
    ) async throws -> UIImage {
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        let cgImage = try await imageGenerator.image(at: time).image
        return UIImage(cgImage: cgImage)
    }
    #endif
    
    // MARK: - Private Methods
    
    #if canImport(UIKit)
    private func resizeImage(_ image: UIImage, maxSize: CGSize) async -> UIImage {
        let size = image.size
        
        // Check if resizing is needed
        if size.width <= maxSize.width && size.height <= maxSize.height {
            return image
        }
        
        // Calculate new size maintaining aspect ratio
        let widthRatio = maxSize.width / size.width
        let heightRatio = maxSize.height / size.height
        let ratio = min(widthRatio, heightRatio)
        
        let newSize = CGSize(
            width: size.width * ratio,
            height: size.height * ratio
        )
        
        // Resize image
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    #endif
    
    private func createTemporaryVideoURL() -> URL {
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileName = "processed_video_\(UUID().uuidString).mp4"
        return tempDirectory.appendingPathComponent(fileName)
    }
}