# Moderation Kit

The Moderation kit provides content reporting and safety features for the Agora iOS app.

## Overview

This module handles:
- Content reporting and submission
- Keyword muting and content filtering
- Safety policy enforcement
- User action permission checks
- Content validation before posting

## Components

### ReportComposer
Handles content reporting with a SwiftUI interface.

```swift
// Present report composer
ReportComposerView(contentId: "post123", contentType: .post)

// Programmatic reporting
let composer = ReportComposer()
try await composer.submitReport(
    contentId: "post123",
    contentType: .post,
    reportType: .spam,
    description: "This is spam content"
)
```

### ContentFilter
Keyword muting engine for content filtering.

```swift
let filter = ContentFilter.shared

// Configure filtering
let config = FilterConfig(
    mutedKeywords: ["spam", "bot"],
    mutedUsers: ["user123"],
    hideReplies: true,
    caseSensitive: false
)
filter.updateConfig(config)

// Filter content
let result = filter.filterContent(someContent)
switch result {
case .show:
    // Show content normally
case .hide(let reason):
    // Hide content with reason
case .warn(let reason):
    // Show with warning
}

// Manage muted keywords
filter.muteKeyword("unwanted")
filter.unmuteKeyword("unwanted")

// Manage muted users
filter.muteUser("user123")
filter.unmuteUser("user123")
```

### SafetyManager
Policy enforcement and content validation.

```swift
let safetyManager = SafetyManager.shared

// Validate content before posting
let result = await safetyManager.validateContent("Post content")
switch result {
case .valid:
    // Content is safe to post
case .warning(let reason):
    // Show warning but allow posting
case .flagged(let reason):
    // Content flagged for review
case .invalid(let reason):
    // Content violates policies
}

// Check user permissions
let permission = await safetyManager.canPerformAction(.post, userId: "user123")
switch permission {
case .allowed:
    // User can perform action
case .denied(let reason):
    // Action denied
case .rateLimited(let retryAfter):
    // Rate limited, retry after specified time
}
```

## Report Types

The kit supports various report categories:

- **Spam**: Unwanted or repetitive content
- **Harassment**: Targeted harassment or bullying
- **Hate Speech**: Content that promotes hatred
- **Violence**: Violent or graphic content
- **Sexual Content**: Inappropriate sexual content
- **Misinformation**: False or misleading information
- **Copyright**: Unauthorized use of copyrighted material
- **Other**: Other policy violations

## Content Filtering

### Filter Results
- **Show**: Display content normally
- **Hide**: Hide content with reason
- **Warn**: Show with warning overlay

### Filter Reasons
- Muted keyword detected
- Muted user content
- Hidden replies (if configured)
- Hidden reposts (if configured)
- Sensitive content warning
- Reported content warning

## Dependencies

- DesignSystem (for UI components)
- Networking (for API communication)
- SwiftUI
- Foundation

## Usage

Import the module in your Swift files:

```swift
import Moderation
```

## Architecture

The Moderation kit is designed to be:
- Privacy-focused with local filtering
- Configurable per user preferences
- Extensible for new report types
- Integrated with backend moderation systems
- Compliant with platform policies

## Testing

Run tests using:

```bash
swift test --package-path Packages/Kits/Moderation
```

## Configuration

### Filter Configuration
Users can customize their content filtering:

```swift
let config = FilterConfig(
    mutedKeywords: Set(["keyword1", "keyword2"]),
    mutedUsers: Set(["user1", "user2"]),
    hideReplies: false,
    hideReposts: false,
    caseSensitive: false
)
```

### Safety Policies
The SafetyManager enforces various policies:
- Content length limits
- Spam detection
- Personal information detection
- Rate limiting
- User status checks

## Privacy & Safety

The kit prioritizes user safety and privacy:
- Local content filtering when possible
- Transparent reporting processes
- User control over filtering preferences
- Compliance with content policies
- Protection against harassment