//
//  CommentSheet.swift
//  DesignSystem
//
//  TikTok-style comment sheet for viewing and adding comments
//

import SwiftUI
import AppFoundation

/// TikTok-style comment sheet for viewing and adding comments
/// Displays as a bottom sheet with drag-to-dismiss
public struct CommentSheet: View {
    let post: Post
    let onDismiss: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    public init(post: Post, onDismiss: @escaping () -> Void) {
        self.post = post
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("\(post.replyCount) \(post.replyCount == 1 ? "comment" : "comments")")
                        .font(TypographyScale.headline)
                        .foregroundColor(ColorTokens.primaryText)
                    
                    Spacer()
                    
                    Button(action: {
                        onDismiss()
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(ColorTokens.tertiaryText)
                    }
                }
                .padding(SpacingTokens.md)
                .background(.ultraThinMaterial)
                
                Divider()
                
                // Comments list (placeholder)
                ScrollView {
                    VStack(spacing: SpacingTokens.lg) {
                        Spacer()
                            .frame(height: 60)
                        
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 48))
                            .foregroundColor(ColorTokens.tertiaryText)
                        
                        Text("Comments coming soon")
                            .font(TypographyScale.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(ColorTokens.primaryText)
                        
                        Text("We're building a thoughtful\nconversation experience")
                            .font(TypographyScale.body)
                            .foregroundColor(ColorTokens.secondaryText)
                            .multilineTextAlignment(.center)
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                }
                
                Divider()
                
                // Comment input (disabled placeholder)
                HStack(spacing: SpacingTokens.sm) {
                    Circle()
                        .fill(ColorTokens.separator.opacity(0.3))
                        .frame(width: 32, height: 32)
                        .overlay {
                            Image(systemName: "person.fill")
                                .foregroundColor(ColorTokens.tertiaryText)
                                .font(.system(size: 14))
                        }
                    
                    Text("Add a comment...")
                        .font(TypographyScale.body)
                        .foregroundColor(ColorTokens.tertiaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(SpacingTokens.sm)
                        .background(ColorTokens.secondaryBackground)
                        .cornerRadius(SpacingTokens.sm)
                    
                    Button(action: {}) {
                        Text("Post")
                            .font(TypographyScale.callout)
                            .fontWeight(.semibold)
                            .foregroundColor(ColorTokens.tertiaryText)
                    }
                    .disabled(true)
                }
                .padding(SpacingTokens.md)
                .background(.ultraThinMaterial)
            }
            .navigationBarHidden(true)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(SpacingTokens.lg)
    }
}

// MARK: - Previews

#Preview("Comment Sheet") {
    Text("Tap to open")
        .sheet(isPresented: .constant(true)) {
            CommentSheet(
                post: Post(
                    id: "1",
                    authorId: "user-1",
                    authorDisplayHandle: "test_user",
                    text: "This is a sample post",
                    replyCount: 5,
                    createdAt: Date()
                ),
                onDismiss: {}
            )
        }
}

