# Implementation Plan

- [x] 1. Set up project structure and core interfaces
  - Create DirectMessages feature package with proper dependencies
  - Define messaging service protocols in AppFoundation
  - Set up basic routing and entry points
  - _Requirements: 1.1, 2.1_

- [x] 1.1 Create DirectMessages feature package structure
  - Create Package.swift with dependencies on DesignSystem, AppFoundation, Messaging, Media
  - Set up directory structure for Views, ViewModels, Components, and Routing
  - Create basic README and test structure
  - _Requirements: 1.1_

- [x] 1.2 Define messaging service protocols in AppFoundation
  - Add MessagingServiceProtocol with conversation and message operations
  - Add MessagingRealtimeProtocol with subscription and typing capabilities
  - Add MessagingMediaProtocol for attachment preparation
  - Define MessagingEvent enum for real-time updates
  - _Requirements: 1.1, 2.1, 3.1, 6.1_

- [x] 1.3 Create routing and entry point infrastructure
  - Add DMsRoute enum to AppFoundation Routes
  - Implement DMsEntry view as public interface
  - Set up navigation between conversation list and chat views
  - _Requirements: 1.1, 2.1_

- [ ] 2. Implement core data models and messaging kit
  - Create Conversation, Message, and Attachment models with all required fields
  - Implement MessagingRealtimeObserver actor for real-time management
  - Create MessagingServiceLive and MessagingRealtimeLive implementations
  - Set up dependency injection for messaging services
  - _Requirements: 3.1, 6.1, 5.1_

- [ ] 2.1 Create comprehensive data models
  - Implement Conversation model with pinning, muting, drafts, and group support
  - Implement Message model with nonces, editing, system messages, and link previews
  - Implement Attachment model with size limits and metadata
  - Create MessageNonce and OutboundMessageDraft for optimistic updates
  - _Requirements: 3.1, 5.1_

- [ ] 2.2 Implement MessagingRealtimeObserver actor
  - Create actor with Input/Output enums and configuration
  - Implement channel management with chunking for >100 conversations
  - Add lifecycle management for foreground/background states
  - Implement typing signal broadcasting and coalescing logic
  - _Requirements: 6.1, 6.2, 6.3_

- [ ] 2.3 Create messaging service implementations
  - Implement MessagingServiceLive with all CRUD operations
  - Implement MessagingRealtimeLive bridging observer to protocol
  - Create MessagingMediaLive for attachment preparation
  - Add proper error handling and retry logic
  - _Requirements: 3.1, 5.1, 6.1_

- [ ] 2.4 Set up dependency injection
  - Add messaging service properties to Dependencies struct
  - Create live dependency configuration
  - Wire up services in app initialization
  - _Requirements: 1.1, 3.1_

- [ ] 3. Build conversation list view (DirectMessagesView)
  - Create DirectMessagesView with conversation list display
  - Implement DirectMessagesViewModel with state management
  - Create ConversationRow component for list items
  - Add pull-to-refresh and navigation functionality
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_

- [ ] 3.1 Create DirectMessagesView and basic layout
  - Implement NavigationStack with List of conversations
  - Add navigation title and basic styling
  - Set up tap gesture handling for conversation selection
  - _Requirements: 1.1, 1.2_

- [ ] 3.2 Implement DirectMessagesViewModel
  - Create ObservableObject with conversation state management
  - Add methods for fetching conversations and handling navigation
  - Implement real-time subscription for conversation list updates
  - Add search and filtering capabilities
  - _Requirements: 1.2, 1.3, 1.4_

- [ ] 3.3 Create ConversationRow component
  - Design row layout with avatar, name, preview, and timestamp
  - Add unread indicators and conversation status display
  - Implement proper accessibility labels and Dynamic Type support
  - _Requirements: 1.3, 1.5, 10.1, 10.2_

- [ ] 3.4 Add pull-to-refresh and loading states
  - Implement refreshable modifier for conversation loading
  - Add skeleton loading states for initial load
  - Handle empty states and error conditions
  - _Requirements: 1.4_

- [ ] 4. Build chat interface (ConversationView)
  - Create ConversationView with message list and composer
  - Implement ConversationViewModel with message state management
  - Add scroll management and keyboard handling
  - Set up real-time message subscriptions
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 9.1, 9.2, 9.3, 9.4, 9.5_

