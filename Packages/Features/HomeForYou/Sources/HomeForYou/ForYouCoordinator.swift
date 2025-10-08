//
//  ForYouCoordinator.swift
//  Agora
//
//  Created by Agora Team on 2024.
//

import SwiftUI
import Analytics

@MainActor
@Observable
public class ForYouCoordinator {
    public var navigationPath = NavigationPath()
    
    private let analytics: AnalyticsManager
    
    public init(analytics: AnalyticsManager = AnalyticsManager.shared) {
        self.analytics = analytics
    }
    
    public func navigateToPost(_ post: Post) {
        analytics.track(event: "post_tapped", properties: [
            "post_id": post.id,
            "source": "for_you_feed"
        ])
        
        // TODO: Implement navigation to post detail
        // navigationPath.append(PostDetailDestination(postId: post.id))
    }
    
    public func navigateToProfile(_ userId: String) {
        analytics.track(event: "profile_tapped", properties: [
            "user_id": userId,
            "source": "for_you_feed"
        ])
        
        // TODO: Implement navigation to profile
        // navigationPath.append(ProfileDestination(userId: userId))
    }
    
    public func popToRoot() {
        navigationPath.removeLast(navigationPath.count)
    }
}

// MARK: - Navigation Destinations (for future use)
public enum ForYouDestination: Hashable {
    case postDetail(postId: String)
    case profile(userId: String)
}
