//
//  PostDetailViewModel.swift
//  Agora
//
//  Created by Agora Team on 2024.
//

import Foundation
import SwiftUI
import Networking
import AppFoundation

// Note: AgoraAPIClient protocol comes from Networking kit

@MainActor
@Observable
public class PostDetailViewModel {
    public var post: Post?
    public var replies: [Post] = []
    public var isLoading = false
    public var isLoadingReplies = false
    public var error: Error?
    
    private let postId: String
    private let networking: any AgoraAPIClient
    
    /// Initialize PostDetailViewModel with explicit dependencies
    /// Following the DI rule pattern
    public init(postId: String, networking: any AgoraAPIClient) {
        self.postId = postId
        self.networking = networking
    }
    
    public func loadPost() async {
        isLoading = true
        error = nil
        
        // Load post and replies in parallel
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.fetchPost()
            }
            group.addTask {
                await self.fetchReplies()
            }
        }
        
        isLoading = false
    }
    
    public func refresh() async {
        await loadPost()
    }
    
    private func fetchPost() async {
        do {
            // TODO: Implement actual post fetch API call
            // For now using placeholder
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second
            post = Post(
                id: postId,
                authorId: "sample-author-id",
                authorDisplayHandle: "sample.author",
                text: "This is a detailed view of a post. You can see the full content and all replies here.",
                replyCount: 0,
                createdAt: Date().addingTimeInterval(-3600),
                authorDisplayName: "Sample Author"
            )
        } catch {
            self.error = error
        }
    }
    
    private func fetchReplies() async {
        isLoadingReplies = true
        defer { isLoadingReplies = false }
        
        do {
            struct RepliesResponse: Codable {
                let replies: [PostResponse]
            }
            
            struct PostResponse: Codable {
                let id: String
                let text: String
                let author_id: String
                let author_display_handle: String
                let author_display_name: String?
                let author_avatar_url: String?
                let created_at: String
                let like_count: Int
                let repost_count: Int
                let reply_count: Int
                let is_liked_by_viewer: Bool
                let is_reposted_by_viewer: Bool
            }
            
            // Fetch replies via direct HTTP call  
            var components = URLComponents(url: AppConfig.apiBaseURL.appending(path: "/get-replies"), resolvingAgainstBaseURL: false)!
            components.queryItems = [URLQueryItem(name: "postId", value: postId)]
            
            var urlRequest = URLRequest(url: components.url!)
            // TODO: Fix auth token provider API
            // if let token = try? await networking.authTokenProvider?.currentAccessToken() {
            //     urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            // }
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.setValue(AppConfig.supabaseAnonKey, forHTTPHeaderField: "apikey")
            
            let (data, _) = try await URLSession.shared.data(for: urlRequest)
            
            let decoder = JSONDecoder()
            let response = try decoder.decode(RepliesResponse.self, from: data)
            
            // Convert API response to Post models
            let dateFormatter = ISO8601DateFormatter()
            replies = response.replies.compactMap { reply in
                guard let createdAt = dateFormatter.date(from: reply.created_at) else {
                    return nil
                }
                
                return Post(
                    id: reply.id,
                    authorId: reply.author_id,
                    authorDisplayHandle: reply.author_display_handle,
                    text: reply.text,
                    replyToPostId: postId,
                    likeCount: reply.like_count,
                    repostCount: reply.repost_count,
                    replyCount: reply.reply_count,
                    createdAt: createdAt,
                    authorDisplayName: reply.author_display_name,
                    authorAvatarUrl: reply.author_avatar_url,
                    isLikedByViewer: reply.is_liked_by_viewer,
                    isRepostedByViewer: reply.is_reposted_by_viewer
                )
            }
            
            // Update post's reply count
            if let currentPost = post {
                post = Post(
                    id: currentPost.id,
                    authorId: currentPost.authorId,
                    authorDisplayHandle: currentPost.authorDisplayHandle,
                    text: currentPost.text,
                    linkUrl: currentPost.linkUrl,
                    mediaBundleId: currentPost.mediaBundleId,
                    replyToPostId: currentPost.replyToPostId,
                    quotePostId: currentPost.quotePostId,
                    likeCount: currentPost.likeCount,
                    repostCount: currentPost.repostCount,
                    replyCount: replies.count,
                    visibility: currentPost.visibility,
                    createdAt: currentPost.createdAt,
                    authorDisplayName: currentPost.authorDisplayName,
                    authorAvatarUrl: currentPost.authorAvatarUrl,
                    editedAt: currentPost.editedAt,
                    selfDestructAt: currentPost.selfDestructAt,
                    score: currentPost.score,
                    reasons: currentPost.reasons,
                    explore: currentPost.explore,
                    isLikedByViewer: currentPost.isLikedByViewer,
                    isRepostedByViewer: currentPost.isRepostedByViewer
                )
            }
        } catch {
            self.error = error
            print("Error fetching replies: \(error)")
        }
    }
}