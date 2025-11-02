# Implementation Plan

- [x] 1. Create core data models and protocols
  - Define ToastID, ToastKind, ToastPriority, ToastOptions, ToastAction, and ToastItem structs
  - Implement ToastsProviding protocol with async methods
  - Create ToastPolicy configuration struct with environment integration
  - Add ToastTelemetry protocol with async analytics hooks
  - _Requirements: 1.1, 4.1, 4.2, 4.4, 6.2_

- [x] 2. Implement ToastManager actor with queue management
  - Create actor-based ToastManager with thread-safe queue operations
  - Implement PresentationState enum for deterministic state transitions
  - Add FIFO queuing with priority interruption logic
  - Implement coalescing policy with dedupeKey matching
  - Add rate limiting with configurable minimum intervals
  - _Requirements: 4.1, 4.4, 6.1, 6.2, 6.3_

- [x] 3. Build scene-aware presentation system
  - Create ToastPresenter class with scene binding and lifecycle management
  - Implement SceneOverlayCoordinator for shared presentation surface
  - Add UIKitHostingController integration for gesture isolation
  - Implement keyboard avoidance for bottom-presented toasts
  - Add safe area calculation and multi-window support
  - _Requirements: 1.4, 6.4, 9.3, 9.4_

- [x] 4. Create ToastView with Liquid Glass materials
  - Implement SwiftUI ToastView with iOS 26 Liquid Glass background
  - Add ultraThin material with vibrancy layers for content contrast
  - Integrate Agora DesignSystem tokens for colors, typography, and spacing
  - Implement adaptive layout for icon, text, and optional action button
  - Add corner radius, border highlights, and subtle shadow effects
  - _Requirements: 1.1, 2.1, 2.2, 2.3, 2.4, 2.5_

- [x] 5. Implement animation system with accessibility support
  - Create spring-based appearance animations with scale and opacity
  - Add dismissal animations with fade and directional translation
  - Implement Reduce Motion adaptation using cross-fade only
  - Add interactive dismissal with pan gesture recognition
  - Ensure 240ms animation timing with 60/120 FPS performance
  - _Requirements: 5.1, 5.2, 3.2, 7.7_

- [x] 6. Add comprehensive accessibility features
  - Implement VoiceOver announcements with polite/assertive priority
  - Add accessibility labels, hints, and custom actions for dismiss/action
  - Support Dynamic Type up to xxxLarge with adaptive layout
  - Implement Reduce Transparency adaptation with maintained contrast
  - Ensure 44x44pt minimum touch targets for all interactive elements
  - _Requirements: 3.1, 3.3, 3.4, 7.1, 7.2, 7.3, 7.4, 7.5_

- [x] 7. Integrate haptic feedback system
  - Implement ToastHaptic enum with notification and impact feedback types
  - Add semantic haptics for success, error, warning, and info toast kinds
  - Coordinate haptic timing with toast appearance animations
  - Respect system haptics toggle and provide per-toast opt-out
  - Support custom haptic types for ToastKind.custom variants
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_

- [x] 8. Build environment integration and dependency injection
  - Create ToastEnvironmentKey and EnvironmentValues extension
  - Register ToastManager in AppFoundation ServiceFactory
  - Add convenience extensions for success, error, info, warning methods
  - Implement NoOpToastProvider for testing and preview contexts
  - Add ToastPolicyKey environment integration for configuration overrides
  - _Requirements: 4.1, 4.5, 6.1_

- [x] 9. Implement performance optimizations and resource management
  - Add blur view reusing and layer limitation (max 3 sublayers)
  - Implement Low Power Mode adaptations for shadows and blur radius
  - Add memory management with weak scene references and cleanup
  - Implement queue bounds limiting and timer invalidation
  - Add texture caching for SF Symbol renders
  - _Requirements: 5.3, 5.4, 5.5_

- [ ] 10. Add iPad and landscape orientation support
  - Implement maximum width constraints (600pt) with horizontal centering
  - Add orientation change handling with layout recomputation
  - Implement keyboard frame observation and bottom toast repositioning
  - Add system banner conflict detection with 300ms presentation delay
  - Support size class adaptations for compact and regular layouts
  - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5_

- [ ] 11. Implement error handling and graceful degradation
  - Add material fallback to solid colors when blur is unavailable
  - Implement animation fallback with instant transitions on failure
  - Add scene recovery with presenter recreation on invalid references
  - Implement queue recovery for critical toasts through app lifecycle
  - Add restoration queue for cold launch scenarios
  - _Requirements: 6.4, 6.5_

- [x] 12. Create comprehensive test suite
  - Write unit tests for queue logic, priority interruption, and coalescing
  - Add timer management tests for background/foreground lifecycle
  - Create scene coordination tests for multi-window presenter management
  - Implement accessibility tests for VoiceOver announcement verification
  - Add snapshot tests for visual variants and accessibility states
  - _Requirements: All requirements validation_

- [ ] 13. Add performance and integration testing
  - Create animation smoothness tests with frame rate measurement
  - Add memory usage tests with leak detection and pressure testing
  - Implement battery impact measurement and Core Animation profiling
  - Create keyboard avoidance and multi-scene isolation tests
  - Add system conflict tests with banners and interactive dismissal accuracy
  - _Requirements: 5.1, 5.2, 5.3, 9.3, 9.4, 9.5_

- [ ] 14. Create documentation and developer experience
  - Add DocC documentation with usage examples and API reference
  - Create ToastView_Previews with grid of all kinds and accessibility states
  - Implement debug panel for testing toast variants in development builds
  - Add usage examples for common patterns and integration scenarios
  - Create migration guide for existing notification systems
  - _Requirements: 4.1, 4.2, 4.3_