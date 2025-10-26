# Avatar Cropper Requirements Document

## Introduction

The Avatar Cropper feature enables users to select, crop, and optimize photos for use as profile pictures within the Agora social media application. The system provides an intuitive, SwiftUI-first interface that allows users to pan and pinch-to-zoom photos behind a circular mask while ensuring high-quality output and preventing empty space within the crop area.

## Glossary

- **Avatar_Cropper_System**: The complete photo cropping interface and processing pipeline for profile pictures
- **Circular_Mask**: The circular overlay that defines the visible crop area on screen
- **Cover_Scale**: The minimum zoom level that ensures the image completely fills the circular mask
- **Quality_Scale**: The maximum zoom level that maintains acceptable image quality for the output resolution
- **Liquid_Glass_UI**: Apple's translucent, blurred interface elements that provide depth and visual hierarchy
- **Output_Image**: The final square bitmap (e.g., 512×512 pixels) produced by the cropping system
- **Source_Image**: The original photo selected by the user for cropping
- **Display_Thumbnail**: A performance-optimized version of the source image used for real-time interaction

## Zoom & Pan Math (Authoritative)

Screen scale: σ (e.g., 3.0). Source image: pixels (W, H). Mask diameter: Dpt points → Dpx = Dpt × σ pixels. Output: outputSize pixels, qualityMultiplier q (default 1.25).

**Cover (no blank space) minimum:**
```
s_min = max( Dpt / (W / σ),  Dpt / (H / σ) )
```

**Quality-based maximum (visible crop must be ≥ outputSize × q per side):**
Visible side at scale s in image pixels: `visibleSidePx(s) = (Dpt × σ) / s`
Require `visibleSidePx(s) ≥ outputSize × q` ⇒
```
s_quality = (Dpt × σ) / (outputSize × q)
```

**Final zoom range:**
```
s_max = min( s_min × maxZoomMultiplier,  s_quality )
if s_max < s_min → set s_max = s_min and surface a "zoom limited by quality" tip once
```

**Pan clamping (always-valid crop):**
Displayed image size in points at scale s:
```
dispW = (W / σ) × s
dispH = (H / σ) × s
```

Allowed translations (editor centered):
```
tx ∈ [-(dispW - Dpt)/2, +(dispW - Dpt)/2]
ty ∈ [-(dispH - Dpt)/2, +(dispH - Dpt)/2]
```
Apply clamps continuously during gestures (not just on end).

**Minimum pixel density (crispness at min zoom):**
Inside the circle at s_min, per-point pixels = `(Dpx / Dpt) / s_min = σ / s_min`
Require: `σ / s_min ≥ 1.0` (warn/limit if violated)

## Requirements

### Requirement 1

**User Story:** As a user, I want to select a photo and crop it for my profile picture, so that I can customize my appearance on the platform.

#### Acceptance Criteria

1. WHEN a user selects a photo from PhotosPicker, THE Avatar_Cropper_System SHALL display the image in a full-screen cropping interface
2. THE Avatar_Cropper_System SHALL accept source images with minimum dimensions of 320 pixels on the shortest side
3. THE Avatar_Cropper_System SHALL reject images smaller than 320 pixels with a friendly error message
4. THE Avatar_Cropper_System SHALL produce a square Output_Image at exactly 512×512 pixels in sRGB color space
5. THE Avatar_Cropper_System SHALL encode the Output_Image as PNG format for optimal quality

### Requirement 2

**User Story:** As a user, I want to pan and zoom the photo within a circular frame, so that I can position the most important part of the image as my profile picture.

#### Acceptance Criteria

1. WHEN a user performs a drag gesture, THE Avatar_Cropper_System SHALL pan the image within the Circular_Mask boundaries
2. WHEN a user performs a pinch gesture, THE Avatar_Cropper_System SHALL zoom the image between Cover_Scale and Quality_Scale-clamped maximum
3. WHEN a user double-taps the image, THE Avatar_Cropper_System SHALL cycle through zoom levels (1.0×, 1.5×, 2.0×, s_max) anchored at the tap location to preserve focal point
4. THE Avatar_Cropper_System SHALL prevent panning beyond image boundaries at all times during gesture interaction
5. THE Avatar_Cropper_System SHALL clamp zoom levels continuously to prevent quality degradation or empty space exposure

### Requirement 3

**User Story:** As a user, I want the cropping interface to feel native and responsive, so that I have confidence in the quality of my profile picture selection.

#### Acceptance Criteria

1. THE Avatar_Cropper_System SHALL maintain buttery smooth interaction targeting 60 fps during pan and zoom gestures on iPhone 15-17 Pro devices
2. WHEN a user reaches zoom limits, THE Avatar_Cropper_System SHALL provide light haptic feedback using SwiftUI sensory feedback APIs
3. WHEN a user confirms their crop selection, THE Avatar_Cropper_System SHALL provide success haptic feedback
4. THE Avatar_Cropper_System SHALL display Liquid_Glass_UI chrome with translucent top and bottom bars
5. THE Avatar_Cropper_System SHALL complete crop processing within 100-300 milliseconds for 512×512 output

