# Avatar Cropper Design Document

## Overview

The Avatar Cropper is a SwiftUI-first photo cropping system that enables users to create high-quality profile pictures through an intuitive pan-and-zoom interface. The system enforces mathematical constraints to prevent empty space within the circular crop area while maintaining optimal image quality and performance.

The design follows a layered architecture with clear separation between UI presentation, gesture handling, mathematical constraints, and image processing. All components are built using SwiftUI and Swift Concurrency, avoiding UIKit dependencies where possible.

## Architecture

### Module Organization

```
Features/Profile (AvatarPickerScreen)
    ↓
┌─────────────────────────────────────────────────────────────┐
│                 DesignSystem/ImageEditing                   │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐ │
│  │  AvatarCropper  │  │   Liquid Glass  │  │   Gesture   │ │
│  │      View       │  │     Chrome      │  │   Handling  │ │
│  └─────────────────┘  └─────────────────┘  └─────────────┘ │
└─────────────────────────────────────────────────────────────┘
    ↓                           ↓                           ↓
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│   Media Kit     │  │ AppFoundation   │  │  SupabaseKit    │
│ ┌─────────────┐ │  │ ┌─────────────┐ │  │ ┌─────────────┐ │
│ │CropGeometry │ │  │ │ Protocols & │ │  │ │   Avatar    │ │
│ │ImageCrop    │ │  │ │Dependencies │ │  │ │   Upload    │ │
│ │Renderer     │ │  │ │             │ │  │ │  Service    │ │
│ └─────────────┘ │  │ └─────────────┘ │  │ └─────────────┘ │
└─────────────────┘  └─────────────────┘  └─────────────────┘
```

### Data Flow

1. **Input**: User selects photo from PhotosPicker in Profile feature
2. **UI Presentation**: AvatarCropperView (DesignSystem) handles interactive editing
3. **Math & Validation**: CropGeometry (Media) provides constraint calculations
4. **Final Processing**: ImageCropRenderer (Media) produces final bitmap
5. **Upload**: AvatarUploadService (SupabaseKit) handles storage and versioning
6. **Profile Update**: Profile feature updates user profile with new avatar URL

### Dependency Graph

```
Features/Profile
  ↳ DesignSystem (AvatarCropperView, AvatarCropperConfig)
  ↳ Media (CropGeometry, ImageCropRenderer via protocol)
  ↳ SupabaseKit (AvatarUploadService)
  ↳ AppFoundation (protocols, DI)
```

## Components and Interfaces

### AppFoundation Protocols

```swift
// Packages/Shared/AppFoundation/ServiceProtocols.swift
public protocol AvatarUploadService {
    func uploadAvatar(_ data: Data, mime: String) async throws -> URL
}

public protocol ImageCropRendering {
    /// Renders a square output (e.g., 512×512) from a source CGImage and transform
    func renderSquareAvatar(
        source: CGImage,
        cropRectInPixels: CGRect,
        outputSize: Int,
        colorSpace: CGColorSpace
    ) throws -> Data
}
```

### DesignSystem - AvatarCropperView

```swift
// Packages/Kits/DesignSystem/Sources/DesignSystem/ImageEditing/AvatarCropper/AvatarCropperView.swift
public struct AvatarCropperView: View {
    public let sourceImage: CGImage
    public let config: AvatarCropperConfig
    public let onCancel: () -> Void
    public let onConfirm: (_ cropRectInPixels: CGRect) -> Void
    
    @StateObject private var cropState = CropState()
    @State private var processingState = ProcessingState.idle
    
    public init(
        sourceImage: CGImage,
        config: AvatarCropperConfig = .default,
        onCancel: @escaping () -> Void,
        onConfirm: @escaping (CGRect) -> Void
    ) {
        self.sourceImage = sourceImage
        self.config = config
        self.onCancel = onCancel
        self.onConfirm = onConfirm
    }
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background dimming
                Color.black.opacity(0.92)
                    .ignoresSafeArea()
                
                // Main crop interface
                cropCanvas(in: geometry)
                    .overlay(alignment: .top) {
                        liquidGlassTopBar()
                    }
                    .overlay(alignment: .bottom) {
                        liquidGlassBottomBar()
                    }
            }
        }
        .onAppear {
            setupInitialState()
        }
    }
}

public struct AvatarCropperConfig: Equatable, Sendable {
    public var outputSize: Int = 512
    public var qualityMultiplier: CGFloat = 1.25
    public var maxZoomMultiplier: CGFloat = 4.0
    public var maskDiameterFraction: CGFloat = 0.82
    public var showGrid: Bool = true
    public var useLiquidGlassChrome: Bool = true
    
    public init() {}
    
    public static let `default` = AvatarCropperConfig()
}
```

