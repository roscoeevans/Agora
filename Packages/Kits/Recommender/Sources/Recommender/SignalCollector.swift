import Foundation
import Analytics

/// User interaction signals for recommendation
public enum InteractionSignal: Sendable {
    case view(postId: String, dwellTime: TimeInterval)
    case like(postId: String)
    case unlike(postId: String)
    case repost(postId: String)
    case skip(postId: String, reason: SkipReason)
    case share(postId: String, method: String)
    case profileView(userId: String, dwellTime: TimeInterval)
    case follow(userId: String)
    case unfollow(userId: String)
    case report(postId: String, reason: String)
    case hide(postId: String, reason: String)
}

/// Reasons for skipping content
public enum SkipReason: String, CaseIterable, Sendable {
    case notInterested = "not_interested"
    case tooSimilar = "too_similar"
    case inappropriate = "inappropriate"
    case spam = "spam"
    case fastScroll = "fast_scroll"
    case lowQuality = "low_quality"
}

/// Signal metadata for context
public struct SignalMetadata: Sendable {
    public let timestamp: Date
    public let sessionId: String
    public let feedPosition: Int?
    public let feedType: String
    public let deviceContext: DeviceContext
    
    public init(
        sessionId: String,
        feedPosition: Int? = nil,
        feedType: String = "for_you",
        deviceContext: DeviceContext = DeviceContext()
    ) {
        self.timestamp = Date()
        self.sessionId = sessionId
        self.feedPosition = feedPosition
        self.feedType = feedType
        self.deviceContext = deviceContext
    }
}

/// Device context for signals
public struct DeviceContext: Sendable {
    public let batteryLevel: Float?
    public let isLowPowerMode: Bool
    public let networkType: String
    public let timeOfDay: String
    
    public init() {
        #if os(iOS)
        self.batteryLevel = UIDevice.current.batteryLevel >= 0 ? UIDevice.current.batteryLevel : nil
        #else
        self.batteryLevel = nil
        #endif
        self.isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
        self.networkType = "unknown" // TODO: Detect actual network type
        
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12:
            self.timeOfDay = "morning"
        case 12..<17:
            self.timeOfDay = "afternoon"
        case 17..<21:
            self.timeOfDay = "evening"
        default:
            self.timeOfDay = "night"
        }
    }
}

/// Collected signal with metadata
public struct CollectedSignal: Sendable {
    public let signal: InteractionSignal
    public let metadata: SignalMetadata
    
    public init(signal: InteractionSignal, metadata: SignalMetadata) {
        self.signal = signal
        self.metadata = metadata
    }
}

/// Signal collector for user interaction tracking
/// 
/// Follows DI rule: explicit dependency injection, no singletons
public final class SignalCollector: Sendable {
    private let eventTracker: EventTracker
    private let sessionId: String
    
    /// Initialize with explicit event tracker dependency
    public init(eventTracker: EventTracker) {
        self.eventTracker = eventTracker
        self.sessionId = UUID().uuidString
    }
    
    /// Collects an interaction signal
    public func collectSignal(
        _ signal: InteractionSignal,
        feedPosition: Int? = nil,
        feedType: String = "for_you"
    ) {
        let metadata = SignalMetadata(
            sessionId: sessionId,
            feedPosition: feedPosition,
            feedType: feedType
        )
        
        let collectedSignal = CollectedSignal(signal: signal, metadata: metadata)
        
        // Track analytics event
        trackAnalyticsEvent(for: collectedSignal)
        
        // TODO: Send to recommendation service
        sendToRecommendationService(collectedSignal)
    }
    
    /// Tracks post view with dwell time
    public func trackPostView(postId: String, dwellTime: TimeInterval, feedPosition: Int? = nil) {
        collectSignal(.view(postId: postId, dwellTime: dwellTime), feedPosition: feedPosition)
    }
    
    /// Tracks post like
    public func trackPostLike(postId: String, feedPosition: Int? = nil) {
        collectSignal(.like(postId: postId), feedPosition: feedPosition)
    }
    