- [ ] 4.1 Create ConversationView basic structure
  - Implement ScrollViewReader with LazyVStack for message list
  - Add safeAreaInset for composer positioning
  - Set up basic navigation and title display
  - _Requirements: 2.1, 2.2_

- [ ] 4.2 Implement ConversationViewModel
  - Create ObservableObject with message state and pagination
  - Add real-time subscription management for individual conversations
  - Implement optimistic message sending with nonce handling
  - Add typing indicator state management
  - _Requirements: 2.3, 2.4, 2.5, 6.1, 6.2_

- [ ] 4.3 Add scroll management and auto-scroll
  - Implement automatic scroll to latest message on load
  - Add scroll position preservation for older message loading
  - Handle smooth scrolling animations for new messages
  - _Requirements: 2.2, 2.3_

- [ ] 4.4 Implement keyboard-aware layout
  - Set up safeAreaInset positioning for composer
  - Add keyboard dismissal via scroll gesture
  - Handle layout adjustments when keyboard appears/disappears
  - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5_

- [ ] 5. Create message bubble components
  - Implement MessageBubble with sender-appropriate styling
  - Add support for text, media, and link previews
  - Create context menu with copy, reply, delete actions
  - Add swipe gestures for quick reply
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 7.1, 7.2, 7.3, 7.4, 7.5, 8.1, 8.2, 8.3, 8.4, 8.5_

- [ ] 5.1 Create basic MessageBubble component
  - Implement bubble layout with proper alignment for sender
  - Add rounded rectangle styling with continuous corners
  - Set up color scheme for current user vs others
  - Add timestamp and delivery status display
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

- [ ] 5.2 Add media support to message bubbles
  - Implement inline image display with 400px max constraint
  - Add video thumbnail support with play indicators
  - Create lazy loading for full-resolution media on tap
  - Handle EXIF orientation and aspect ratio preservation
  - _Requirements: 5.4_

- [ ] 5.3 Implement context menu actions
  - Add long-press gesture with Copy, Reply, Delete options
  - Implement clipboard integration for message copying
  - Add reply preview functionality in composer
  - Create delete confirmation and optimistic removal
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

- [ ] 5.4 Add swipe gesture for quick reply
  - Implement swipe-to-reply with visual feedback
  - Add smooth animation and haptic feedback
  - Ensure accessibility compliance with VoiceOver
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_

- [ ] 6. Build composer bar with attachments
  - Create ComposerBar with growing text input
  - Add PhotosPicker integration for media attachments
  - Implement send button with proper state management
  - Add haptic feedback and keyboard handling
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 5.1, 5.2, 5.3, 5.4, 5.5_

- [ ] 6.1 Create ComposerBar basic structure
  - Implement HStack layout with TextEditor and buttons
  - Add growing text input with height constraints (38-120pt)
  - Set up material background and proper spacing
  - _Requirements: 3.1, 3.2, 3.3_

- [ ] 6.2 Add send functionality and state management
  - Implement send button with enabled/disabled states
  - Add onSubmit handling for Return key sending
  - Create haptic feedback on successful send
  - Handle text clearing and focus management
  - _Requirements: 3.4, 3.5_

- [ ] 6.3 Integrate PhotosPicker for media attachments
  - Add attachment button with PhotosPicker presentation
  - Implement media selection and preparation pipeline
  - Add attachment preview chips above text input
  - Handle media upload progress and error states
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_

- [ ] 6.4 Add draft persistence and restoration
  - Implement per-conversation draft text storage
  - Restore draft text when entering conversations
  - Auto-save draft changes with debouncing
  - _Requirements: 3.1_

- [ ] 7. Implement typing indicators and real-time features
  - Create TypingIndicator component with animated dots
  - Add typing detection and broadcast functionality
  - Implement message delivery status updates
  - Set up real-time message arrival handling
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

- [ ] 7.1 Create TypingIndicator component
  - Implement animated dots using TimelineView or phaseAnimator
  - Add smooth appearance/disappearance animations
  - Handle multiple users typing with proper display limits
  - _Requirements: 6.1, 6.4, 6.5_

- [ ] 7.2 Implement typing detection and broadcasting
  - Add debounced typing detection (300ms start, 3s keepalive, 4s auto-stop)
  - Implement typing signal broadcasting via real-time channels
  - Handle typing state cleanup on app backgrounding
  - _Requirements: 6.2, 6.3_

