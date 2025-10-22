//
//  CommentCompositionService.swift
//  PostDetail
//
//  Created by Agora Team on 2024.
//

import SwiftUI
import AppFoundation

/// Implementation of CommentCompositionProtocol for PostDetail
public struct CommentCompositionService: CommentCompositionProtocol {
    public init() {}
    
    public func createCommentSheet(
        for post: Post,
        replyToCommentId: String?,
        replyToUsername: String?
    ) -> AnyView {
        AnyView(
            CommentSheetWrapper(
                post: post,
                replyToCommentId: replyToCommentId,
                replyToUsername: replyToUsername
            )
        )
    }
}

@MainActor
private struct CommentSheetWrapper: View {
    let post: Post
    let replyToCommentId: String?
    let replyToUsername: String?
    
    var body: some View {
        CommentSheet(
            post: post,
            replyToCommentId: replyToCommentId,
            replyToUsername: replyToUsername
        )
    }
}
