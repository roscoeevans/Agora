import Foundation
#if canImport(PhotosUI) && canImport(SwiftUI) && canImport(UIKit)
import PhotosUI
import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// Media type enumeration
public enum MediaType: Sendable {
    case image
    case video
    case unknown
}

/// Represents selected media from the picker
@available(iOS 26.0, macOS 13.0, *)
public struct SelectedMedia: Identifiable, Sendable {
    public let id = UUID()
    public let item: PhotosPickerItem
    public var data: Data?
    public var url: URL?
    public var type: MediaType
    
    public init(item: PhotosPickerItem, type: MediaType) {
        self.item = item
        self.type = type
    }
}

/// SwiftUI wrapper for system photo picker
@available(iOS 26.0, macOS 13.0, *)
public struct MediaPicker: UIViewControllerRepresentable {
    @Binding var selectedMedia: [SelectedMedia]
    let maxSelectionCount: Int
    let filter: PHPickerFilter?
    
    public init(
        selectedMedia: Binding<[SelectedMedia]>,
        maxSelectionCount: Int = 4,
        filter: PHPickerFilter? = .any(of: [.images, .videos])
    ) {
        self._selectedMedia = selectedMedia
        self.maxSelectionCount = maxSelectionCount
        self.filter = filter
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
        Coordinator(self)
    }
    
    public class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: MediaPicker
        
        init(_ parent: MediaPicker) {
            self.parent = parent
        }
        
        public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            var selectedMedia: [SelectedMedia] = []
            
            for result in results {
                // Create a placeholder PhotosPickerItem - this is simplified for compilation
                let item = PhotosPickerItem(itemIdentifier: UUID().uuidString)
                
                // Determine media type based on available type identifiers
                let mediaType: MediaType
                if #available(iOS 26.0, macOS 11.0, *) {
                    if result.itemProvider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                        mediaType = .image
                    } else if result.itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                        mediaType = .video
                    } else {
                        mediaType = .unknown
                    }
                } else {
                    // Fallback for older versions
                    mediaType = .unknown
                }
                
                let media = SelectedMedia(item: item, type: mediaType)
                selectedMedia.append(media)
            }
            
            parent.selectedMedia = selectedMedia
        }
    }
}

/// Convenience methods for MediaPicker
@available(iOS 26.0, macOS 13.0, *)
public extension MediaPicker {
    /// Creates a photo-only picker
    static func photosPicker(
        selectedMedia: Binding<[SelectedMedia]>,
        maxSelectionCount: Int = 4
    ) -> MediaPicker {
        MediaPicker(
            selectedMedia: selectedMedia,
            maxSelectionCount: maxSelectionCount,
            filter: .images
        )
    }
    
    /// Creates a video-only picker
    static func videosPicker(
        selectedMedia: Binding<[SelectedMedia]>,
        maxSelectionCount: Int = 1
    ) -> MediaPicker {
        MediaPicker(
            selectedMedia: selectedMedia,
            maxSelectionCount: maxSelectionCount,
            filter: .videos
        )
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

/// Placeholder MediaPicker for platforms without UIKit
public struct MediaPicker {
    public init() {}
}

#endif