import Foundation

/// Type-safe event definitions
public enum AnalyticsEvent {
    // User events
    case userSignedIn(method: String)
    case userSignedOut
    case userProfileUpdated
    
    // Post events
    case postCreated(characterCount: Int, hasMedia: Bool)
    case postLiked(postId: String)
    case postUnliked(postId: String)
    case postReposted(postId: String)
    case postViewed(postId: String, dwellTime: TimeInterval)
    
    // Feed events
    case feedRefreshed(feedType: String)
    case feedScrolled(direction: String, distance: Double)
    
    // Navigation events
    case screenViewed(screenName: String)
    case tabSwitched(fromTab: String, toTab: String)
    
    // Search events
    case searchPerformed(query: String, resultCount: Int)
    case searchResultTapped(query: String, resultType: String)
    
    // Media events
    case mediaUploaded(type: String, size: Int64, duration: TimeInterval?)
    case mediaProcessed(type: String, originalSize: Int64, compressedSize: Int64)
    
    // Error events
    case errorOccurred(error: String, context: String)
    case networkError(statusCode: Int, endpoint: String)
    
    // Skeleton loading events
    case firstContentfulRow(feedType: String, rowIndex: Int, elapsedTimeMs: Int)
    case timeToInteractive(feedType: String, totalRows: Int, elapsedTimeMs: Int)
    case skeletonError(feedType: String, error: String, context: String, retryCount: Int)
    case skeletonFPSDrop(currentFPS: Double, threshold: Double)
    case skeletonMemoryThreshold(memoryUsageMB: Int64, thresholdMB: Int)
    
    // Direct messaging events
    case dmOpenList
    case dmOpenConversation(conversationId: String)
    case dmSend(hasMedia: Bool, characterCount: Int)
    case dmReceive
    case dmTypingStart(conversationId: String)
    case dmTypingStop(conversationId: String)
    case dmRead(conversationId: String, messageCount: Int)
    case dmMediaUpload(type: String, sizeBytes: Int64)
    case dmConversationCreated(participantCount: Int)
    
    /// Event name for tracking
    public var name: String {
        switch self {
        case .userSignedIn: return "user_signed_in"
        case .userSignedOut: return "user_signed_out"
        case .userProfileUpdated: return "user_profile_updated"
        case .postCreated: return "post_created"
        case .postLiked: return "post_liked"
        case .postUnliked: return "post_unliked"
        case .postReposted: return "post_reposted"
        case .postViewed: return "post_viewed"
        case .feedRefreshed: return "feed_refreshed"
        case .feedScrolled: return "feed_scrolled"
        case .screenViewed: return "screen_viewed"
        case .tabSwitched: return "tab_switched"
        case .searchPerformed: return "search_performed"
        case .searchResultTapped: return "search_result_tapped"
        case .mediaUploaded: return "media_uploaded"
        case .mediaProcessed: return "media_processed"
        case .errorOccurred: return "error_occurred"
        case .networkError: return "network_error"
        case .firstContentfulRow: return "first_contentful_row"
        case .timeToInteractive: return "time_to_interactive"
        case .skeletonError: return "skeleton_error"
        case .skeletonFPSDrop: return "skeleton_fps_drop"
        case .skeletonMemoryThreshold: return "skeleton_memory_threshold"
        case .dmOpenList: return "dm_open_list"
        case .dmOpenConversation: return "dm_open_conversation"
        case .dmSend: return "dm_send"
        case .dmReceive: return "dm_receive"
        case .dmTypingStart: return "dm_typing_start"
        case .dmTypingStop: return "dm_typing_stop"
        case .dmRead: return "dm_read"
        case .dmMediaUpload: return "dm_media_upload"
        case .dmConversationCreated: return "dm_conversation_created"
        }
    }
    
