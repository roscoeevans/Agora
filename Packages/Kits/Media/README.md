# Media Kit

The Media kit provides photo/video capture, processing, and upload functionality for the Agora iOS app.

## Overview

This module handles:
- System photo picker integration
- Image and video compression
- Media upload to Cloudflare
- Thumbnail generation
- Progress tracking

## Components

### MediaPicker
**Note:** MediaPicker has been moved to `UIKitBridge` package for better organization.
Use `UIKitBridge.MediaPickerBridge` instead.

```swift
import UIKitBridge

@State private var selectedMedia: [SelectedMedia] = []

var body: some View {
    MediaPickerBridge(selectedMedia: $selectedMedia, maxSelectionCount: 4)
}

// Convenience methods
MediaPickerBridge.photosPicker(selectedMedia: $selectedMedia)
MediaPickerBridge.videosPicker(selectedMedia: $selectedMedia, maxSelectionCount: 1)
```

### MediaProcessor
Handles image and video compression and processing.

```swift
let processor = MediaProcessor.shared

// Process image
let processedImage = try await processor.processImage(data: imageData)

// Process video
let processedVideo = try await processor.processVideo(url: videoURL)

// Generate thumbnail
let thumbnail = try await processor.generateVideoThumbnail(url: videoURL)
```

### UploadManager
Manages media uploads to Cloudflare with progress tracking.

```swift
let uploadManager = UploadManager.shared

// Upload processed media
let result = try await uploadManager.uploadProcessedMedia(processedMedia) { progress in
    print("Upload progress: \(progress.percentage * 100)%")
}

// Upload raw data
let result = try await uploadManager.uploadMedia(
    data: mediaData,
    type: .image,
    mimeType: "image/jpeg"
)
```

## Dependencies

- PhotosUI (iOS 26+)
- AVFoundation
- UIKit
- Networking (internal dependency)

## Usage

Import the module in your Swift files:

```swift
import Media
```

## Architecture

The Media kit is designed to be:
- Async/await compatible for modern Swift concurrency
- Memory efficient with streaming uploads
- Progress-aware for user feedback
- Type-safe with proper error handling
- Configurable for different use cases

## Configuration

### MediaProcessingConfig
Configure image and video processing parameters:

```swift
let config = MediaProcessingConfig(
    maxImageSize: CGSize(width: 1920, height: 1920),
    imageCompressionQuality: 0.8,
    maxVideoSize: CGSize(width: 1920, height: 1080),
    videoCompressionPreset: AVAssetExportPresetMediumQuality
)
```

### UploadConfig
Configure upload parameters:

```swift
let config = UploadConfig(
    maxFileSize: 100 * 1024 * 1024, // 100MB
    allowedMimeTypes: ["image/jpeg", "image/png", "video/mp4"],
    chunkSize: 1024 * 1024 // 1MB chunks
)
```

## Testing

Run tests using:

```bash
swift test --package-path Packages/Kits/Media
```

## Error Handling

The module provides comprehensive error handling:

- `MediaProcessingError` for processing failures
- `UploadError` for upload failures
- Proper error propagation with descriptive messages