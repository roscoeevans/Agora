//
//  ComposeViewModel.swift
//  Agora
//
//  Created by Agora Team on 2024.
//

import Foundation
import SwiftUI
import Networking
import Media
import Verification

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
    
    /// Initialize ComposeViewModel with explicit dependencies
    /// Following the DI rule pattern
    public init(
        networking: any AgoraAPIClient,
        verificationManager: AppAttestManager
    ) {
        self.networking = networking
        self.verificationManager = verificationManager
    }
    
    public func post() async {
        guard canPost else { return }
        
        isPosting = true
        defer { isPosting = false }
        
        do {
            // TODO: This is a placeholder implementation
            // Full implementation requires:
            // 1. Get user ID from session
            // 2. Upload media via MediaBundleService
            // 3. Fetch link preview if URL detected
            // 4. Call create-post Edge Function
            
            // For now, simulate network delay
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            // Calculate self-destruct timestamp if set
            let selfDestructAt = selfDestructDuration.date()
            
            // TODO: Replace with actual API call
            // let post = try await networking.createPost(
            //     text: text,
            //     mediaBundleId: mediaBundleId,
            //     linkUrl: linkPreview?.url,
            //     quotePostId: quotePostId,
            //     selfDestructAt: selfDestructAt
            // )
            
            // Clear the compose form on successful post
            clearDraft()
            
        } catch {
            self.error = error
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
        selectedMedia.append(item)
    }
    
    public func removeMedia(_ item: MediaItem) {
        selectedMedia.removeAll { $0.id == item.id }
    }
}

public struct MediaItem: Identifiable, Codable, Sendable {
    public let id: String
    public let type: MediaType
    public let url: URL?
    public let thumbnailURL: URL?
    public let width: Int?
    public let height: Int?
    
    public init(
        type: MediaType,
        url: URL? = nil,
        thumbnailURL: URL? = nil,
        width: Int? = nil,
        height: Int? = nil
    ) {
        self.id = UUID().uuidString
        self.type = type
        self.url = url
        self.thumbnailURL = thumbnailURL
        self.width = width
        self.height = height
    }
}

public enum MediaType: String, Codable, CaseIterable, Sendable {
    case photo
    case video
}

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