    /// Event properties
    public var properties: EventProperties {
        switch self {
        case .userSignedIn(let method):
            return ["method": method]
        case .userSignedOut:
            return [:]
        case .userProfileUpdated:
            return [:]
        case .postCreated(let characterCount, let hasMedia):
            return ["character_count": characterCount, "has_media": hasMedia]
        case .postLiked(let postId):
            return ["post_id": postId]
        case .postUnliked(let postId):
            return ["post_id": postId]
        case .postReposted(let postId):
            return ["post_id": postId]
        case .postViewed(let postId, let dwellTime):
            return ["post_id": postId, "dwell_time": dwellTime]
        case .feedRefreshed(let feedType):
            return ["feed_type": feedType]
        case .feedScrolled(let direction, let distance):
            return ["direction": direction, "distance": distance]
        case .screenViewed(let screenName):
            return ["screen_name": screenName]
        case .tabSwitched(let fromTab, let toTab):
            return ["from_tab": fromTab, "to_tab": toTab]
        case .searchPerformed(let query, let resultCount):
            return ["query": query, "result_count": resultCount]
        case .searchResultTapped(let query, let resultType):
            return ["query": query, "result_type": resultType]
        case .mediaUploaded(let type, let size, let duration):
            var props: EventProperties = ["type": type, "size": size]
            if let duration = duration {
                props["duration"] = duration
            }
            return props
        case .mediaProcessed(let type, let originalSize, let compressedSize):
            return [
                "type": type,
                "original_size": originalSize,
                "compressed_size": compressedSize,
                "compression_ratio": Double(compressedSize) / Double(originalSize)
            ]
        case .errorOccurred(let error, let context):
            return ["error": error, "context": context]
        case .networkError(let statusCode, let endpoint):
            return ["status_code": statusCode, "endpoint": endpoint]
        case .firstContentfulRow(let feedType, let rowIndex, let elapsedTimeMs):
            return ["feed_type": feedType, "row_index": rowIndex, "elapsed_time_ms": elapsedTimeMs]
        case .timeToInteractive(let feedType, let totalRows, let elapsedTimeMs):
            return ["feed_type": feedType, "total_rows": totalRows, "elapsed_time_ms": elapsedTimeMs]
        case .skeletonError(let feedType, let error, let context, let retryCount):
            return ["feed_type": feedType, "error": error, "context": context, "retry_count": retryCount]
        case .skeletonFPSDrop(let currentFPS, let threshold):
            return ["current_fps": currentFPS, "threshold": threshold]
        case .skeletonMemoryThreshold(let memoryUsageMB, let thresholdMB):
            return ["memory_usage_mb": memoryUsageMB, "threshold_mb": thresholdMB]
        case .dmOpenList:
            return [:]
        case .dmOpenConversation(let conversationId):
            return ["conversation_id": conversationId]
        case .dmSend(let hasMedia, let characterCount):
            return ["has_media": hasMedia, "character_count": characterCount]
        case .dmReceive:
            return [:]
        case .dmTypingStart(let conversationId):
            return ["conversation_id": conversationId]
        case .dmTypingStop(let conversationId):
            return ["conversation_id": conversationId]
        case .dmRead(let conversationId, let messageCount):
            return ["conversation_id": conversationId, "message_count": messageCount]
        case .dmMediaUpload(let type, let sizeBytes):
            return ["type": type, "size_bytes": sizeBytes]
        case .dmConversationCreated(let participantCount):
            return ["participant_count": participantCount]
        }
    }
}

/// Type-safe event tracker
/// 
/// Provides a higher-level API for tracking type-safe analytics events.
/// This is a feature-scoped helper that wraps AnalyticsClient.
/// 
/// Not marked @MainActor as analytics tracking can happen from any context.
public final class EventTracker: Sendable {
    private let analyticsClient: AnalyticsClient
    
    /// Initialize with explicit analytics client dependency
    /// Following the DI rule: no singletons, explicit injection
    public init(analyticsClient: AnalyticsClient) {
        self.analyticsClient = analyticsClient
    }
    
    /// Tracks a type-safe analytics event
    public func track(_ event: AnalyticsEvent) async {
        // Copy properties to ensure Sendable safety
        // Analytics properties are typically simple value types (String, Int, Bool)
        let properties = event.properties
        await analyticsClient.track(event: event.name, properties: properties)
    }
    
    /// Tracks a custom event with properties
    public func track(event: String, properties: EventProperties = [:]) async {
        await analyticsClient.track(event: event, properties: properties)
    }
    
    /// Tracks screen view with automatic timing
    public func trackScreenView(_ screenName: String) async {
        await track(.screenViewed(screenName: screenName))
    }
    
    /// Tracks error with context
    public func trackError(_ error: Error, context: String = "") async {
        let errorDescription = error.localizedDescription
        await track(.errorOccurred(error: errorDescription, context: context))
    }
}