//
//  CommentViewModel.swift
//  Agora
//
//  Created by Agora Team on 2024.
//

import Foundation
import AppFoundation
import Networking
import Verification

// Note: AgoraAPIClient protocol comes from Networking kit
// Note: AppAttestManager comes from Verification kit

@MainActor
@Observable
final class CommentViewModel {
    // MARK: - Published State
    var text: String = ""
    var isPosting: Bool = false
    var error: Error?
    
    // MARK: - Dependencies
    private let post: Post
    private let replyToCommentId: String?
    private let networking: any AgoraAPIClient
    private let verificationManager: AppAttestManager
    
    // MARK: - Computed Properties
    var characterCount: Int {
        text.count
    }
    
    var isOverLimit: Bool {
        characterCount > 280
    }
    
    var canPost: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && !isOverLimit
        && !isPosting
    }
    
    // MARK: - Initialization
    init(
        post: Post,
        replyToCommentId: String? = nil,
        networking: any AgoraAPIClient,
        verificationManager: AppAttestManager
    ) {
        self.post = post
        self.replyToCommentId = replyToCommentId
        self.networking = networking
        self.verificationManager = verificationManager
    }
    
    // MARK: - Actions
    func postComment() async {
        guard canPost else { return }
        
        isPosting = true
        error = nil
        
        do {
            // TODO: Fix attestation and auth token provider APIs
            // Generate device attestation
            // let attestation = try await verificationManager.generateAttestation()
            
            // Create the reply via Edge Function
            let request = CreateReplyRequest(
                parentPostId: post.id,
                replyToCommentId: replyToCommentId,
                text: text,
                attestation: "" // TODO: Use real attestation
            )
            
            // Create reply via direct HTTP call (similar to createPost)
            // guard let token = try? await networking.authTokenProvider?.currentAccessToken() else {
            //     throw NSError(domain: "com.agora", code: 401, userInfo: [NSLocalizedDescriptionKey: "Authentication required"])
            // }
            
            var urlRequest = URLRequest(url: AppConfig.apiBaseURL.appending(path: "/create-reply"))
            urlRequest.httpMethod = "POST"
            // urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.setValue(AppConfig.supabaseAnonKey, forHTTPHeaderField: "apikey")
            
            let encoder = JSONEncoder()
            urlRequest.httpBody = try encoder.encode(request)
            
            let (_, response) = try await URLSession.shared.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 else {
                throw NSError(domain: "com.agora", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to create reply"])
            }
            
            // Success - dismiss handled by parent view
        } catch {
            self.error = error
        }
        
        isPosting = false
    }
}

// MARK: - Request/Response Models
struct CreateReplyRequest: Codable {
    let parentPostId: String
    let replyToCommentId: String?
    let text: String
    let attestation: String
}

