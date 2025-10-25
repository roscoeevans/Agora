import Foundation
import AppFoundation
import Media
import SupabaseKit

// MARK: - Public Exports

// The protocols and data models are already defined in AppFoundation
// We just need to import them and provide factory methods

// MARK: - Factory Methods

/// Creates a complete messaging service stack with live implementations
/// - Parameters:
///   - networking: API client for network operations
///   - supabase: Supabase client for real-time and database operations
/// - Returns: Tuple containing all messaging services
public func createMessagingServices(
    networking: any AgoraAPIClient,
    supabase: any SupabaseClientProtocol
) -> (
    messaging: MessagingServiceProtocol,
    realtime: MessagingRealtimeProtocol,
    media: MessagingMediaProtocol
) {
    // Create the real-time observer
    let observer = MessagingRealtimeObserver(supabase: supabase)
    
    // Create service implementations
    let messaging = MessagingServiceLive(networking: networking, supabase: supabase)
    let realtime = MessagingRealtimeLive(observer: observer)
    let media = MessagingMediaLive(supabase: supabase)
    
    return (messaging: messaging, realtime: realtime, media: media)
}

/// Creates a messaging service stack with mock implementations for testing
/// - Returns: Tuple containing mock messaging services
public func createMockMessagingServices() -> (
    messaging: MessagingServiceProtocol,
    realtime: MessagingRealtimeProtocol,
    media: MessagingMediaProtocol
) {
    return (
        messaging: NoOpMessagingService(),
        realtime: NoOpMessagingRealtimeService(),
        media: NoOpMessagingMediaService()
    )
}