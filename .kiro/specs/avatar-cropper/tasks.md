# Avatar Cropper Implementation Plan

- [ ] 1. Set up foundational protocols and dependencies
  - Create protocol definitions in AppFoundation/ServiceProtocols.swift
  - Add ImageCropRendering and AvatarUploadService protocol signatures
  - Update Dependencies.swift with new service registrations
  - _Requirements: 1.1, 1.4, 12.1_

- [ ] 2. Implement core mathematical engine in Media kit
  - [ ] 2.1 Create CropGeometry.swift with constraint calculations
    - Implement zoomRange function with quality-limited flag
    - Implement clampedTranslation for pan bounds
    - Implement cropRectInImagePixels with coordinate system precision
    - _Requirements: 2.2, 2.5, 5.1, 8.2, 8.3_
  
  - [ ] 2.2 Create ImageCropRenderer.swift for final processing
    - Implement renderSquareAvatar with sRGB color management
    - Add EXIF orientation normalization
    - Implement safe rect clamping and error handling
    - Add makeDisplayThumbnail function with ImageIO
    - _Requirements: 1.4, 1.5, 9.1, 9.2, 9.3, 9.4_
  
  - [ ] 2.3 Write comprehensive tests for mathematical invariants
    - Property-based tests for no blank space guarantee
    - Edge case testing for extreme aspect ratios
    - Crop rect accuracy validation with round-trip testing
    - _Requirements: 8.1, 8.2, 8.3_

- [ ] 3. Build SwiftUI cropper interface in DesignSystem
  - [ ] 3.1 Create AvatarCropperConfig.swift configuration model
    - Define all configuration parameters with sensible defaults
    - Implement Sendable and Equatable conformance
    - _Requirements: 1.1, 5.1, 5.2_
  
  - [ ] 3.2 Create CropState.swift for internal state management
    - Implement ObservableObject with published properties
    - Add gesture tracking and UI state management
    - _Requirements: 2.1, 2.2, 6.1, 6.2_
  
  - [ ] 3.3 Implement AvatarCropperView.swift main interface
    - Create SwiftUI view with GeometryReader and ZStack layout
    - Implement circular mask with proper dimming overlay
    - Add Liquid Glass chrome with top and bottom bars
    - _Requirements: 3.4, 6.3, 6.4, 6.5_
  
  - [ ] 3.4 Add gesture handling system
    - Implement simultaneous MagnificationGesture and DragGesture
    - Add continuous constraint validation using CropGeometry
    - Implement double-tap zoom with focal point preservation
    - Add SwiftUI sensory feedback for boundary hits
    - _Requirements: 2.1, 2.2, 2.3, 3.2, 3.3_
  
  - [ ] 3.5 Implement accessibility features
    - Add VoiceOver announcements and labels
    - Create alternative zoom slider controls
    - Ensure 44pt minimum hit targets
    - Add reduce motion support
    - _Requirements: 4.1, 4.2, 4.3, 4.4_
  
  - [ ] 3.6 Create UI snapshot tests and interaction tests
    - Test Liquid Glass chrome appearance
    - Validate grid overlay positioning
    - Test gesture constraint enforcement
    - _Requirements: 3.1, 6.1, 6.2_

- [ ] 4. Implement Supabase upload service
  - [ ] 4.1 Create AvatarUploadServiceLive.swift
    - Implement upload with proper contentType and cache control
    - Add exponential backoff retry logic (0.5s, 1s, 2s)
    - Implement atomic profile update with server-side versioning
    - Add comprehensive error handling and recovery
    - _Requirements: 12.1, 12.2, 12.3, 12.4, 12.5_
  
  - [ ] 4.2 Write upload service tests
    - Mock client testing for correct parameters
    - Test retry logic and error propagation
    - Validate profile update atomicity
    - _Requirements: 12.1, 12.2, 12.5_

- [ ] 5. Create Profile feature integration
  - [ ] 5.1 Implement AvatarPickerScreen.swift
    - Add PhotosPicker integration with proper data loading
    - Implement image validation and thumbnail generation
    - Create full-screen cropper presentation
    - Add upload progress indication with Liquid Glass styling
    - _Requirements: 1.1, 1.2, 1.3, 7.1, 7.2_
  
  - [ ] 5.2 Add error handling and user feedback
    - Implement validation error messages
    - Add retry mechanisms for failed operations
    - Create memory fallback notifications
    - Add telemetry logging for performance monitoring
    - _Requirements: 11.1, 11.2, 11.3, 11.4, 10.1, 10.2, 10.3_
  
  - [ ] 5.3 Write integration tests
    - End-to-end flow testing with mocked services
    - Memory pressure scenario testing
    - Error recovery validation
    - _Requirements: 7.3, 7.4, 11.5_

- [ ] 6. Performance optimization and validation
  - [ ] 6.1 Implement memory management optimizations
    - Add proper cleanup of display thumbnails
    - Implement background processing for crop operations
    - Add memory pressure monitoring and fallback
    - _Requirements: 3.1, 7.1, 7.2, 7.3, 7.4_
  
  - [ ] 6.2 Add performance monitoring and telemetry
    - Implement non-PII metrics collection
    - Add crop processing time measurement
    - Create upload success rate tracking
    - _Requirements: 10.1, 10.2, 10.3, 10.4_
  
  - [ ]* 6.3 Conduct performance testing
    - Validate 60fps during gestures on target devices
    - Test crop processing time requirements (100-300ms)
    - Memory usage testing with large source images
    - _Requirements: 3.1, 3.5_

- [ ] 7. Final integration and polish
  - [ ] 7.1 Wire up dependency injection
    - Register all services in Dependencies.swift
    - Create mock implementations for testing
    - Add environment value extensions for SwiftUI
    - _Requirements: 1.1, 12.1_
  
  - [ ] 7.2 Add comprehensive error validation
    - Implement all CropValidationError cases
    - Add user-friendly error messages
    - Create error recovery workflows
    - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5_
  
  - [ ] 7.3 Implement quality assurance features
    - Add quality-limited zoom warnings
    - Implement pixel density validation
    - Create crop area validation before confirmation
    - _Requirements: 5.2, 5.5, 8.4, 8.5_
  
  - [ ]* 7.4 Create comprehensive test suite
    - Cross-module integration testing
    - Accessibility compliance validation
    - Visual regression testing
    - _Requirements: 4.1, 4.2, 4.3, 4.4_