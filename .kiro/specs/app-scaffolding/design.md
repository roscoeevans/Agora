# Design Document

## Overview

The Agora iOS app will be built using a modular Swift Package Manager (SPM) architecture that promotes separation of concerns, testability, and parallel development. The design follows Apple's iOS 26.0 patterns with SwiftUI 6, @Observable models, and modern concurrency.

The architecture consists of three main layers:
1. **Feature Modules** - Self-contained UI and business logic for specific app surfaces
2. **Kit Modules** - Shared functionality and cross-cutting concerns
3. **Main App Target** - Integration layer and app lifecycle management

## Architecture

### Project Structure
```
Agora/
├── Agora.xcodeproj
├── Package.swift (workspace-level dependencies)
├── Resources/ (main app resources)
├── Packages/
│   ├── Features/
│   │   ├── HomeForYou/
│   │   ├── HomeFollowing/
│   │   ├── Compose/
│   │   ├── PostDetail/
│   │   ├── Threading/
│   │   ├── Profile/
│   │   ├── Search/
│   │   ├── Notifications/
│   │   └── DMs/
│   ├── Kits/
│   │   ├── DesignSystem/
│   │   ├── Networking/
│   │   ├── Persistence/
│   │   ├── Auth/
│   │   ├── Media/
│   │   ├── Analytics/
│   │   ├── Moderation/
│   │   ├── Verification/
│   │   └── Recommender/
│   └── Shared/
│       ├── AppFoundation/
│       └── TestSupport/
```

### Dependency Flow
- **Main App** depends on all Feature modules
- **Feature modules** depend on relevant Kit modules
- **Kit modules** may depend on other Kit modules or external packages
- **No circular dependencies** between modules at the same level

### Module Boundaries
Each module will have clear public interfaces and internal implementation details:
- Public APIs exposed through module imports
- Internal types and functions kept private to the module
- Protocol-based abstractions for testability and flexibility

## Components and Interfaces

### Feature Modules

#### HomeForYou
- **Purpose**: For You feed with personalized recommendations
- **Key Components**: 
  - `ForYouView` - Main feed interface
  - `ForYouViewModel` - Feed state management and data loading
  - `ForYouCoordinator` - Navigation coordination
- **Dependencies**: DesignSystem, Networking, Analytics, Recommender

#### HomeFollowing  
- **Purpose**: Chronological feed of followed users
- **Key Components**:
  - `FollowingView` - Chronological feed interface
  - `FollowingViewModel` - Feed state and refresh logic
- **Dependencies**: DesignSystem, Networking, Analytics

#### Compose
- **Purpose**: Post creation and editing
- **Key Components**:
  - `ComposeView` - Post composition interface
  - `ComposeViewModel` - Draft management and validation
  - `MediaPickerView` - Photo/video selection
- **Dependencies**: DesignSystem, Media, Networking, Verification

#### PostDetail
- **Purpose**: Individual post view with replies
- **Key Components**:
  - `PostDetailView` - Post and replies display
  - `PostDetailViewModel` - Post data and interaction handling
- **Dependencies**: DesignSystem, Networking, Threading

#### Threading
- **Purpose**: Reply chains and conversation management
- **Key Components**:
  - `ThreadView` - Reply chain display
  - `ReplyComposer` - Reply creation interface
- **Dependencies**: DesignSystem, Networking

#### Profile
- **Purpose**: User profiles and settings
- **Key Components**:
  - `ProfileView` - User profile display
  - `ProfileEditView` - Profile editing interface
  - `SettingsView` - App settings
- **Dependencies**: DesignSystem, Networking, Auth, Media

#### Search
- **Purpose**: User and post search functionality
- **Key Components**:
  - `SearchView` - Search interface and results
  - `SearchViewModel` - Search query handling
- **Dependencies**: DesignSystem, Networking