### Media Kit - CropGeometry

```swift
// Packages/Kits/Media/Sources/Media/CropGeometry.swift
public struct CropGeometry {
    public static func zoomRange(
        maskDiameterPoints Dpt: CGFloat,
        screenScale sigma: CGFloat,
        sourceSize: CGSize, // pixels (W,H)
        outputSize: Int,
        qualityMultiplier q: CGFloat,
        maxZoomMultiplier: CGFloat
    ) -> (min: CGFloat, max: CGFloat, qualityLimited: Bool) {
        // Cover scale (no blank space)
        let sCover = max(
            Dpt / (sourceSize.width / sigma),
            Dpt / (sourceSize.height / sigma)
        )
        
        // Quality scale (maintain resolution)
        let sQuality = (Dpt * sigma) / (CGFloat(outputSize) * q)
        
        // Check if quality limits zoom before maxZoomMultiplier
        var sMax = min(sCover * maxZoomMultiplier, sQuality)
        let qualityLimited = sQuality <= sCover * maxZoomMultiplier
        
        // Ensure sMax >= sCover
        if sMax < sCover { sMax = sCover }
        
        return (sCover, sMax, qualityLimited)
    }
    
    public static func clampedTranslation(
        scale s: CGFloat,
        Dpt: CGFloat,
        sigma: CGFloat,
        sourceSize: CGSize,
        proposed: CGSize
    ) -> CGSize {
        let dispW = (sourceSize.width / sigma) * s
        let dispH = (sourceSize.height / sigma) * s
        let maxX = max(0, (dispW - Dpt) / 2)
        let maxY = max(0, (dispH - Dpt) / 2)
        
        return CGSize(
            width: min(max(proposed.width, -maxX), +maxX),
            height: min(max(proposed.height, -maxY), +maxY)
        )
    }
    
    public static func cropRectInImagePixels(
        scale s: CGFloat,
        translation: CGSize, // points, relative to center
        Dpt: CGFloat,        // mask diameter in points
        sigma: CGFloat,      // screen scale
        sourceSize: CGSize   // pixels (W,H)
    ) -> CGRect {
        let Dpx = Dpt * sigma
        
        // Image center in image pixel coords before translation
        let cx0 = sourceSize.width / 2
        let cy0 = sourceSize.height / 2
        
        // Translation is applied in points; convert to image pixels at current zoom.
        // Positive translation means image moved right/down => visible center moves left/up.
        let pxPerPoint = sigma / s
        let cx = cx0 - translation.width * pxPerPoint
        let cy = cy0 - translation.height * pxPerPoint
        
        let sidePx = Dpx / s
        var rect = CGRect(
            x: cx - sidePx / 2,
            y: cy - sidePx / 2,
            width: sidePx,
            height: sidePx
        ).integral
        
        // Clamp inside source (avoid nil cropping() and edge artifacts)
        rect.origin.x = max(0, min(rect.origin.x, sourceSize.width - rect.width))
        rect.origin.y = max(0, min(rect.origin.y, sourceSize.height - rect.height))
        
        return rect
    }
}
```

### Media Kit - ImageCropRenderer

