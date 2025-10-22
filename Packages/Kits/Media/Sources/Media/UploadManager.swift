import Foundation
import Networking

/// Media type enumeration
public enum MediaType: String, CaseIterable, Sendable {
    case image = "image"
    case video = "video"
    case audio = "audio"
}

/// Processed media information
public struct ProcessedMedia: Sendable {
    public let data: Data
    public let type: MediaType
    public let mimeType: String
    public let thumbnailData: Data?
    
    public init(data: Data, type: MediaType, mimeType: String, thumbnailData: Data? = nil) {
        self.data = data
        self.type = type
        self.mimeType = mimeType
        self.thumbnailData = thumbnailData
    }
}

/// Upload progress information
public struct UploadProgress {
    public let bytesUploaded: Int64
    public let totalBytes: Int64
    public let percentage: Double
    
    public init(bytesUploaded: Int64, totalBytes: Int64) {
        self.bytesUploaded = bytesUploaded
        self.totalBytes = totalBytes
        self.percentage = totalBytes > 0 ? Double(bytesUploaded) / Double(totalBytes) : 0.0
    }
}

/// Upload result information
public struct UploadResult {
    public let mediaId: String
    public let url: URL
    public let thumbnailURL: URL?
    public let size: Int64
    public let type: MediaType
    
    public init(
        mediaId: String,
        url: URL,
        thumbnailURL: URL? = nil,
        size: Int64,
        type: MediaType
    ) {
        self.mediaId = mediaId
        self.url = url
        self.thumbnailURL = thumbnailURL
        self.size = size
        self.type = type
    }
}

/// Upload configuration
public struct UploadConfig: Sendable {
    public let maxFileSize: Int64
    public let allowedMimeTypes: Set<String>
    public let chunkSize: Int
    
    public init(
        maxFileSize: Int64 = 100 * 1024 * 1024, // 100MB
        allowedMimeTypes: Set<String> = ["image/jpeg", "image/png", "image/heic", "video/mp4", "video/quicktime"],
        chunkSize: Int = 1024 * 1024 // 1MB chunks
    ) {
        self.maxFileSize = maxFileSize
        self.allowedMimeTypes = allowedMimeTypes
        self.chunkSize = chunkSize
    }
    
    public static let `default` = UploadConfig()
}

/// Upload errors
public enum UploadError: LocalizedError {
    case fileTooLarge(Int64, Int64) // actual size, max size
    case unsupportedFileType(String)
    case networkError(Error)
    case serverError(Int, String)
    case uploadCancelled
    case invalidResponse
    
    public var errorDescription: String? {
        switch self {
        case .fileTooLarge(let actual, let max):
            return "File size (\(actual) bytes) exceeds maximum allowed size (\(max) bytes)"
        case .unsupportedFileType(let type):
            return "Unsupported file type: \(type)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message)"
        case .uploadCancelled:
            return "Upload was cancelled"
        case .invalidResponse:
            return "Invalid server response"
        }
    }
}

/// Manages media uploads to Cloudflare
@MainActor
public final class UploadManager {
    public static let shared = UploadManager()
    
    private let config: UploadConfig
    private let urlSession: URLSession
    
    private init(config: UploadConfig = .default) {
        self.config = config
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 60
        configuration.timeoutIntervalForResource = 300
        self.urlSession = URLSession(configuration: configuration)
    }
    
    /// Uploads media data to Cloudflare
    public func uploadMedia(
        data: Data,
        type: MediaType,
        mimeType: String,
        progressHandler: @escaping (UploadProgress) -> Void = { _ in }
    ) async throws -> UploadResult {
        // Validate file size
        guard Int64(data.count) <= config.maxFileSize else {
            throw UploadError.fileTooLarge(Int64(data.count), config.maxFileSize)
        }
        
        // Validate MIME type
        guard config.allowedMimeTypes.contains(mimeType) else {
            throw UploadError.unsupportedFileType(mimeType)
        }
        
        // Create upload request
        let uploadURL = try await getUploadURL(for: type, mimeType: mimeType)
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "PUT"
        request.setValue(mimeType, forHTTPHeaderField: "Content-Type")
        request.setValue("\(data.count)", forHTTPHeaderField: "Content-Length")
        
        // Perform upload with progress tracking
        let (responseData, response) = try await urlSession.upload(for: request, from: data)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw UploadError.invalidResponse
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            let errorMessage = String(data: responseData, encoding: .utf8) ?? "Unknown error"
            throw UploadError.serverError(httpResponse.statusCode, errorMessage)
        }
        
        // Parse response
        return try parseUploadResponse(responseData, type: type)
    }
    
    /// Uploads processed media
    public func uploadProcessedMedia(
        _ processedMedia: ProcessedMedia,
        progressHandler: @escaping (UploadProgress) -> Void = { _ in }
    ) async throws -> UploadResult {
        let mimeType = getMimeType(for: processedMedia.type)
        
        return try await uploadMedia(
            data: processedMedia.data,
            type: processedMedia.type,
            mimeType: mimeType,
            progressHandler: progressHandler
        )
    }
    
    /// Cancels an ongoing upload (placeholder for future implementation)
    public func cancelUpload(uploadId: String) async {
        // TODO: Implement upload cancellation
        // This would require tracking active uploads and their tasks
    }
    
    // MARK: - Private Methods
    
    private func getUploadURL(for type: MediaType, mimeType: String) async throws -> URL {
        // TODO: Replace with actual API call to get signed upload URL
        // This is a placeholder implementation
        
        let baseURL = "https://api.agora.app/v1/media/upload"
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "type", value: type == .image ? "image" : "video"),
            URLQueryItem(name: "mime_type", value: mimeType)
        ]
        
        guard let url = components.url else {
            throw UploadError.invalidResponse
        }
        
        return url
    }
    
    private func parseUploadResponse(_ data: Data, type: MediaType) throws -> UploadResult {
        // TODO: Replace with actual response parsing
        // This is a placeholder implementation
        
        struct UploadResponse: Codable {
            let mediaId: String
            let url: String
            let thumbnailURL: String?
            let size: Int64
        }
        
        do {
            let response = try JSONDecoder().decode(UploadResponse.self, from: data)
            
            guard let url = URL(string: response.url) else {
                throw UploadError.invalidResponse
            }
            
            let thumbnailURL = response.thumbnailURL.flatMap { URL(string: $0) }
            
            return UploadResult(
                mediaId: response.mediaId,
                url: url,
                thumbnailURL: thumbnailURL,
                size: response.size,
                type: type
            )
        } catch {
            throw UploadError.invalidResponse
        }
    }
    
    private func getMimeType(for type: MediaType) -> String {
        switch type {
        case .image:
            return "image/jpeg"
        case .video:
            return "video/mp4"
        case .audio:
            return "audio/mpeg"
        }
    }
}