### Requirement 4

**User Story:** As a user with accessibility needs, I want alternative ways to adjust the crop area, so that I can use the feature regardless of my motor abilities.

#### Acceptance Criteria

1. THE Avatar_Cropper_System SHALL announce "Avatar editor. Circular crop. Drag to move, pinch to zoom" to VoiceOver users
2. WHERE accessibility options are enabled, THE Avatar_Cropper_System SHALL provide slider controls for zoom adjustment (0-100%)
3. THE Avatar_Cropper_System SHALL ensure all interactive controls have minimum 44×44 point hit targets
4. THE Avatar_Cropper_System SHALL maintain proper contrast ratios in Liquid_Glass_UI elements
5. THE Avatar_Cropper_System SHALL support VoiceOver navigation through all interface elements

### Requirement 5

**User Story:** As a user, I want the system to prevent poor quality crops, so that my profile picture always looks professional and clear.

#### Acceptance Criteria

1. THE Avatar_Cropper_System SHALL enforce qualityMultiplier (default 1.25×) of output resolution per side within the crop area
2. WHEN image quality would be compromised, THE Avatar_Cropper_System SHALL limit maximum zoom and display a quality warning
3. THE Avatar_Cropper_System SHALL calculate Cover_Scale to ensure no empty space appears within the Circular_Mask
4. THE Avatar_Cropper_System SHALL decode Display_Thumbnail (≈2560–3000 px long edge) for real-time interaction while preserving original quality for final output
5. THE Avatar_Cropper_System SHALL validate that the crop area contains at least (outputSize × qualityMultiplier) pixels per side (e.g., 640×640 for outputSize=512 & qualityMultiplier=1.25) before allowing confirmation

### Requirement 6

**User Story:** As a user, I want visual guidance while cropping, so that I can align my photo optimally within the circular frame.

#### Acceptance Criteria

1. THE Avatar_Cropper_System SHALL display a subtle 2×2 grid within the Circular_Mask for alignment guidance
2. WHEN a user begins gesture interaction, THE Avatar_Cropper_System SHALL hide the grid for visual clarity
3. THE Avatar_Cropper_System SHALL apply 90-94% opacity dimming to areas outside the Circular_Mask
4. THE Avatar_Cropper_System SHALL show instructional text "Pinch to zoom, drag to move" that auto-hides after first gesture
5. THE Avatar_Cropper_System SHALL display a thin white stroke around the Circular_Mask boundary

### Requirement 7

**User Story:** As a user, I want the cropping process to be memory efficient, so that the app remains responsive even with large photos.

#### Acceptance Criteria

1. THE Avatar_Cropper_System SHALL decode source images to Display_Thumbnail resolution for real-time interaction
2. THE Avatar_Cropper_System SHALL retain original image data only for final high-quality crop processing
3. THE Avatar_Cropper_System SHALL perform crop processing on a background task to maintain UI responsiveness
4. IF memory pressure occurs, THE Avatar_Cropper_System SHALL fall back to cropping the Display_Thumbnail with user notification
5. THE Avatar_Cropper_System SHALL release Display_Thumbnail memory immediately after crop completion

### Requirement 8

**User Story:** As a user, I never want to see empty space in the circular crop area, so that my profile picture always looks complete and professional.

#### Acceptance Criteria

1. THE Avatar_Cropper_System SHALL ensure the Circular_Mask displays image content at all times during gesture updates (no blank background)
2. THE Avatar_Cropper_System SHALL clamp zoom to [s_min, s_max] as defined in Zoom & Pan Math
3. THE Avatar_Cropper_System SHALL clamp pan continuously so the mask stays fully covered
4. IF s_max equals s_min, THE Avatar_Cropper_System SHALL show a one-time tip: "Zoom limited by photo quality"
5. THE Avatar_Cropper_System SHALL ensure minimum pixel density of 1.0 px/pt inside the circle at min zoom to avoid softness on @3× displays

### Requirement 9

**User Story:** As a user, I want my cropped avatar to have consistent color and orientation, so that it displays correctly across all devices and platforms.

#### Acceptance Criteria

1. THE Avatar_Cropper_System SHALL normalize EXIF orientation to .up before any math or cropping operations
2. THE Avatar_Cropper_System SHALL convert output to sRGB color space with embedded sRGB ICC profile
3. THE Avatar_Cropper_System SHALL encode output as PNG by default, with optional JPEG(0.9) via configuration
4. THE Avatar_Cropper_System SHALL produce output dimensions of exactly outputSize×outputSize pixels
5. THE Avatar_Cropper_System SHALL output square opaque images (circle is UI mask only, no alpha cropping)