```swift
// Packages/Kits/Media/Sources/Media/ImageCropRenderer.swift
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

public struct ImageCropRenderer: ImageCropRendering, Sendable {
    public init() {}
    
    public func renderSquareAvatar(
        source: CGImage,
        cropRectInPixels: CGRect,
        outputSize: Int,
        colorSpace: CGColorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
    ) throws -> Data {
        // Safe clamp to source bounds
        let srcRect = CGRect(x: 0, y: 0, width: source.width, height: source.height)
        let rect = cropRectInPixels.intersection(srcRect).integral
        guard rect.width > 0, rect.height > 0 else {
            throw CropValidationError.cropProcessingFailed
        }
        
        // Crop to exact rect
        guard let cropped = source.cropping(to: rect) else {
            throw CropValidationError.cropProcessingFailed
        }
        
        // Create opaque square output context (we mask in UI, not in pixels)
        guard let ctx = CGContext(
            data: nil,
            width: outputSize,
            height: outputSize,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw CropValidationError.cropProcessingFailed
        }
        
        ctx.interpolationQuality = .high
        ctx.draw(cropped, in: CGRect(x: 0, y: 0, width: outputSize, height: outputSize))
        
        guard let finalImage = ctx.makeImage() else {
            throw CropValidationError.cropProcessingFailed
        }
        
        // Encode as PNG with embedded sRGB profile
        let data = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(
            data, UTType.png.identifier as CFString, 1, nil
        ) else {
            throw CropValidationError.cropProcessingFailed
        }
        
        // Embed sRGB profile
        let props: [CFString: Any] = [
            kCGImagePropertyColorModel: kCGImagePropertyColorModelRGB,
            kCGImagePropertyProfileName: "sRGB IEC61966-2.1"
        ]
        CGImageDestinationAddImage(dest, finalImage, props as CFDictionary)
        
        guard CGImageDestinationFinalize(dest) else {
            throw CropValidationError.cropProcessingFailed
        }
        
        return data as Data
    }
}

// MARK: - Thumbnail Generation
public func makeDisplayThumbnail(from data: Data, longEdge: CGFloat = 2560) -> CGImage? {
    guard let src = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
    let opts: [CFString: Any] = [
        kCGImageSourceCreateThumbnailFromImageIfAbsent: true,
        kCGImageSourceCreateThumbnailWithTransform: true, // honors EXIF orientation
        kCGImageSourceThumbnailMaxPixelSize: Int(longEdge)
    ]
    return CGImageSourceCreateThumbnailAtIndex(src, 0, opts as CFDictionary)
}
```

### SupabaseKit - AvatarUploadService

```swift
// Packages/Kits/SupabaseKit/Sources/SupabaseKit/AvatarUploadServiceLive.swift
public struct AvatarUploadServiceLive: AvatarUploadService, Sendable {
    private let client: SupabaseClient
    
    public init(client: SupabaseClient) {
        self.client = client
    }
    
    public func uploadAvatar(_ data: Data, mime: String) async throws -> URL {
        // Get current user ID
        guard let user = try await client.auth.user() else {
            throw AvatarUploadError.notAuthenticated
        }
        
        let userId = user.id.uuidString
        let fileExtension = mime == "image/png" ? "png" : "jpg"
        let fileName = "avatar_512.\(fileExtension)"
        let filePath = "users/\(userId)/\(fileName)"
        
        // Retryable operation with exponential backoff
        return try await withRetry(maxAttempts: 3) {
            // Upload with upsert and cache control
            _ = try await client.storage
                .from("avatars")
                .upload(
                    path: filePath,
                    file: data,
                    options: FileOptions(
                        cacheControl: "31536000", // 1 year
                        contentType: mime,
                        upsert: true
                    )
                )
            
            // Get public URL
            let publicURL = try client.storage
                .from("avatars")
                .getPublicURL(path: filePath)
            
            // Update profile with new avatar path and server-side timestamp for versioning
            let updateResponse = try await client.database
                .from("profiles")
                .update([
                    "avatar_path": filePath,
                    "updated_at": "now()" // Server-side timestamp for deterministic versioning
                ])
                .eq("id", value: userId)
                .select("updated_at")
                .single()
                .execute()
            
            // Extract timestamp for cache busting
            let updatedAt = updateResponse.data["updated_at"] as? String ?? String(Int(Date().timeIntervalSince1970))
            let versionHash = String(updatedAt.hash)
            
            // Return versioned URL for cache busting
            var components = URLComponents(url: publicURL, resolvingAgainstBaseURL: false)
            components?.queryItems = [URLQueryItem(name: "v", value: versionHash)]
            
            return components?.url ?? publicURL
        }
    }
    
    private func withRetry<T>(
        maxAttempts: Int,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        
        for attempt in 1...maxAttempts {
            do {
                return try await operation()
            } catch {
                lastError = error
                if attempt < maxAttempts {
                    let delay = pow(2.0, Double(attempt - 1)) * 0.5 // 0.5s, 1s, 2s
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? AvatarUploadError.uploadFailed(NSError(domain: "Unknown", code: -1))
    }
}

public enum AvatarUploadError: LocalizedError, Sendable {
    case notAuthenticated
    case uploadFailed(Error)
    case profileUpdateFailed(Error)
    
    public var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please sign in to update your avatar."
        case .uploadFailed:
            return "Failed to upload avatar. Please try again."
        case .profileUpdateFailed:
            return "Avatar uploaded but profile update failed. Please try again."
        }
    }
}
```

