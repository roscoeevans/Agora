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
                let mediaType: MediaType = item.supportedContentTypes.contains(.movie) ? .video : .photo
                
                // Create MediaItem (in a real implementation, you'd upload the data and get URLs)
                let mediaItem = MediaItem(
                    type: mediaType,
                    url: nil, // Would be set after upload
                    thumbnailURL: nil, // Would be generated
                    width: nil, // Would be extracted from image/video
                    height: nil // Would be extracted from image/video
                )
                
                mediaItems.append(mediaItem)
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