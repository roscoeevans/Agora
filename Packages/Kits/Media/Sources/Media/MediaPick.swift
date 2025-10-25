import Foundation

/// Represents a media item selected for upload
public struct MediaPick: Sendable {
    public let data: Data
    public let filename: String
    public let mimeType: String
    
    public init(data: Data, filename: String, mimeType: String) {
        self.data = data
        self.filename = filename
        self.mimeType = mimeType
    }
}