### Profile Feature Integration

```swift
// Packages/Features/Profile/Sources/Profile/AvatarPickerScreen.swift
import PhotosUI
import DesignSystem

struct AvatarPickerScreen: View {
    @Environment(\.deps) private var deps
    @State private var photoSelection: PhotosPickerItem?
    @State private var pickedImageData: Data?
    @State private var displayThumbnail: CGImage?
    @State private var originalImage: CGImage?
    @State private var isPresentingCropper = false
    @State private var isUploading = false
    @State private var error: String?
    @State private var qualityLimitedShown = false
    
    var body: some View {
        VStack {
            PhotosPicker(
                selection: $photoSelection,
                matching: .images,
                photoLibrary: .shared()
            ) {
                Text("Choose Photo")
            }
            .onChange(of: photoSelection) { selection in
                Task {
                    await loadSelectedPhoto(selection)
                }
            }
        }
        .fullScreenCover(isPresented: $isPresentingCropper) {
            if let thumbnail = displayThumbnail {
                AvatarCropperView(
                    sourceImage: thumbnail,
                    config: .default,
                    onCancel: {
                        isPresentingCropper = false
                        cleanup()
                    },
                    onConfirm: { cropRect in
                        Task {
                            await processCroppedAvatar(cropRect: cropRect)
                        }
                    }
                )
                .sensoryFeedback(.success, trigger: isUploading) // Success haptic on upload complete
            }
        }
        .overlay {
            if isUploading {
                VStack {
                    ProgressView()
                    Text("Uploading...")
                        .font(.caption)
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .alert("Error", isPresented: .constant(error != nil)) {
            Button("OK") { error = nil }
        } message: {
            if let error = error {
                Text(error)
            }
        }
    }
    
    private func loadSelectedPhoto(_ selection: PhotosPickerItem?) async {
        guard let selection = selection else { return }
        
        do {
            guard let data = try await selection.loadTransferable(type: Data.self) else {
                throw CropValidationError.imageDecodingFailed
            }
            
            // Validate minimum size
            guard let source = CGImageSourceCreateWithData(data as CFData, nil),
                  let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
                  let width = properties[kCGImagePropertyPixelWidth] as? Int,
                  let height = properties[kCGImagePropertyPixelHeight] as? Int else {
                throw CropValidationError.imageDecodingFailed
            }
            
            let minDimension = min(width, height)
            guard minDimension >= 320 else {
                throw CropValidationError.imageTooSmall(
                    size: CGSize(width: width, height: height),
                    minimum: 320
                )
            }
            
            // Generate display thumbnail with EXIF orientation handling
            guard let thumbnail = makeDisplayThumbnail(from: data, longEdge: 2560) else {
                throw CropValidationError.imageDecodingFailed
            }
            
            // Keep original for final crop
            guard let original = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
                throw CropValidationError.imageDecodingFailed
            }
            
            await MainActor.run {
                self.pickedImageData = data
                self.displayThumbnail = thumbnail
                self.originalImage = original
                self.isPresentingCropper = true
            }
            
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
            }
        }
    }
    
    private func processCroppedAvatar(cropRect: CGRect) async {
        guard let original = originalImage else { return }
        
        await MainActor.run {
            isUploading = true
        }
        
        defer {
            Task { @MainActor in
                isUploading = false
                isPresentingCropper = false
                cleanup()
            }
        }
        
        do {
            // Render final crop using original image for best quality
            let cropData = try deps.imageCropRendering.renderSquareAvatar(
                source: original,
                cropRectInPixels: cropRect,
                outputSize: 512,
                colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!
            )
            
            // Upload using SupabaseKit with retry logic
            let avatarURL = try await deps.avatarUploadService.uploadAvatar(
                cropData,
                mime: "image/png"
            )
            
            // Log telemetry (non-PII)
            logCropTelemetry(
                sourceSize: CGSize(width: original.width, height: original.height),
                cropRect: cropRect,
                outputSize: 512
            )
            
            // Trigger profile refresh with new avatar URL
            // NotificationCenter or other mechanism to update profile state
            
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
            }
        }
    }
    
    private func cleanup() {
        pickedImageData = nil
        displayThumbnail = nil
        originalImage = nil
        qualityLimitedShown = false
    }
    
    private func logCropTelemetry(sourceSize: CGSize, cropRect: CGRect, outputSize: Int) {
        // Log non-PII metrics for monitoring
        let telemetry = [
            "source_width": sourceSize.width,
            "source_height": sourceSize.height,
            "crop_side_px": cropRect.width,
            "output_size": outputSize,
            "aspect_ratio": sourceSize.width / sourceSize.height
        ]
        // Send to analytics service
    }
}
```