    /// Tracks post unlike
    public func trackPostUnlike(postId: String, feedPosition: Int? = nil) {
        collectSignal(.unlike(postId: postId), feedPosition: feedPosition)
    }
    
    /// Tracks post repost
    public func trackPostRepost(postId: String, feedPosition: Int? = nil) {
        collectSignal(.repost(postId: postId), feedPosition: feedPosition)
    }
    
    /// Tracks post skip
    public func trackPostSkip(postId: String, reason: SkipReason, feedPosition: Int? = nil) {
        collectSignal(.skip(postId: postId, reason: reason), feedPosition: feedPosition)
    }
    
    /// Tracks post share
    public func trackPostShare(postId: String, method: String, feedPosition: Int? = nil) {
        collectSignal(.share(postId: postId, method: method), feedPosition: feedPosition)
    }
    
    /// Tracks profile view
    public func trackProfileView(userId: String, dwellTime: TimeInterval) {
        collectSignal(.profileView(userId: userId, dwellTime: dwellTime))
    }
    
    /// Tracks user follow
    public func trackUserFollow(userId: String) {
        collectSignal(.follow(userId: userId))
    }
    
    /// Tracks user unfollow
    public func trackUserUnfollow(userId: String) {
        collectSignal(.unfollow(userId: userId))
    }
    
    /// Tracks content report
    public func trackContentReport(postId: String, reason: String, feedPosition: Int? = nil) {
        collectSignal(.report(postId: postId, reason: reason), feedPosition: feedPosition)
    }
    
    /// Tracks content hide
    public func trackContentHide(postId: String, reason: String, feedPosition: Int? = nil) {
        collectSignal(.hide(postId: postId, reason: reason), feedPosition: feedPosition)
    }
    
    // MARK: - Private Methods
    
    private func trackAnalyticsEvent(for collectedSignal: CollectedSignal) {
        Task { @MainActor in
            switch collectedSignal.signal {
            case .view(let postId, let dwellTime):
                await eventTracker.track(.postViewed(postId: postId, dwellTime: dwellTime))
                
            case .like(let postId):
                await eventTracker.track(.postLiked(postId: postId))
                
            case .unlike(let postId):
                await eventTracker.track(.postUnliked(postId: postId))
                
            case .repost(let postId):
                await eventTracker.track(.postReposted(postId: postId))
                
            case .skip(let postId, let reason):
                await eventTracker.track(event: "post_skipped", properties: [
                    "post_id": postId,
                    "reason": reason.rawValue,
                    "feed_position": collectedSignal.metadata.feedPosition ?? -1
                ])
                
            case .share(let postId, let method):
                await eventTracker.track(event: "post_shared", properties: [
                    "post_id": postId,
                    "method": method,
                    "feed_position": collectedSignal.metadata.feedPosition ?? -1
                ])
                
            case .profileView(let userId, let dwellTime):
                await eventTracker.track(event: "profile_viewed", properties: [
                    "user_id": userId,
                    "dwell_time": dwellTime
                ])
                
            case .follow(let userId):
                await eventTracker.track(event: "user_followed", properties: [
                    "user_id": userId
                ])
                
            case .unfollow(let userId):
                await eventTracker.track(event: "user_unfollowed", properties: [
                    "user_id": userId
                ])
                
            case .report(let postId, let reason):
                await eventTracker.track(event: "content_reported", properties: [
                    "post_id": postId,
                    "reason": reason
                ])
                
            case .hide(let postId, let reason):
                await eventTracker.track(event: "content_hidden", properties: [
                    "post_id": postId,
                    "reason": reason
                ])
            }
        }
    }
    
    private func sendToRecommendationService(_ signal: CollectedSignal) {
        // TODO: Send signal to recommendation service
        // This would typically be a background task that batches signals
        print("Signal collected: \(signal)")
    }
}

// MARK: - UIDevice Extension

#if os(iOS)
import UIKit

private extension UIDevice {
    var batteryLevel: Float {
        isBatteryMonitoringEnabled = true
        defer { isBatteryMonitoringEnabled = false }
        return batteryLevel
    }
}
#endif