#### Notifications
- **Purpose**: Activity notifications and alerts
- **Key Components**:
  - `NotificationsView` - Notification list
  - `NotificationRow` - Individual notification display
- **Dependencies**: DesignSystem, Networking

#### DMs
- **Purpose**: Direct messaging functionality
- **Key Components**:
  - `DMThreadsView` - Message thread list
  - `DMChatView` - Individual conversation
  - `DMComposeView` - New message creation
- **Dependencies**: DesignSystem, Networking, Media

### Kit Modules

#### DesignSystem
- **Purpose**: Shared UI components and design tokens
- **Key Components**:
  - `AgoraButton` - Standardized button styles
  - `AgoraTextField` - Input field components
  - `ColorTokens` - App color palette
  - `TypographyScale` - Text styles and hierarchy
  - `SpacingTokens` - 8-point grid spacing values
- **Dependencies**: None (foundation module)

#### Networking
- **Purpose**: HTTP client and API communication
- **Key Components**:
  - `APIClient` - OpenAPI-generated models, AuthInterceptor (uses AuthTokenProvider from AppFoundation), retry/backoff, JSON decoding
  - `RequestBuilder` - Type-safe request construction
  - `ResponseDecoder` - JSON response parsing
- **Dependencies**: AppFoundation (for AuthTokenProvider protocol)

#### Persistence
- **Purpose**: Local data storage and caching
- **Key Components**:
  - `SwiftDataStore` - SwiftData models & migrations
  - `CacheManager` - In-memory and disk caching
  - `DraftStore` - Compose draft persistence
- **Dependencies**: None

#### Auth
- **Purpose**: Authentication and session management (Sign in with Apple + phone verification required for posting)
- **Key Components**:
  - `AuthManager` - Sign in with Apple integration
  - `SessionStore` - Token storage and refresh
  - `KeychainHelper` - Secure credential storage
- **Dependencies**: Verification (for phone verification), AppFoundation (implements AuthTokenProvider)

#### Media
- **Purpose**: Photo/video capture, processing, and upload
- **Key Components**:
  - `MediaPicker` - System photo picker integration
  - `MediaProcessor` - Image/video compression
  - `UploadManager` - Cloudflare upload handling
- **Dependencies**: Networking

#### Analytics
- **Purpose**: Event tracking and crash reporting
- **Key Components**:
  - `AnalyticsManager` - PostHog integration
  - `EventTracker` - Type-safe event logging
  - `CrashReporter` - Sentry integration
- **Dependencies**: None

#### Moderation
- **Purpose**: Content reporting and safety features
- **Key Components**:
  - `ReportComposer` - Report submission interface
  - `ContentFilter` - Keyword muting engine
  - `SafetyManager` - Policy enforcement
- **Dependencies**: DesignSystem, Networking

#### Verification
- **Purpose**: Device attestation and phone verification
- **Key Components**:
  - `AppAttestManager` - App Attest integration
  - `PhoneVerifier` - Twilio Verify integration
  - `DeviceChecker` - DeviceCheck validation
- **Dependencies**: Networking

#### Recommender
- **Purpose**: For You feed recommendation logic
- **Key Components**:
  - `SignalCollector` - User interaction tracking (dwell/like/skip/etc.)
  - `FeedMixer` - UI mixing only (all scoring happens server-side)
- **Dependencies**: Analytics, Networking

### Shared Modules

#### AppFoundation
- **Purpose**: Core utilities and extensions
- **Key Components**:
  - `Logger` - Structured logging
  - `DateFormatter` - Standardized date formatting
  - `ValidationHelpers` - Input validation utilities
  - `AuthTokenProvider` - Protocol for token access (prevents circular dependencies)
- **Dependencies**: None

#### TestSupport
- **Purpose**: Testing utilities and mocks
- **Key Components**:
  - `MockNetworking` - Network request mocking
  - `TestFixtures` - Sample data for tests
  - `XCTestExtensions` - Custom test assertions