## Data Models

### Configuration Model

```swift
public struct AvatarCropperConfig: Sendable, Equatable {
    public var outputSize: Int = 512
    public var qualityMultiplier: CGFloat = 1.25
    public var maxZoomMultiplier: CGFloat = 4.0
    public var maskDiameterFraction: CGFloat = 0.82
    
    public var showGrid: Bool = true
    public var allowRotation: Bool = false
    public var useLiquidGlassChrome: Bool = true
    
    public var minPixelPerPoint: CGFloat = 1.0
    public var encoding: Encoding = .pngSRGB
    
    public enum Encoding: Sendable, Equatable {
        case pngSRGB
        case jpegSRGB(quality: CGFloat)
    }
    
    public static let `default` = AvatarCropperConfig()
}
```

### Constraint Model

```swift
struct CropConstraints {
    let minScale: CGFloat
    let maxScale: CGFloat
    let maskDiameter: CGFloat
    let panBoundsCalculator: (CGFloat) -> CGRect
    let qualityLimited: Bool
}
```

### Processing State

```swift
enum ProcessingState: Equatable {
    case idle
    case processing
    case uploading(progress: Double)
    case completed
    case failed(Error)
    
    static func == (lhs: ProcessingState, rhs: ProcessingState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.processing, .processing), (.completed, .completed):
            return true
        case (.uploading(let lProgress), .uploading(let rProgress)):
            return lProgress == rProgress
        case (.failed, .failed):
            return true
        default:
            return false
        }
    }
}
```

## Error Handling

### Validation Pipeline

```swift
enum CropValidationError: LocalizedError {
    case imageTooSmall(size: CGSize, minimum: CGFloat)
    case imageDecodingFailed
    case cropProcessingFailed
    case uploadFailed(underlying: Error)
    case memoryPressure
    
    var errorDescription: String? {
        switch self {
        case .imageTooSmall:
            return "This photo is too small for a profile picture."
        case .imageDecodingFailed:
            return "Unable to process this image. Please try a different photo."
        case .cropProcessingFailed:
            return "Failed to crop image. Please try again."
        case .uploadFailed:
            return "Upload failed. Please check your connection and try again."
        case .memoryPressure:
            return "Using an optimized preview to finish the crop."
        }
    }
}

func validateSourceImage(_ image: UIImage) throws {
    let minDimension = min(image.size.width, image.size.height)
    guard minDimension >= 320 else {
        throw CropValidationError.imageTooSmall(
            size: image.size,
            minimum: 320
        )
    }
}
```

### Error Recovery

```swift
@MainActor
final class ErrorRecoveryManager: ObservableObject {
    @Published var currentError: CropValidationError?
    @Published var showRetryOption: Bool = false
    
    func handleError(_ error: CropValidationError) {
        currentError = error
        
        switch error {
        case .cropProcessingFailed, .uploadFailed:
            showRetryOption = true
        case .memoryPressure:
            // Show one-time notice, continue with fallback
            showMemoryFallbackNotice()
        default:
            showRetryOption = false
        }
    }
    
    private func showMemoryFallbackNotice() {
        // Implementation for one-time memory fallback notice
    }
}
```

