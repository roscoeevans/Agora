# Profile Picture Standards for Agora

## Overview

This document defines the comprehensive standards for profile pictures in the Agora app, including technical specifications, user experience guidelines, and implementation details.

## Technical Specifications

### Image Requirements

#### Dimensions & Aspect Ratio
- **Aspect Ratio**: 1:1 (square)
- **Minimum Upload Resolution**: 320 × 320 px
- **Recommended Upload Resolution**: 1080 × 1080 px
- **Maximum Upload Resolution**: No limit (automatically downscaled)
- **Display Size**: 120 × 120 pt (circular crop)

#### File Format & Quality
- **Supported Formats**: JPEG, PNG
- **Compression**: 85% quality for optimal balance
- **File Size Limit**: 2MB maximum
- **Color Space**: sRGB

#### Processing Pipeline
1. **Upload Validation**: Check minimum dimensions, format, and file size
2. **Smart Resize**: 
   - Images > 2048px: Downscale to 1080×1080
   - Images > 1080px: Downscale to 1080×1080  
   - Images ≤ 1080px: Keep original size
3. **Compress**: Apply 85% JPEG compression
4. **Generate Thumbnails**: Create 120×120 and 320×320 versions
5. **Storage**: Store processed image + thumbnails in cloud storage

### Crop Guidelines

#### Circular Display
- Profile pictures are displayed as circles
- Important content should be centered
- Avoid placing key elements in corners
- Maintain 20% safe margin from edges

#### User Experience
- Show circular crop preview during selection
- Allow drag-to-reposition and pinch-to-zoom
- Provide visual feedback for optimal framing
- Support rotation if needed

## Implementation Architecture

### Components

#### 1. ImageCropperView
```swift
struct ImageCropperView: View {
    let image: UIImage
    let onCrop: (UIImage) -> Void
    let onCancel: () -> Void
}
```

#### 2. ImageValidator
```swift
struct ImageValidator {
    static func validate(_ image: UIImage) -> ValidationResult
    static func process(_ image: UIImage) -> ProcessedImage
}
```

#### 3. ProfileImageProcessor
```swift
class ProfileImageProcessor {
    func processForProfile(_ image: UIImage) async throws -> ProcessedProfileImage
    func generateThumbnails(_ image: UIImage) async -> [ThumbnailSize: UIImage]
}
```

### Data Models

#### ProcessedProfileImage
```swift
struct ProcessedProfileImage {
    let original: Data
    let thumbnail120: Data
    let thumbnail320: Data
    let metadata: ImageMetadata
}

struct ImageMetadata {
    let originalSize: CGSize
    let processedSize: CGSize
    let fileSize: Int
    let format: ImageFormat
    let quality: Double
}
```

## User Experience Flow

### 1. Image Selection
- User taps "Change Photo" button
- Native photo picker opens
- User selects image from library or camera

### 2. Image Validation
- Check if image meets minimum requirements
- Show error if image is too small or invalid format
- Proceed to cropping if valid

### 3. Cropping Interface
- Display selected image with circular overlay
- Allow drag to reposition
- Allow pinch to zoom
- Show preview of final circular result
- "Crop" and "Cancel" buttons

### 4. Processing & Upload
- Process image according to standards
- Generate thumbnails
- Upload to storage
- Update profile with new image URL

## Error Handling

### Validation Errors
- "Image too small. Please select an image at least 320×320 pixels."
- "Unsupported format. Please select a JPEG or PNG image."
- "File too large. Please select an image smaller than 2MB."

### Processing Errors
- "Failed to process image. Please try again."
- "Upload failed. Please check your connection and try again."

## Accessibility

### VoiceOver Support
- "Profile picture, double tap to change"
- "Image cropper, drag to reposition, pinch to zoom"
- "Crop button, double tap to apply changes"

### Visual Indicators
- High contrast crop overlay
- Clear button labels
- Loading states during processing

## Performance Considerations

### Memory Management
- Process images on background queue
- Release large images after processing
- Use efficient image rendering

### Caching
- Cache processed thumbnails
- Lazy load profile images
- Implement proper cache invalidation

## Testing Requirements

### Unit Tests
- Image validation logic
- Processing pipeline
- Error handling

### UI Tests
- Complete selection flow
- Cropping interface
- Error states

### Manual Testing
- Various image sizes and formats
- Different device orientations
- Network failure scenarios
- Accessibility with VoiceOver

## Future Enhancements

### Advanced Features
- AI-powered face detection for auto-cropping
- Multiple crop aspect ratios
- Basic filters and adjustments
- Batch processing for multiple images

### Analytics
- Track image processing performance
- Monitor error rates
- User engagement metrics

## Implementation Checklist

- [ ] Create ImageCropperView component
- [ ] Implement ImageValidator
- [ ] Build ProfileImageProcessor
- [ ] Update EditProfileView integration
- [ ] Add comprehensive error handling
- [ ] Implement accessibility features
- [ ] Create unit and UI tests
- [ ] Performance optimization
- [ ] Documentation and code comments

## References

- [Apple Human Interface Guidelines - Images](https://developer.apple.com/design/human-interface-guidelines/images)
- [Instagram Profile Picture Guidelines](https://help.instagram.com/1631821640426723)
- [iOS Image Processing Best Practices](https://developer.apple.com/documentation/coregraphics)
