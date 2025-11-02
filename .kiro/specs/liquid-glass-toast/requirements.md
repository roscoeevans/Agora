# Requirements Document

## Introduction

A reusable toast notification component that leverages iOS 26's Liquid Glass design language to provide elegant, non-intrusive feedback throughout the Agora app. The system provides scene-aware, accessible, and performant notifications with sophisticated queuing, coalescing, and priority management.

## Glossary

- **Toast_Manager**: Actor-based service responsible for queuing, coalescing, and managing toast lifecycle
- **Toast_Presenter**: Scene-bound component that hosts toast overlays within specific UI scenes
- **Toast_View**: SwiftUI component implementing Liquid Glass visual design with blur and vibrancy
- **Toast_Item**: Data model representing a single toast notification with message, kind, and options
- **Toast_Priority**: Enumeration defining interruption behavior (normal, elevated, critical)
- **Liquid_Glass_Material**: iOS 26's translucent background with backdrop blur and vibrancy layers
- **Coalescing_Policy**: System for deduplicating toasts with matching keys within time windows
- **Scene_Awareness**: Multi-window support ensuring toasts appear in the correct UI context

## Requirements

### Requirement 1

**User Story:** As a user, I want to receive elegant visual feedback for my actions, so that I understand the result of my interactions without disrupting my workflow.

#### Acceptance Criteria

1. WHEN a user performs an action requiring feedback, THE Toast_View SHALL display using iOS 26 Liquid Glass materials with backdrop blur
2. THE Toast_View SHALL automatically dismiss after 3 seconds with configurable duration between 1-10 seconds
3. THE Toast_Manager SHALL queue multiple toasts sequentially without visual overlap
4. THE Toast_View SHALL support top or bottom presentation edges with safe area avoidance
5. WHERE user interaction occurs, THE Toast_View SHALL allow tap-to-dismiss and directional swipe gestures

### Requirement 2

**User Story:** As a user, I want toast notifications to feel native to iOS, so that they integrate seamlessly with the system's design language.

#### Acceptance Criteria

1. THE Toast_View SHALL use ultraThin material with vibrancy layers for text contrast over busy backgrounds
2. THE Toast_View SHALL apply 16-20pt corner radius with 1pt hairline stroke for floating appearance
3. THE Toast_View SHALL use SF Symbols for iconography with semantic color tinting per toast kind
4. THE Toast_View SHALL follow Dynamic Type with Title3/Semibold for single lines and Body/Medium for multi-line content
5. THE Toast_View SHALL support both light and dark mode with automatic material adaptation

### Requirement 3

**User Story:** As a user with accessibility needs, I want toast notifications to be announced and accessible, so that I can receive feedback regardless of my abilities.

#### Acceptance Criteria

1. WHEN a toast appears, THE Toast_View SHALL post UIAccessibility announcement with polite priority by default
2. THE Toast_View SHALL respect Reduce Motion by using cross-fade transitions only
3. THE Toast_View SHALL respect Reduce Transparency by reducing blur radius while maintaining contrast
4. THE Toast_View SHALL maintain minimum 4.5:1 contrast ratio for text over material backgrounds
5. THE Toast_View SHALL provide 44x44pt minimum touch targets for dismiss and action affordances

### Requirement 4

**User Story:** As a developer, I want a simple API to show toast notifications, so that I can easily provide feedback throughout the app.

#### Acceptance Criteria

1. THE Toast_Manager SHALL provide environment-accessible API through @Environment(\.toasts)
2. THE Toast_Manager SHALL support convenience methods for success, error, info, and warning types
3. THE Toast_Manager SHALL allow custom ToastKind with optional icon and accent color
4. THE Toast_Manager SHALL support optional single action with LocalizedStringKey title and handler
5. THE Toast_Manager SHALL integrate with AppFoundation dependency injection system

### Requirement 5

**User Story:** As a user, I want toast notifications to perform smoothly, so that they don't impact my app experience.

#### Acceptance Criteria

1. THE Toast_View SHALL complete appearance animations within 240ms using spring-based scaling and opacity
2. THE Toast_View SHALL complete dismissal animations within 240ms with fade and translation
3. THE Toast_Manager SHALL maintain 60 FPS baseline with 120 FPS support on ProMotion displays
4. THE Toast_View SHALL limit to 3 sublayers maximum and reuse blur views for efficiency
5. WHERE Low Power Mode is active, THE Toast_View SHALL disable expensive shadows and reduce blur radius

### Requirement 6

**User Story:** As a user receiving multiple notifications, I want them managed intelligently, so that I'm not overwhelmed by duplicate or low-priority messages.

#### Acceptance Criteria

1. THE Toast_Manager SHALL implement FIFO queuing with rate limiting of maximum 1 toast per 800ms
2. WHERE dedupeKey matches existing queued or visible toast, THE Toast_Manager SHALL update existing item instead of creating duplicate
3. WHEN critical priority toast arrives, THE Toast_Manager SHALL dismiss lower priority toasts within 120ms
4. THE Toast_Manager SHALL pause timers during background state and resume on foreground
5. THE Toast_Manager SHALL drop or hold toasts when no active scene is present based on configuration

### Requirement 7

**User Story:** As a user with system accessibility settings enabled, I want toasts to adapt appropriately, so that they remain usable with my preferences.

#### Acceptance Criteria

1. THE Toast_View SHALL support Dynamic Type up to Extra-Extra-Extra Large with maximum 2 lines before truncation
2. THE Toast_View SHALL provide full message text via accessibilityLabel when truncated
3. THE Toast_View SHALL announce action hints via VoiceOver when actions are present
4. THE Toast_View SHALL expose explicit "Dismiss" action for VoiceOver users
5. WHERE Reduce Motion is enabled, THE Toast_View SHALL use fade-only transitions without scale or translation

### Requirement 8

**User Story:** As a user, I want appropriate haptic feedback with toasts, so that I receive multi-sensory confirmation of actions.

#### Acceptance Criteria

1. THE Toast_Manager SHALL provide notification haptics for success (.success) and error (.error) types
2. THE Toast_Manager SHALL provide impact haptics for warning (.warning) and info (.light) types
3. THE Toast_Manager SHALL respect system haptics toggle and allow per-toast opt-out
4. THE Toast_Manager SHALL support custom haptic types for ToastKind.custom variants
5. THE Toast_Manager SHALL coordinate haptics with toast appearance timing

### Requirement 9

**User Story:** As a user on iPad or in landscape orientation, I want toasts to layout appropriately, so that they don't interfere with my workflow.

#### Acceptance Criteria

1. THE Toast_View SHALL constrain maximum width to 600pt on iPad and landscape orientations
2. THE Toast_View SHALL center horizontally when constrained by maximum width
3. THE Toast_Presenter SHALL recompute layout on orientation and size class changes
4. WHERE software keyboard is present, THE Toast_Presenter SHALL shift bottom toasts above keyboard frame
5. THE Toast_Presenter SHALL defer presentation 300ms when system banners are active to avoid visual conflicts