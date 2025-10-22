# Design Document

## Overview

The iMessage-inspired DM system will be implemented as a new Feature module following Agora's established architecture patterns. The system consists of two main views: a conversation list (DirectMessagesView) and individual chat interface (ConversationView), with supporting components for message bubbles, composer bar, and real-time interactions.

The design leverages SwiftUI's native capabilities for chat interfaces while maintaining clean separation of concerns through protocol-based dependency injection and modular architecture.

## Architecture

### Module Structure

```
Packages/Features/DirectMessages/
├── Package.swift
├── README.md
├── Sources/DirectMessages/
│   ├── DirectMessagesView.swift        // Conversation list
│   ├── ConversationView.swift          // Chat interface
│   ├── Components/
│   │   ├── MessageBubble.swift         // Individual message display
│   │   ├── ComposerBar.swift           // Input area with attachments
│   │   ├── TypingIndicator.swift       // Animated typing dots
│   │   └── ConversationRow.swift       // List item for conversations
│   ├── ViewModels/
│   │   ├── DirectMessagesViewModel.swift
│   │   └── ConversationViewModel.swift
│   └── Routing/
│       └── DMsEntry.swift              // Public entry point
└── Tests/DirectMessagesTests/
```

### Supporting Infrastructure

**New Messaging Kit** (`Packages/Kits/Messaging/`):
- Implements messaging service protocols
- Handles real-time subscriptions
- Manages media attachments
- Provides local caching and persistence

**Service Protocols** (in `AppFoundation`):
```swift
public protocol MessagingServiceProtocol {
    func createConversation(participantIds: [UUID]) async throws -> Conversation
    func leaveConversation(id: UUID) async throws
    func setMuted(_ muted: Bool, for id: UUID) async throws
    func setArchived(_ archived: Bool, for id: UUID) async throws
    func pin(_ pinned: Bool, for id: UUID) async throws
    func fetchConversations(page: Int, pageSize: Int) async throws -> [Conversation]
    func fetchMessages(conversationId: UUID, before: Date?, limit: Int) async throws -> [Message]
    func send(text: String, in conversationId: UUID) async throws -> Message
    func send(attachment: Attachment, in conversationId: UUID) async throws -> Message
    func markDelivered(conversationId: UUID, messageId: UUID) async throws
    func markReadRange(conversationId: UUID, upTo messageId: UUID) async throws
}

public protocol MessagingRealtimeProtocol {
    func subscribeConversationList() async throws -> MessagingSubscription
    func subscribe(conversationId: UUID) async throws -> MessagingSubscription
    func setTyping(conversationId: UUID, isTyping: Bool) async
    var events: AsyncStream<MessagingEvent> { get }
}

public protocol MessagingMediaProtocol {
    func prepareAttachment(_ pick: MediaPick) async throws -> Attachment
}

public enum MessagingEvent: Sendable {
    case messageAdded(Message)
    case messageUpdated(Message)
    case messageDeleted(UUID, conversationId: UUID)
    case typing(conversationId: UUID, userId: UUID, isTyping: Bool)
    case readReceipt(conversationId: UUID, messageId: UUID, userId: UUID)
    case conversationUpdated(Conversation)
}
```

## Components and Interfaces

### DirectMessagesView (Conversation List)

**Purpose**: Main entry point showing all user conversations
**Key Features**:
- List of conversations with preview, timestamp, unread indicators
- Pull-to-refresh for loading new conversations
- Search functionality for finding specific conversations
- Navigation to individual chat interfaces

**SwiftUI Implementation**:
```swift
struct DirectMessagesView: View {
    @State private var viewModel = DirectMessagesViewModel()
    
    var body: some View {
        NavigationStack {
            List(viewModel.conversations) { conversation in
                ConversationRow(conversation: conversation)
                    .onTapGesture {
                        viewModel.navigate(to: .conversation(conversation.id))
                    }
            }
            .refreshable {
                await viewModel.refresh()
            }
            .navigationTitle("Messages")
        }
    }
}
```

### ConversationView (Chat Interface)