- [ ] 7.3 Add real-time message delivery and status
  - Implement optimistic UI updates for sent messages
  - Add real-time message arrival with smooth animations
  - Handle delivery status progression (sending → sent → delivered → read)
  - Set up message deduplication by nonce
  - _Requirements: 2.5, 6.1_

- [ ] 8. Add accessibility and internationalization support
  - Implement comprehensive VoiceOver labels and navigation
  - Add Dynamic Type support throughout the interface
  - Handle Reduce Motion preferences for animations
  - Set up proper focus management and touch targets
  - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5_

- [ ] 8.1 Implement VoiceOver accessibility
  - Add descriptive labels for message bubbles with sender, time, and content
  - Create proper accessibility grouping for conversation elements
  - Implement rotor navigation between messages
  - _Requirements: 10.1, 10.4_

- [ ] 8.2 Add Dynamic Type and visual accessibility
  - Ensure all text scales properly with Dynamic Type settings
  - Verify minimum touch target sizes (44pt) for all interactive elements
  - Test layout with largest accessibility text sizes
  - _Requirements: 10.2, 10.5_

- [ ] 8.3 Handle motion and animation preferences
  - Respect Reduce Motion settings for message animations
  - Provide alternative feedback for users with motion sensitivity
  - Ensure core functionality works without animations
  - _Requirements: 10.3_

- [ ] 8.4 Set up internationalization support
  - Use RelativeDateTimeFormatter for timestamps
  - Support right-to-left layout mirroring
  - Ensure proper text direction for message bubbles
  - _Requirements: 10.1_

- [ ] 9. Integrate with existing app systems
  - Wire up navigation from main app to DM system
  - Integrate with analytics for usage tracking
  - Set up push notifications for new messages
  - Add abuse reporting and user blocking features
  - _Requirements: 1.1, 7.5_

- [ ] 9.1 Connect main app navigation
  - Update main tab navigation to include DM button
  - Implement deep linking to specific conversations
  - Add proper navigation state management
  - _Requirements: 1.1_

- [ ] 9.2 Integrate analytics tracking
  - Add event tracking for DM usage patterns
  - Implement privacy-compliant analytics (no message content)
  - Set up conversion funnels for messaging engagement
  - _Requirements: Analytics integration_

- [ ] 9.3 Set up push notification integration
  - Configure OneSignal for DM-specific notifications
  - Implement conversation-specific notification categories
  - Add notification collapse keys and deep linking
  - Respect muted/archived conversation settings
  - _Requirements: Notifications integration_

- [ ] 9.4 Add safety and moderation features
  - Implement message reporting functionality
  - Add user blocking capabilities
  - Create abuse prevention measures
  - _Requirements: 7.5_

- [ ] 10. Write comprehensive tests
  - Create unit tests for ViewModels and service implementations
  - Add integration tests for real-time functionality
  - Implement UI tests for complete user flows
  - Create performance tests for message list optimization
  - _Requirements: All requirements_

- [ ] 10.1 Write unit tests for core functionality
  - Test ConversationViewModel message handling and state management
  - Test DirectMessagesViewModel conversation list operations
  - Test MessagingRealtimeObserver actor behavior and channel management
  - Test optimistic update logic and conflict resolution
  - _Requirements: 2.3, 2.4, 6.1_

- [ ] 10.2 Create integration tests for real-time features
  - Test end-to-end message sending and receiving
  - Test typing indicator functionality across multiple users
  - Test real-time subscription management and reconnection
  - Test message delivery status progression
  - _Requirements: 6.1, 6.2, 6.3, 7.3_

- [ ] 10.3 Implement UI tests for user flows
  - Test complete conversation creation and messaging flow
  - Test media attachment selection and sending
  - Test message actions (copy, delete, reply) functionality
  - Test accessibility compliance with VoiceOver
  - _Requirements: 1.1, 2.1, 3.1, 5.1, 7.1, 8.1, 10.1_

- [ ] 10.4 Add performance and load tests
  - Test message list performance with 10k+ messages
  - Test real-time reconnection under network stress
  - Test memory usage with large conversation lists
  - Test scroll performance and frame rate consistency
  - _Requirements: Performance considerations_