//
//  UsageExamples.swift
//  SupabaseKit
//
//  Examples showing how SupabaseKit improves the architecture
//

import Foundation

/// Examples demonstrating how SupabaseKit improves the app architecture
public struct SupabaseKitExamples {
    
    // MARK: - Before vs After Comparison
    
    /// BEFORE: Direct Supabase usage (tightly coupled)
    /// Problems:
    /// - Hard to test (can't mock Supabase)
    /// - Tightly coupled to Supabase SDK
    /// - Type-erased in Dependencies
    /// - Other modules can't use Supabase without AppFoundation
    public static func beforeExample() {
        /*
        // In AppFoundation (before):
        import Supabase
        
        class SomeService {
            private let supabase: SupabaseClient
            
            init() {
                self.supabase = SupabaseClient(url: url, key: key)
            }
            
            func doSomething() {
                // Direct Supabase usage - hard to test
                supabase.auth.signInWithApple(...)
                supabase.realtime.subscribe(...)
            }
        }
        
        // In Dependencies (before):
        public let supabase: (any Sendable)? // Type-erased!
        */
    }
    
    /// AFTER: SupabaseKit usage (clean architecture)
    /// Benefits:
    /// - Easy to test (protocol-based)
    /// - Decoupled from Supabase SDK
    /// - Type-safe in Dependencies
    /// - Any module can use SupabaseKit directly
    public static func afterExample() {
        /*
        // In any module (after):
        import SupabaseKit
        
        class SomeService {
            private let supabase: any SupabaseClientProtocol
            
            init(supabase: any SupabaseClientProtocol) {
                self.supabase = supabase
            }
            
            func doSomething() async {
                // Clean, testable interface
                let session = try await supabase.auth.signInWithApple(...)
                let updates = supabase.realtime.subscribeToPostEngagement(...)
            }
        }
        
        // In Dependencies (after):
        public let supabase: (any SupabaseClientProtocol)? // Type-safe!
        */
    }
    
    // MARK: - Real Usage Examples
    
    /// Example: Engagement Kit using SupabaseKit for realtime updates
    public static func engagementRealtimeExample() {
        /*
        // In Engagement Kit:
        import SupabaseKit
        
        class EngagementServiceLive {
            private let supabase: any SupabaseClientProtocol
            
            init(supabase: any SupabaseClientProtocol) {
                self.supabase = supabase
            }
            
            func startListeningToEngagementUpdates() {
                Task {
                    for await update in supabase.realtime.subscribeToPostEngagement(postId: "123") {
                        // Handle realtime engagement updates
                        await updateEngagementState(update)
                    }
                }
            }
        }
        */
    }
    
    /// Example: Media Kit using SupabaseKit for file uploads
    public static func mediaUploadExample() {
        /*
        // In Media Kit:
        import SupabaseKit
        
        class MediaServiceLive {
            private let supabase: any SupabaseClientProtocol
            
            init(supabase: any SupabaseClientProtocol) {
                self.supabase = supabase
            }
            
            func uploadImage(_ data: Data) async throws -> URL {
                let path = "images/\(UUID().uuidString).jpg"
                return try await supabase.storage.uploadImage(data: data, path: path)
            }
        }
        */
    }
    
    /// Example: Notifications Kit using SupabaseKit for realtime notifications
    public static func notificationsExample() {
        /*
        // In Notifications Kit:
        import SupabaseKit
        
        class NotificationsServiceLive {
            private let supabase: any SupabaseClientProtocol
            
            init(supabase: any SupabaseClientProtocol) {
                self.supabase = supabase
            }
            
            func startListeningToNotifications() {
                Task {
                    for await notification in supabase.realtime.subscribeToUserNotifications(userId: "user123") {
                        // Handle realtime notifications
                        await showNotification(notification)
                    }
                }
            }
        }
        */
    }
    
    /// Example: Testing with mock SupabaseKit
    public static func testingExample() {
        /*
        // In tests:
        import SupabaseKit
        
        func testEngagementService() async {
            // Create mock Supabase client
            let mockSupabase = SupabaseClientMock(
                realtime: SupabaseRealtimeMock(
                    mockEngagementUpdates: [
                        EngagementUpdate(
                            postId: "123",
                            likeCount: 5,
                            repostCount: 2,
                            replyCount: 1,
                            isLiked: true,
                            isReposted: false
                        )
                    ]
                )
            )
            
            // Test with mock
            let service = EngagementServiceLive(supabase: mockSupabase)
            // ... test implementation
        }
        */
    }
}

// MARK: - Architecture Benefits Summary

/*
 
 ## How SupabaseKit Improves the Architecture
 
 ### 1. **Decoupled Architecture**
 BEFORE: AppFoundation → supabase-swift (direct)
 AFTER:  AppFoundation → SupabaseKit → supabase-swift
         Other modules → SupabaseKit (direct, clean)
 
 ### 2. **Better Testing**
 BEFORE: Hard to mock Supabase SDK
 AFTER:  Easy to mock with SupabaseClientMock
 
 ### 3. **Type Safety**
 BEFORE: `supabase: (any Sendable)?` (type-erased)
 AFTER:  `supabase: (any SupabaseClientProtocol)?` (type-safe)
 
 ### 4. **Reusability**
 BEFORE: Only AppFoundation can use Supabase
 AFTER:  Any module can import and use SupabaseKit
 
 ### 5. **Cleaner Dependencies**
 BEFORE: Modules need AppFoundation to use Supabase
 AFTER:  Modules can depend directly on SupabaseKit
 
 ### 6. **Protocol-Based Design**
 - Easy to swap implementations
 - Better dependency injection
 - Cleaner interfaces
 - More testable code
 
 */