**Purpose**: Individual conversation with message history and composer
**Key Features**:
- Bottom-anchored message list with smooth scrolling
- Auto-scroll to latest message on new message arrival
- Day separators for message grouping
- Typing indicators from other participants
- Keyboard-aware layout adjustments

**SwiftUI Implementation Strategy**:
- `ScrollViewReader` with `LazyVStack` for performance
- `safeAreaInset(edge: .bottom)` for composer positioning
- `scrollPosition(id:)` for maintaining scroll position
- `refreshable` for loading older messages at top

### MessageBubble Component

**Purpose**: Individual message display with sender-appropriate styling
**Design Specifications**:
- Right-aligned blue bubbles for current user messages
- Left-aligned system material bubbles for other users
- Rounded rectangle with continuous corner style (18pt radius)
- Proper spacing and padding for readability
- Support for text, media, and link previews

**Styling Approach**:
```swift
struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.isFromCurrentUser { Spacer(minLength: 48) }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(message.content)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .background(
                        message.isFromCurrentUser ? .blue : .regularMaterial,
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                    )
                    .foregroundStyle(message.isFromCurrentUser ? .white : .primary)
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            
            if !message.isFromCurrentUser { Spacer(minLength: 48) }
        }
        .contextMenu {
            Button("Copy") { /* copy action */ }
            Button("Reply") { /* reply action */ }
            if message.isFromCurrentUser {
                Button("Delete", role: .destructive) { /* delete action */ }
            }
        }
    }
}
```

### ComposerBar Component

**Purpose**: Message input area with text field and attachment options
**Key Features**:
- Growing text input (TextEditor) with height constraints
- Media attachment button using PhotosPicker
- Send button with proper enabled/disabled states
- Keyboard-responsive layout
- Haptic feedback on send

**Implementation Details**:
- Uses `TextEditor` for multi-line support
- `@FocusState` for keyboard management
- Height constraints: min 38pt, max 120pt
- Material background for visual separation

### Real-time Features

**Real-time Architecture**:
- Actor-based `MessagingRealtimeObserver` managing Supabase channels and lifecycle
- Two realtime "lanes":
  - Stateful events via Postgres Changes: messages, edits, deletes, read receipts
  - Ephemeral presence via Broadcast: typing indicators (short-lived, high frequency)
- Server-side filtering using `conversation_id=in.(...)` for efficient subscriptions
- Chunking when conversation sets exceed 100 IDs per channel
- Automatic reconnection with exponential backoff and jitter

**Typing Indicators**:
- Battery-friendly implementation with proper debouncing:
  - Emit at first keystroke after 300ms idle
  - Keepalive refresh every 3s while typing
  - Auto-stop after 4s of inactivity
- Per-participant typing in groups with display caps ("Alice, Bob, +2")
- Ephemeral broadcast channels: `typing:{conversationId}`
- Animated dots using `TimelineView` or `phaseAnimator`

**Message Delivery & Ordering**:
- Authoritative server-side ordering by `created_at` + `id` tiebreaker
- Optimistic UI updates with nonce-based deduplication
- Real-time message arrival with backpressure (coalesce bursts to 60-120ms)
- Delivery status progression: sending → sent → delivered → read
- Failed message retry with visual indicators and user actions

## Data Models

### Core Models

