# Messaging Kit

The Messaging Kit provides real-time messaging functionality for the Agora app, including conversation management, message sending/receiving, and real-time subscriptions.

## Features

- **Conversation Management**: Create, manage, and organize conversations
- **Real-time Messaging**: Send and receive messages with real-time updates
- **Media Attachments**: Support for images, videos, and other media
- **Typing Indicators**: Real-time typing status updates
- **Message Status**: Delivery and read receipts
- **Optimistic Updates**: Immediate UI updates with server reconciliation

## Architecture

The kit follows a protocol-based architecture with three main service protocols:

- `MessagingServiceProtocol`: Core CRUD operations for conversations and messages
- `MessagingRealtimeProtocol`: Real-time subscriptions and events
- `MessagingMediaProtocol`: Media attachment preparation and handling

## Key Components

- `MessagingServiceLive`: Production implementation of messaging operations
- `MessagingRealtimeLive`: Real-time subscription management
- `MessagingRealtimeObserver`: Actor-based real-time event processing
- `MessagingMediaLive`: Media attachment processing

## Usage

```swift
// Initialize messaging services
let messagingService = MessagingServiceLive(networking: networking)
let realtimeService = MessagingRealtimeLive(observer: observer)

// Send a message
let message = try await messagingService.send(
    text: "Hello!",
    in: conversationId
)

// Subscribe to real-time updates
let subscription = try await realtimeService.subscribe(conversationId: conversationId)
```