# Analytics Kit

The Analytics kit provides event tracking and crash reporting functionality for the Agora iOS app.

## Overview

This module handles:
- PostHog integration for event tracking
- Sentry integration for crash reporting
- Type-safe event definitions
- User identification and properties
- Error tracking and breadcrumbs

## Components

### AnalyticsManager
Core analytics functionality with PostHog integration.

```swift
let analytics = AnalyticsManager.shared

// Initialize
analytics.initialize(apiKey: "your-posthog-key")

// Identify user
analytics.identify(userId: "user123", properties: ["plan": "premium"])

// Track events
analytics.track(event: "button_clicked", properties: ["button": "signup"])

// Set user properties
analytics.setUserProperties(["age": 25, "location": "SF"])
```

### EventTracker
Type-safe event tracking with predefined events.

```swift
let tracker = EventTracker.shared

// Track type-safe events
tracker.track(.postCreated(characterCount: 100, hasMedia: true))
tracker.track(.userSignedIn(method: "apple"))
tracker.track(.screenViewed(screenName: "home"))

// Track custom events
tracker.track(event: "custom_event", properties: ["key": "value"])

// Track errors
tracker.trackError(someError, context: "user_action")
```

### CrashReporter
Crash reporting and error tracking with Sentry integration.

```swift
let crashReporter = CrashReporter.shared

// Initialize
crashReporter.initialize(dsn: "your-sentry-dsn", environment: "production")

// Report errors
crashReporter.reportError(error, context: ["user_id": "123"])

// Report messages
crashReporter.reportMessage("Something happened", level: .warning)

// Set user context
crashReporter.setUser(id: "user123", email: "user@example.com")

// Add breadcrumbs
crashReporter.addBreadcrumb(message: "User tapped button", category: "ui")
```

## Event Types

The kit provides type-safe event definitions:

- **User Events**: Sign in/out, profile updates
- **Post Events**: Creation, likes, reposts, views
- **Feed Events**: Refresh, scrolling
- **Navigation Events**: Screen views, tab switches
- **Search Events**: Queries, result interactions
- **Media Events**: Uploads, processing
- **Error Events**: Errors, network failures

## Dependencies

- Foundation
- PostHog SDK (to be added)
- Sentry SDK (to be added)

## Usage

Import the module in your Swift files:

```swift
import Analytics
```

## Architecture

The Analytics kit is designed to be:
- Type-safe with predefined event structures
- Privacy-conscious with configurable data collection
- Performance-optimized with batching and queuing
- Testable with dependency injection support
- Extensible for new event types

## Testing

Run tests using:

```bash
swift test --package-path Packages/Kits/Analytics
```

## Configuration

### Environment Setup
Configure different environments:

```swift
#if DEBUG
analytics.initialize(apiKey: "dev-key")
crashReporter.initialize(dsn: "dev-dsn", environment: "development")
#else
analytics.initialize(apiKey: "prod-key")
crashReporter.initialize(dsn: "prod-dsn", environment: "production")
#endif
```

### Privacy Compliance
The kit supports privacy-first analytics:
- User consent management
- Data anonymization options
- Opt-out capabilities
- GDPR compliance features