### Requirement 10

**User Story:** As a developer, I want to monitor cropping performance and usage patterns, so that I can optimize the feature and identify issues.

#### Acceptance Criteria

1. THE Avatar_Cropper_System SHALL log source dimensions, thumbnail size, s_min, s_max values, and total crop latency
2. THE Avatar_Cropper_System SHALL log whether quality clamp engaged, output format, and encoding parameters
3. THE Avatar_Cropper_System SHALL never log image data, file paths, or any personally identifiable information
4. THE Avatar_Cropper_System SHALL log only numeric metrics and boolean flags for telemetry
5. THE Avatar_Cropper_System SHALL track upload success rates and retry patterns for reliability monitoring

### Requirement 11

**User Story:** As a user, I want clear feedback when something goes wrong with cropping, so that I can understand and resolve the issue.

#### Acceptance Criteria

1. IF source image min(width,height) < 320 pixels, THE Avatar_Cropper_System SHALL block with friendly error: "This photo is too small for a profile picture"
2. IF cropping fails, THE Avatar_Cropper_System SHALL preserve user state and offer a Retry action
3. IF memory fallback occurs, THE Avatar_Cropper_System SHALL show one-time notice: "Using an optimized preview to finish the crop"
4. THE Avatar_Cropper_System SHALL provide specific error messages for decode failures, processing errors, and upload failures
5. THE Avatar_Cropper_System SHALL maintain crop state during error recovery to avoid user frustration

### Requirement 12

**User Story:** As a user, when I confirm my crop, my new avatar should reliably upload and update everywhere in the app, so that my profile picture changes are immediately visible.

#### Acceptance Criteria

1. THE Avatar_Cropper_System SHALL upload to Supabase Storage avatars bucket using users/{auth.uid()}/avatar_512.png key pattern
2. THE Avatar_Cropper_System SHALL use upsert=true and appropriate contentType (image/png or image/jpeg) for uploads
3. THE Avatar_Cropper_System SHALL update profiles.avatar_path and profiles.avatar_version atomically after successful upload
4. THE Avatar_Cropper_System SHALL include cache-busting version parameter (?v={avatar_version}) in avatar URLs
5. THE Avatar_Cropper_System SHALL retry failed uploads with exponential backoff (0.5s, 1s, 2s; max 3 attempts) and preserve previous avatar on total failure
## 
API Configuration

```swift
public struct AvatarCropperConfig: Sendable, Equatable {
    public var outputSize: Int = 512
    public var qualityMultiplier: CGFloat = 1.25
    public var maxZoomMultiplier: CGFloat = 4.0
    public var maskDiameterFraction: CGFloat = 0.82   // of min(view.width, view.height)
    
    public var showGrid: Bool = true
    public var allowRotation: Bool = false
    public var useLiquidGlassChrome: Bool = true
    
    public var minPixelPerPoint: CGFloat = 1.0        // density gate at s_min
    public var encoding: Encoding = .pngSRGB
    
    public enum Encoding {
        case pngSRGB
        case jpegSRGB(quality: CGFloat)
    }
}
```

## Rendering & Color Management

- **Orientation**: Normalize EXIF to .up before any math/cropping
- **Color space**: Convert to sRGB; embed sRGB ICC profile in output
- **Output encoding**: Default PNG; allow JPEG(0.9) via config
- **Alpha**: Output is square opaque; the circle is a UI mask (no true alpha crop)

## Performance & Memory

- **Display_Thumbnail**: Create with ImageIO thumbnailing (~2560–3000 px long edge) for interactive panning/zooming
- **Final crop**: Use original full-res image to compute crop rect and render output
- **Threading**: Cropping/encoding on a background Task
- **Fallback**: On memory pressure, crop the Display_Thumbnail with a one-time heads-up toast

## Accessibility & Reduce Motion

- **VoiceOver announcement**: "Avatar editor. Circular crop. Drag to move, pinch to zoom"
- **Actions**: Provide Zoom slider (0–100%), and Recenter action
- **Hit targets**: ≥ 44×44 pt for all interactive elements
- **Contrast**: Liquid Glass bars pass WCAG AA standards
- **Reduce Motion**: If enabled, disable springy overscroll; use discrete transitions

## UX Polish

- **Grid**: 2×2 inside the circle; auto-hide during active gesture
- **Instructional copy**: "Pinch to zoom, drag to move" — fade after first gesture (remember per session)
- **Haptics**: SwiftUI sensory feedback
  - Light tick on hitting s_min/s_max or pan clamps
  - Success on Confirm
- **Double-tap zoom**: 1.0× → 1.5× → 2.0× → s_max, anchored at tap location
- **Initial pose**: Start at s_min × 1.05, centered (optionally auto-center on largest face later)