```swift
public struct Conversation: Identifiable, Codable {
    public let id: UUID
    public let participants: [User]
    public let lastMessage: Message?
    public let lastActivity: Date
    public let unreadCount: Int
    public let unreadMentionsCount: Int
    public let isArchived: Bool
    public let isPinned: Bool
    public let isMuted: Bool
    public let lastReadMessageId: UUID?
    public let draftText: String?
    public let isGroup: Bool
    public let title: String?
    public let avatarUrl: URL?
}

public struct Message: Identifiable, Codable {
    public let id: UUID
    public let conversationId: UUID
    public let senderId: UUID
    public let content: String
    public let attachments: [Attachment]
    public let timestamp: Date
    public let deliveryStatus: DeliveryStatus
    public let replyTo: UUID?
    public let nonce: MessageNonce? // Client temp ID for optimistic sends
    public let editedAt: Date?
    public let deletedAt: Date?
    public let expiresAt: Date? // For disappearing messages
    public let systemKind: SystemMessageKind? // join/leave events
    public let linkPreview: LinkPreview?
}

public struct Attachment: Identifiable, Codable {
    public let id: UUID
    public let type: AttachmentType
    public let url: URL
    public let thumbnailUrl: URL?
    public let sizeBytes: Int64
    public let duration: TimeInterval? // For video/audio
    public let metadata: AttachmentMetadata
}

public struct MessageNonce: Hashable, Codable {
    public let value: UUID
}

public struct OutboundMessageDraft: Sendable {
    public let conversationId: UUID
    public let nonce: MessageNonce
    public var text: String
    public var attachments: [Attachment]
}

public enum DeliveryStatus: String, Codable {
    case sending, sent, delivered, read, failed
}

public enum SystemMessageKind: String, Codable {
    case userJoined, userLeft, conversationCreated, titleChanged
}
```

### Local State Management

**ConversationViewModel**:
- Manages message list state and pagination
- Handles real-time subscriptions
- Manages typing state and indicators
- Coordinates with messaging services

**DirectMessagesViewModel**:
- Manages conversation list state
- Handles navigation between views
- Manages search and filtering
- Coordinates refresh operations

## Error Handling

### Network Error Scenarios

**Connection Issues**:
- Graceful degradation when offline
- Retry mechanisms for failed message sends
- Local queuing of outbound messages
- Clear user feedback for network states

**Message Delivery Failures**:
- Visual indicators for failed messages
- Retry options for failed sends
- Fallback to local storage for drafts
- Error messages with actionable guidance

### User Experience Considerations

**Loading States**:
- Skeleton loading for conversation list
- Progressive loading for message history
- Smooth transitions between states
- Proper empty state handling

**Accessibility Support**:
- VoiceOver labels for all interactive elements
- Dynamic Type support throughout
- Reduce Motion preference respect
- Proper focus management

## Testing Strategy

### Unit Testing

**ViewModel Testing**:
- Message sending and receiving logic
- Real-time event handling
- State management and updates
- Error handling scenarios

**Service Testing**:
- API integration with mock responses
- Real-time subscription management
- Media attachment processing
- Local persistence operations

### Integration Testing

**Feature Integration**:
- Navigation between conversation list and chat
- Real-time message flow end-to-end
- Media attachment upload and display
- Keyboard and layout behavior

### UI Testing

**User Interaction Flows**:
- Complete conversation creation and messaging
- Media attachment selection and sending
- Message actions (copy, delete, reply)
- Accessibility compliance verification

## Real-time Implementation Details

### MessagingRealtimeObserver Architecture

**Actor-Based Design**:
```swift
actor MessagingRealtimeObserver {
    struct Config: Sendable {
        let maxIdsPerChannel: Int = 100
        let throttlePerConversationMs: Int = 300
        let scrollDebounceMs: Int = 500
    }
    
    enum Input: Sendable {
        case setVisibleConversations(Set<UUID>)
        case setActiveThread(UUID?)
        case lifecycleForeground
        case lifecycleBackground
        case setTyping(conversationId: UUID, isTyping: Bool)
    }
    
    enum Output: Sendable {
        case messageAdded(Message)
        case messageUpdated(Message)
        case messageDeleted(conversationId: UUID, messageId: UUID)
        case readReceipt(conversationId: UUID, messageId: UUID, userId: UUID)
        case conversationUpdated(Conversation)
        case typing(conversationId: UUID, userId: UUID, isTyping: Bool)
    }
}
```

**Database Schema & Filters**:
- `messages` table: Realtime publication ON, RLS filter by `conversation_id in (...)`
- `read_receipts` table: Realtime publication ON, filter by `conversation_id in (...)`
- `conversations` table: Optional realtime for metadata updates
- `typing` signals: Ephemeral broadcast channels `typing:{conversationId}`

