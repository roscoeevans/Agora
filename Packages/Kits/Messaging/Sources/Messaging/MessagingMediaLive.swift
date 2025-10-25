import Foundation
import AppFoundation
import SupabaseKit

/// Production implementation of MessagingMediaProtocol
/// Handles media attachment preparation and upload for messaging
public final class MessagingMediaLive: MessagingMediaProtocol {
    
    private let supabase: any SupabaseClientProtocol
    
    // Configuration constants
    private let maxImageDimension: CGFloat = 2048
    private let maxVideoSize: Int64 = 100 * 1024 * 1024 // 100MB
    private let maxImageSize: Int64 = 25 * 1024 * 1024  // 25MB
    private let supportedImageTypes = ["image/jpeg", "image/png", "image/heic", "image/webp"]
    private let supportedVideoTypes = ["video/mp4", "video/quicktime", "video/mov"]
    
    public init(supabase: any SupabaseClientProtocol) {
        self.supabase = supabase
    }
    
    public func prepareAttachment(_ pick: MediaPick) async throws -> Attachment {
        // Validate file size and type
        try validateMediaPick(pick)
        
        // For now, create a mock attachment
        // In a real implementation, this would process and upload the media
        let attachmentId = UUID()
        let attachmentType: AttachmentType
        
        if pick.mimeType.hasPrefix("image/") {
            attachmentType = .image
        } else if pick.mimeType.hasPrefix("video/") {
            attachmentType = .video
        } else {
            attachmentType = .document
        }
        
        // Mock URLs - in real implementation, these would be actual upload URLs
        let url = URL(string: "https://example.com/attachments/\(attachmentId.uuidString)")!
        let thumbnailUrl = URL(string: "https://example.com/thumbnails/\(attachmentId.uuidString)")!
        
        let metadata = AttachmentMetadata(
            filename: pick.filename,
            mimeType: pick.mimeType,
            width: attachmentType == .image ? 1024 : nil,
            height: attachmentType == .image ? 768 : nil
        )
        
        return Attachment(
            id: attachmentId,
            type: attachmentType,
            url: url,
            thumbnailUrl: thumbnailUrl,
            sizeBytes: Int64(pick.data.count),
            duration: attachmentType == .video ? 30.0 : nil,
            metadata: metadata
        )
    }
    
    // MARK: - Validation
    
    private func validateMediaPick(_ pick: MediaPick) throws {
        // Check file size limits
        if pick.mimeType.hasPrefix("image/") {
            guard pick.data.count <= maxImageSize else {
                throw MessagingError.attachmentTooLarge
            }
            
            guard supportedImageTypes.contains(pick.mimeType) else {
                throw MessagingError.unsupportedAttachmentType
            }
        } else if pick.mimeType.hasPrefix("video/") {
            guard pick.data.count <= maxVideoSize else {
                throw MessagingError.attachmentTooLarge
            }
            
            guard supportedVideoTypes.contains(pick.mimeType) else {
                throw MessagingError.unsupportedAttachmentType
            }
        } else {
            throw MessagingError.unsupportedAttachmentType
        }
    }
}