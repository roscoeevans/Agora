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
    public var isPosting = false
    public var error: Error?
    public var characterCount: Int { text.count }
    public var isOverLimit: Bool { characterCount > 70 }
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
            // TODO: Implement actual posting logic
            // 1. Verify device attestation
            // 2. Upload media if any
            // 3. Submit post to API
            // 4. Clear draft on success
            
            // Simulate network delay
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            // Clear the compose form on successful post
            clearDraft()
            
        } catch {
            self.error = error
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