**Channel Management**:
- ≤100 conversations → 1 channel
- 101-300 → 2-3 channels with chunking
- >300 → Pagination encouraged, subscribe only active + recent conversations
- Automatic reconnection with exponential backoff and jitter

### Optimistic Updates & Conflict Resolution

**Message Sending Flow**:
1. Generate client `MessageNonce` for optimistic display
2. Add to local state immediately with `.sending` status
3. Send to server via service protocol
4. Server returns authoritative message with server ID
5. Reconcile optimistic message by `(conversationId, nonce)` matching
6. Update delivery status based on real-time events

**Ordering & Deduplication**:
- Server-side ordering by `created_at` + `id` tiebreaker (never client clock)
- Client deduplication prevents double-display of optimistic sends
- Out-of-order message handling with proper insertion points

## Performance Considerations

### Message List Optimization

**Lazy Loading & Pagination**:
- `LazyVStack` for efficient memory usage with 30 messages per page
- Anchor-aware loading: preserve scroll offset when inserting older messages
- Gap indicators for "Unread" dividers when opening threads
- Memory cap: ~200 message nodes in-memory with LRU eviction

**Real-time Efficiency**:
- Per-conversation throttling (300ms) for burst events
- Debounced visible set changes (500ms) before re-subscribing
- Efficient WebSocket connection management with lifecycle awareness
- Background processing for media uploads with resumable chunks

**Performance Budgets**:
- Image thumbnails: 200-400px longest side in transcript
- Video thumbnails: pre-generated on upload, no main-thread transcoding
- Memory: cap in-memory message views to ~200 nodes
- First paint target: <100ms for conversation list, <200ms for chat interface

### Memory Management & Persistence

**Image & Media Handling**:
- Pre-compress images (max 2048px dimension) before upload
- Video transcoding to H.264/HEVC with target bitrates
- Lazy-load full resolution only on tap
- EXIF orientation handling for proper display

**Local Persistence Strategy**:
- Cache last 200-500 messages per thread with LRU eviction
- Store conversation list with message snippets for instant launch
- Per-conversation draft text persistence (like iMessage)
- Background sync with BGProcessingTask for suspended uploads

**Network & Retry Logic**:
- Outbound message queue with states: .sending → .sent | .failed
- Exponential backoff for failed sends with user retry options
- Resumable media uploads with progress indicators
- Graceful offline degradation with local queuing

## Integration Points

### Navigation Integration

**Route Handling**:
```swift
public enum DMsRoute: Equatable {
    case list
    case conversation(id: UUID)
}
```

**Entry Point**:
```swift
public struct DMsEntry: View {
    let route: DMsRoute
    
    public var body: some View {
        switch route {
        case .list:
            DirectMessagesView()
        case .conversation(let id):
            ConversationView(conversationId: id)
        }
    }
}
```

### Design System Integration

**Component Usage**:
- AgoraButton for primary actions
- Design system colors and typography
- Consistent spacing and layout patterns
- Material backgrounds and effects

**Theme Support**:
- Dark mode compatibility
- Dynamic color adaptation
- Consistent visual hierarchy
- Accessibility color contrast

### Analytics Integration

**Event Tracking**:
- `dm_open_list` - Conversation list opened
- `dm_open_conversation` - Individual chat opened  
- `dm_send` - Message sent successfully
- `dm_receive` - Message received
- `dm_typing_start/stop` - Typing indicator events
- `dm_read` - Message marked as read
- `dm_media_upload` - Media attachment uploaded
- `dm_conversation_created` - New conversation started

**Privacy & Security**:
- No message content or attachment URLs in analytics
- RLS policies restrict message visibility to participants only
- Typing broadcast channels secured with conversation membership validation
- User consent for usage tracking with minimal data collection
- Built-in abuse reporting: `reportMessage(id:)` and `block(userId:)` in service protocol

**Notifications Integration**:
- OneSignal integration with thread-specific categories
- Collapse keys per conversation to prevent spam
- Deep linking to `DMsRoute.conversation(id:)`
- Respect muted/archived status in server notification rules