- **Dependencies**: All modules (for testing)

## Data Models

### Core Data Types
Each module will define its own data models following these patterns:

```swift
// User representation (uses Swift's built-in Identifiable)
public struct User: Identifiable, Codable {
    public let id: String
    public let handle: String
    public let displayName: String
    public let bio: String
    public let avatarURL: URL?
}

// Post representation  
public struct Post: Identifiable, Codable {
    public let id: String
    public let authorId: String
    public let text: String
    public let linkURL: URL?
    public let mediaBundle: MediaBundle?
    public let createdAt: Date
    public let likeCount: Int
    public let repostCount: Int
    public let replyCount: Int
}

// Media content
public struct MediaBundle: Codable {
    public let id: String
    public let type: MediaType
    public let url: URL
    public let thumbnailURL: URL?
    public let width: Int?
    public let height: Int?
}

// AuthTokenProvider protocol (in AppFoundation)
public protocol AuthTokenProvider: Sendable {
    func currentAccessToken() async throws -> String?
}
```

### State Management
- Use `@Observable` classes for ViewModels
- Implement `@State` and `@Binding` for local UI state
- Use `@Environment` for dependency injection
- Follow unidirectional data flow patterns

## Error Handling

### Error Types
```swift
public enum AgoraError: LocalizedError {
    case networkError(NetworkError)
    case authenticationRequired
    case validationError(String)
    case serverError(Int, String)
    case unknownError
    
    public var errorDescription: String? {
        // User-friendly error messages
    }
}
```

### Error Presentation
- Use SwiftUI's error handling with `@State` error properties
- Present errors using native iOS alert patterns
- Provide actionable error messages with retry options
- Log errors to Analytics for monitoring

### Graceful Degradation
- Show placeholder content when data fails to load
- No offline cache in MVP; show placeholders and retries on failures
- Provide clear feedback when features are unavailable

## Testing Strategy

### Unit Testing
- Test ViewModels in isolation using dependency injection
- Mock network requests and external dependencies
- Test business logic and data transformations
- Aim for 80%+ code coverage on critical paths

### Integration Testing
- Test module interactions and data flow
- Verify API contract compliance
- Test authentication and session management
- Validate error handling across module boundaries

### UI Testing
- Test critical user flows end-to-end
- Verify accessibility compliance
- Test on multiple device sizes and orientations
- Validate performance under various conditions

### Test Organization
```swift
// Example test structure
@testable import HomeForYou
import TestSupport
import XCTest

final class ForYouViewModelTests: XCTestCase {
    var viewModel: ForYouViewModel!
    var mockNetworking: MockNetworking!
    
    override func setUp() {
        mockNetworking = MockNetworking()
        viewModel = ForYouViewModel(networking: mockNetworking)
    }
    
    func testLoadFeed() async {
        // Test implementation
    }
}
```

### Performance Testing
- Measure app launch time and memory usage
- Test scroll performance in feeds
- Validate image loading and caching efficiency
- Monitor network request patterns

## Implementation Notes

### SwiftUI 6 Patterns
- Use `NavigationStack` for navigation hierarchy
- Implement `ViewThatFits` for responsive layouts
- Leverage `@Observable` for reactive state management
- Use `Task` for async operations in views

### Accessibility
- Support Dynamic Type with minimum 11pt text
- Provide VoiceOver labels and hints
- Respect Reduce Motion preferences
- Ensure high contrast ratios

### Performance Considerations
- Lazy load images and media content
- Implement efficient list virtualization
- Use background queues for heavy operations
- Cache frequently accessed data

### Security
- Store sensitive data in Keychain
- Validate all user inputs
- Implement proper session management
- Posting requires a valid session, Sign in with Apple, phone verification, and recent App Attest/DeviceCheck attestation
- Use generated Info.plist + .xcconfig overrides; keep Agora.entitlements minimal; capabilities managed via Signing & Capabilities