//
//  ComposeViewModel.swift
//  Agora
//
//  Created by Agora Team on 2024.
//

import Foundation
import SwiftUI
import PhotosUI
import UIKitBridge
import Networking
import Media
import Verification
import Authentication

#if canImport(UIKit)
import UIKit
#endif

// MARK: - Media Types

public enum MediaType: String, Codable, CaseIterable, Sendable {
    case photo
    case video
}

public struct MediaItem: Identifiable, Sendable {
    public let id: String
    public let type: MediaType
    public var imageData: Data?
    public var videoURL: URL?
    public let url: URL?
    public let thumbnailURL: URL?
    public let width: Int?
    public let height: Int?
    
    public init(
        type: MediaType,
        imageData: Data? = nil,
        videoURL: URL? = nil,
        url: URL? = nil,
        thumbnailURL: URL? = nil,
        width: Int? = nil,
        height: Int? = nil
    ) {
        self.id = UUID().uuidString
        self.type = type
        self.imageData = imageData
        self.videoURL = videoURL
        self.url = url
        self.thumbnailURL = thumbnailURL
        self.width = width
        self.height = height
    }
}

/// Custom transferable type for video
struct VideoTransferable: Transferable {
    let url: URL
    
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { video in
            SentTransferredFile(video.url)
        } importing: { received in
            let copy = URL.temporaryDirectory.appending(path: "\(UUID().uuidString).mov")
            try FileManager.default.copyItem(at: received.file, to: copy)
            return Self(url: copy)
        }
    }
}

// MARK: - ComposeViewModel

@MainActor
@Observable
public class ComposeViewModel {
    public var text: String = ""
    public var selectedMedia: [MediaItem] = []
    public var selfDestructDuration: SelfDestructDuration = .none
    public var linkPreview: LinkPreview?
    public var quotePostId: String?
    public var isPosting = false
    public var isLoadingLinkPreview = false
    public var error: Error?
    
    public var characterCount: Int { text.count }
    public var isOverLimit: Bool { characterCount > 280 }
    public var canPost: Bool { 
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && 
        !isOverLimit && 
        !isPosting 
    }
    
    private let networking: any AgoraAPIClient
    private let verificationManager: AppAttestManager
    private let mediaBundleService: any MediaBundleServiceProtocol
    private let authStateManager: AuthStateManager
    
    /// Initialize ComposeViewModel with explicit dependencies
    /// Following the DI rule pattern
    public init(
        networking: any AgoraAPIClient,
        verificationManager: AppAttestManager,
        mediaBundleService: any MediaBundleServiceProtocol,
        authStateManager: AuthStateManager
    ) {
        self.networking = networking
        self.verificationManager = verificationManager
        self.mediaBundleService = mediaBundleService
        self.authStateManager = authStateManager
    }
    
    public func post() async {
        guard canPost else { return }
        
        isPosting = true
        defer { isPosting = false }
        
        do {
            // Calculate self-destruct timestamp if set
            let selfDestructAt = selfDestructDuration.date()
            
            // Upload media if selected
            var mediaBundleId: String?
            if !selectedMedia.isEmpty {
                mediaBundleId = try await uploadMedia()
            }
            
            // Create the post
            let _ = try await networking.createPost(
                text: text,
                mediaBundleId: mediaBundleId,
                linkUrl: linkPreview?.url,
                quotePostId: quotePostId,
                replyToPostId: nil, // TODO: Support replies when thread view is implemented
                selfDestructAt: selfDestructAt
            )
            
            // Clear the compose form on successful post
            clearDraft()
            
        } catch {
            self.error = error
            print("[ComposeViewModel] ❌ Failed to create post: \(error)")
            if let networkError = error as? NetworkError {
                print("[ComposeViewModel] ❌ Network error details: \(networkError)")
            }
        }
    }
    
    /// Upload selected media and return media bundle ID
    private func uploadMedia() async throws -> String {
        guard !selectedMedia.isEmpty else {
            throw ComposeError.noMediaSelected
        }
        
        // Get user ID from auth state
        guard let userId = authStateManager.state.currentUser?.id else {
            throw ComposeError.userNotAuthenticated
        }
        
        // Separate images and videos
        let images = selectedMedia.filter { $0.type == .photo }
        let videos = selectedMedia.filter { $0.type == .video }
        
        if !images.isEmpty {
            // Upload images
            let imageDataArray = images.compactMap { $0.imageData }
            guard !imageDataArray.isEmpty else {
                throw ComposeError.invalidImageData
            }
            
            return try await mediaBundleService.createImageBundle(
                imageDataArray: imageDataArray,
                userId: userId
            )
        } else if let video = videos.first {
            // Upload video
            guard let videoURL = video.videoURL else {
                throw ComposeError.invalidVideoData
            }
            
            return try await mediaBundleService.createVideoBundle(
                videoURL: videoURL,
                userId: userId
            )
        } else {
            throw ComposeError.unsupportedMediaType
        }
    }
    
