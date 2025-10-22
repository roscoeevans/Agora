//
//  MediaPickerBridge.swift
//  UIKitBridge
//
//  Created by Agora Team on 2024.
//

import Foundation
import SwiftUI

#if canImport(PhotosUI) && canImport(UIKit)
import PhotosUI
import UIKit
import UniformTypeIdentifiers

/// Media type enumeration
public enum MediaType: Sendable {
    case image
    case video
    case unknown
}

/// Represents selected media from the picker
@available(iOS 26.0, *)
public struct SelectedMedia: Identifiable, Sendable {
    public let id = UUID()
    public let item: PhotosPickerItem
    public var data: Data?
    public var url: URL?
    public let type: MediaType
    
    public init(item: PhotosPickerItem, type: MediaType, data: Data? = nil, url: URL? = nil) {
        self.item = item
        self.type = type
        self.data = data
        self.url = url
    }
    
    internal init(item: PhotosPickerItem, type: MediaType) {
        self.item = item
        self.type = type
        self.data = nil
        self.url = nil
    }
}

/// SwiftUI wrapper for system photo picker
@available(iOS 26.0, *)
public struct MediaPickerBridge: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    let maxSelectionCount: Int
    let filter: PHPickerFilter?
    let onSelection: ([SelectedMedia]) -> Void
    
    public init(
        maxSelectionCount: Int = 4,
        filter: PHPickerFilter? = .any(of: [.images, .videos]),
        onSelection: @escaping ([SelectedMedia]) -> Void
    ) {
        self.maxSelectionCount = maxSelectionCount
        self.filter = filter
        self.onSelection = onSelection
    }
    
    public func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = maxSelectionCount
        configuration.filter = filter
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    public func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        // No updates needed
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self, dismiss: dismiss)
    }
    
    public class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: MediaPickerBridge
        let dismiss: DismissAction
        
        init(_ parent: MediaPickerBridge, dismiss: DismissAction) {
            self.parent = parent
            self.dismiss = dismiss
        }
        
        public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard !results.isEmpty else {
                dismiss()
                return
            }
            
            Task {
                var selectedMedia: [SelectedMedia] = []
                
                for result in results {
                    // Determine media type
                    let mediaType: MediaType
                    if result.itemProvider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                        mediaType = .image
                    } else if result.itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                        mediaType = .video
                    } else {
                        mediaType = .unknown
                        continue
                    }
                    
                    // Load data
                    if mediaType == .image {
                        if let data = try? await result.itemProvider.loadDataRepresentation(for: .image) {
                            let media = SelectedMedia(
                                item: PhotosPickerItem(itemIdentifier: result.assetIdentifier ?? UUID().uuidString),
                                type: mediaType,
                                data: data
                            )
                            selectedMedia.append(media)
                        }
                    } else if mediaType == .video {
                        // For videos, we need to load the file URL
                        if let url = try? await result.itemProvider.loadFileRepresentation(for: .movie) {
                            let media = SelectedMedia(
                                item: PhotosPickerItem(itemIdentifier: result.assetIdentifier ?? UUID().uuidString),
                                type: mediaType,
                                url: url
                            )
                            selectedMedia.append(media)
                        }
                    }
                }
                
                await MainActor.run {
                    parent.onSelection(selectedMedia)
                    dismiss()
                }
            }
        }
    }
}

/// Convenience methods for MediaPickerBridge
@available(iOS 26.0, *)
public extension MediaPickerBridge {
    /// Creates a photo-only picker
    static func photosPicker(
        maxSelectionCount: Int = 4,
        onSelection: @escaping ([SelectedMedia]) -> Void
    ) -> MediaPickerBridge {
        MediaPickerBridge(
            maxSelectionCount: maxSelectionCount,
            filter: .images,
            onSelection: onSelection
        )
    }
    
    /// Creates a video-only picker
    static func videosPicker(
        maxSelectionCount: Int = 1,
        onSelection: @escaping ([SelectedMedia]) -> Void
    ) -> MediaPickerBridge {
        MediaPickerBridge(
            maxSelectionCount: maxSelectionCount,
            filter: .videos,
            onSelection: onSelection
        )
    }
}

// MARK: - Helper Extensions

extension NSItemProvider {
    /// Load data representation asynchronously
    func loadDataRepresentation(for contentType: UTType) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            _ = loadDataRepresentation(forTypeIdentifier: contentType.identifier) { data, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let data = data {
                    continuation.resume(returning: data)
                } else {
                    continuation.resume(throwing: NSError(domain: "MediaPickerBridge", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data available"]))
                }
            }
        }
    }
    
    /// Load file representation asynchronously
    func loadFileRepresentation(for contentType: UTType) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            _ = loadFileRepresentation(forTypeIdentifier: contentType.identifier) { url, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let url = url {
                    // Copy to a temporary location
                    let tempURL = URL.temporaryDirectory.appending(path: "\(UUID().uuidString).\(url.pathExtension)")
                    try? FileManager.default.copyItem(at: url, to: tempURL)
                    continuation.resume(returning: tempURL)
                } else {
                    continuation.resume(throwing: NSError(domain: "MediaPickerBridge", code: -1, userInfo: [NSLocalizedDescriptionKey: "No file available"]))
                }
            }
        }
    }
}

#else
// Fallback for platforms without PhotosUI/SwiftUI/UIKit

/// Media type enumeration
public enum MediaType: Sendable {
    case image
    case video
    case unknown
}

/// Placeholder for platforms without PhotosUI
public struct SelectedMedia: Identifiable, Sendable {
    public let id = UUID()
    public var data: Data?
    public var url: URL?
    public var type: MediaType
    
    public init(type: MediaType) {
        self.type = type
    }
}

/// Placeholder MediaPickerBridge for platforms without UIKit
public struct MediaPickerBridge {
    public init() {}
}

#endif
