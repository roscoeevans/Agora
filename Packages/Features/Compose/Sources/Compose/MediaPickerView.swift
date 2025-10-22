//
//  MediaPickerView.swift
//  Agora
//
//  Created by Agora Team on 2024.
//

import SwiftUI
import PhotosUI
import DesignSystem
import Media

#if canImport(UIKit)
import UIKit
#endif

public struct MediaPickerView: View {
    @State private var selectedItems: [PhotosPickerItem] = []
    let onMediaSelected: ([MediaItem]) -> Void
    
    public init(onMediaSelected: @escaping ([MediaItem]) -> Void) {
        self.onMediaSelected = onMediaSelected
    }
    
    public var body: some View {
        PhotosPicker(
            selection: $selectedItems,
            maxSelectionCount: 4,
            matching: .any(of: [.images, .videos])
        ) {
            HStack(spacing: SpacingTokens.xs) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(TypographyScale.callout)
                
                Text("Select Media")
                    .font(TypographyScale.callout)
            }
            .foregroundColor(ColorTokens.agoraBrand)
            .padding(.vertical, SpacingTokens.sm)
            .padding(.horizontal, SpacingTokens.md)
            .background(ColorTokens.agoraBrand.opacity(0.1))
            .cornerRadius(SpacingTokens.xs)
        }
        .onChange(of: selectedItems) { _, newItems in
            Task {
                await processSelectedItems(newItems)
            }
        }
    }
    
    private func processSelectedItems(_ items: [PhotosPickerItem]) async {
        var mediaItems: [MediaItem] = []
        
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self) {
                // Determine media type based on the item
                let isVideo = item.supportedContentTypes.contains(.movie)
                
                if isVideo {
                    // For videos, we'd need to get the video URL
                    // This is simplified - real implementation would use VideoTransferable
                    let mediaItem = MediaItem(
                        type: .video,
                        videoURL: nil // Would be set after processing
                    )
                    mediaItems.append(mediaItem)
                } else {
                    // For photos, store the image data
                    #if canImport(UIKit)
                    if let uiImage = UIImage(data: data) {
                        let mediaItem = MediaItem(
                            type: .photo,
                            imageData: data,
                            width: Int(uiImage.size.width),
                            height: Int(uiImage.size.height)
                        )
                        mediaItems.append(mediaItem)
                    }
                    #else
                    let mediaItem = MediaItem(
                        type: .photo,
                        imageData: data
                    )
                    mediaItems.append(mediaItem)
                    #endif
                }
            }
        }
        
        await MainActor.run {
            onMediaSelected(mediaItems)
        }
    }
}

#Preview {
    MediaPickerView { items in
        print("Selected \(items.count) media items")
    }
}