    /// Detect URLs in text and fetch link preview
    public func detectAndFetchLinkPreview() async {
        // Simple URL detection regex
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let range = NSRange(text.startIndex..., in: text)
        
        guard let match = detector?.firstMatch(in: text, options: [], range: range),
              let url = match.url else {
            linkPreview = nil
            return
        }
        
        isLoadingLinkPreview = true
        defer { isLoadingLinkPreview = false }
        
        do {
            // TODO: Call fetch-link-preview Edge Function
            // let preview = try await networking.fetchLinkPreview(url: url.absoluteString)
            // linkPreview = preview
            
            // Placeholder
            try await Task.sleep(nanoseconds: 1_000_000_000)
            linkPreview = LinkPreview(
                url: url.absoluteString,
                title: "Preview Title",
                description: "Preview description",
                imageUrl: nil,
                siteName: url.host
            )
        } catch {
            print("Failed to fetch link preview: \(error)")
            linkPreview = nil
        }
    }
    
    public func saveDraft() {
        // TODO: Implement draft persistence
        // Save current text and media to local storage
    }
    
    public func loadDraft() {
        // TODO: Implement draft loading
        // Load saved draft from local storage
    }
    
    public func clearDraft() {
        text = ""
        selectedMedia.removeAll()
        selfDestructDuration = .none
        linkPreview = nil
        quotePostId = nil
        error = nil
    }
    
    public func addMedia(_ item: MediaItem) {
        // Enforce media constraints: up to 4 photos OR 1 video, no mixed media
        if item.type == .photo {
            // If adding a photo, remove any videos first
            selectedMedia.removeAll { $0.type == .video }
            // Add photo if under limit
            if selectedMedia.count < 4 {
                selectedMedia.append(item)
            }
        } else if item.type == .video {
            // If adding a video, remove all photos first
            selectedMedia.removeAll { $0.type == .photo }
            // Add video if none exists
            if !selectedMedia.contains(where: { $0.type == .video }) {
                selectedMedia.append(item)
            }
        }
    }
    
    public func removeMedia(_ item: MediaItem) {
        selectedMedia.removeAll { $0.id == item.id }
    }
    
    /// Process selected photos from PhotosPicker
    @MainActor
    public func processPhotos(_ items: [PhotosPickerItem]) async {
        // Clear any existing videos when adding photos
        selectedMedia.removeAll { $0.type == .video }
        
        for item in items.prefix(4) { // Limit to 4 photos
            if let data = try? await item.loadTransferable(type: Data.self) {
                #if canImport(UIKit)
                if let image = UIImage(data: data) {
                    let mediaItem = MediaItem(
                        type: .photo,
                        imageData: data,
                        width: Int(image.size.width),
                        height: Int(image.size.height)
                    )
                    selectedMedia.append(mediaItem)
                }
                #else
                let mediaItem = MediaItem(
                    type: .photo,
                    imageData: data
                )
                selectedMedia.append(mediaItem)
                #endif
            }
        }
    }
    
    /// Process selected video from PhotosPicker
    @MainActor
    public func processVideo(_ item: PhotosPickerItem) async {
        // Clear all existing media when adding a video
        selectedMedia.removeAll()
        
        if let movie = try? await item.loadTransferable(type: VideoTransferable.self) {
            let mediaItem = MediaItem(
                type: .video,
                videoURL: movie.url
            )
            selectedMedia.append(mediaItem)
        }
    }
    
    /// Process selected photos from UIKitBridge MediaPickerBridge
    @MainActor
    public func processMediaPickerPhotos(_ items: [SelectedMedia]) async {
        // Clear any existing videos when adding photos
        selectedMedia.removeAll { $0.type == .video }
        
        for item in items.prefix(4) { // Limit to 4 photos
            guard item.type == .image, let data = item.data else { continue }
            
            #if canImport(UIKit)
            if let image = UIImage(data: data) {
                let mediaItem = MediaItem(
                    type: .photo,
                    imageData: data,
                    width: Int(image.size.width),
                    height: Int(image.size.height)
                )
                selectedMedia.append(mediaItem)
            }
            #else
            let mediaItem = MediaItem(
                type: .photo,
                imageData: data
            )
            selectedMedia.append(mediaItem)
            #endif
        }
    }
    
    /// Process selected video from UIKitBridge MediaPickerBridge
    @MainActor
    public func processMediaPickerVideo(_ item: SelectedMedia?) async {
        guard let item = item, item.type == .video, let videoURL = item.url else { return }
        
        // Clear all existing media when adding a video
        selectedMedia.removeAll()
        
        let mediaItem = MediaItem(
            type: .video,
            videoURL: videoURL
        )
        selectedMedia.append(mediaItem)
    }
}

// MARK: - Link Preview

/// Link preview data model
public struct LinkPreview: Codable, Sendable {
    public let url: String
    public let title: String?
    public let description: String?
    public let imageUrl: String?
    public let siteName: String?
    
    public init(
        url: String,
        title: String? = nil,
        description: String? = nil,
        imageUrl: String? = nil,
        siteName: String? = nil
    ) {
        self.url = url
        self.title = title
        self.description = description
        self.imageUrl = imageUrl
        self.siteName = siteName
    }
}

// MARK: - ComposeError

public enum ComposeError: LocalizedError, Sendable {
    case noMediaSelected
    case invalidImageData
    case invalidVideoData
    case unsupportedMediaType
    case uploadFailed
    case userNotAuthenticated
    
    public var errorDescription: String? {
        switch self {
        case .noMediaSelected:
            return "No media selected for upload"
        case .invalidImageData:
            return "Invalid image data"
        case .invalidVideoData:
            return "Invalid video data"
        case .unsupportedMediaType:
            return "Unsupported media type"
        case .uploadFailed:
            return "Failed to upload media"
        case .userNotAuthenticated:
            return "User not authenticated"
        }
    }
}