## Testing Strategy

### Media Kit Tests
**Location**: `Packages/Kits/Media/Tests/MediaTests/`

1. **CropGeometry Tests**
   - Property-based tests for no blank space invariant across random (W,H) and random mask sizes
   - Verify zoomRange math for various image aspect ratios (very wide, very tall, square)
   - Test cropRectInImagePixels correctness by round-trip validation
   - Edge case testing: minimum source sizes, extreme zoom levels

2. **ImageCropRenderer Tests**
   - Test crop rect accuracy with known input/output pairs
   - Validate EXIF orientation normalization
   - Verify sRGB color space conversion and ICC profile embedding
   - Performance tests for crop processing time requirements

### DesignSystem Tests
**Location**: `Packages/Kits/DesignSystem/Tests/DesignSystemTests/`

1. **AvatarCropperView Tests**
   - UI snapshot tests for editor chrome (grid on/off, Liquid Glass bars)
   - Interaction tests: clamping behaviors during gestures
   - Accessibility tests: VoiceOver announcements, alternative controls
   - Reduce motion compliance testing

2. **Gesture Validation Tests**
   - Test simultaneous pan and zoom constraint enforcement
   - Validate haptic feedback triggers at boundaries
   - Double-tap zoom focal point preservation

### SupabaseKit Tests
**Location**: `Packages/Kits/SupabaseKit/Tests/SupabaseKitTests/`

1. **AvatarUploadService Tests**
   - Mock client testing for correct bucket path, contentType, cache headers
   - Test upsert behavior and error propagation
   - Validate retry logic with exponential backoff
   - Profile update atomicity testing

### Integration Tests
**Location**: `Tests/` (top-level cross-module)

1. **End-to-End Flow Tests**
   - PhotosPicker → AvatarCropperView → crop → render (mock) → upload (mock) → profile updated
   - Memory pressure fallback scenarios
   - Error recovery and state preservation

## Module File Structure

### DesignSystem Package
```
Packages/Kits/DesignSystem/Sources/DesignSystem/ImageEditing/AvatarCropper/
├── AvatarCropperView.swift          // Main SwiftUI view
├── AvatarCropperConfig.swift        // Configuration model
├── CropState.swift                  // Internal state management
└── LiquidGlassChrome.swift          // Top/bottom bar components
```

### Media Package
```
Packages/Kits/Media/Sources/Media/
├── CropGeometry.swift               // Mathematical constraint calculations
└── ImageCropRenderer.swift          // Final image processing and encoding
```

### SupabaseKit Package
```
Packages/Kits/SupabaseKit/Sources/SupabaseKit/
└── AvatarUploadServiceLive.swift    // Upload service implementation
```

### AppFoundation Package
```
Packages/Shared/AppFoundation/Sources/AppFoundation/
├── ServiceProtocols.swift           // Protocol definitions
└── Dependencies.swift               // DI container updates
```

### Profile Feature
```
Packages/Features/Profile/Sources/Profile/
└── AvatarPickerScreen.swift         // Integration screen
```

## Performance Optimizations

### Memory Management Strategy
- **Display Thumbnail**: Generate 2560-3000px thumbnail using ImageIO for smooth interaction
- **Original Preservation**: Keep original CGImage reference for final high-quality crop
- **Background Processing**: All crop rendering happens on background queues
- **Memory Pressure**: Fallback to thumbnail-based cropping with user notification

### Rendering Pipeline
- **EXIF Normalization**: Handle orientation before any mathematical calculations
- **sRGB Conversion**: Ensure consistent color space across devices
- **Efficient Cropping**: Use CGImage.cropping(to:) for pixel-perfect crops
- **PNG Encoding**: Default to PNG for sharp edges, optional JPEG for smaller files

This design maintains strict module boundaries while providing a cohesive user experience. The mathematical foundation ensures pixel-perfect crops, while the modular architecture supports testing and future enhancements.