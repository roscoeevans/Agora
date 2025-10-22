//
//  ShareMenu.swift
//  DesignSystem
//
//  Share menu with multiple sharing options
//

import SwiftUI
import AppFoundation
import UIKitBridge

/// Share menu with multiple sharing options
/// Displays as a bottom sheet with native iOS patterns
public struct ShareMenu: View {
    let post: Post
    let shareURL: URL
    let onShareToDM: () -> Void
    let onDismiss: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var showCopiedToast = false
    
    public init(
        post: Post,
        shareURL: URL,
        onShareToDM: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.post = post
        self.shareURL = shareURL
        self.onShareToDM = onShareToDM
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Share")
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
            
            Divider()
            
            // Share options
            VStack(spacing: 0) {
                ShareMenuItem(
                    icon: "paperplane.fill",
                    title: "Share to Agora DM",
                    subtitle: "Send in a message",
                    action: {
                        onShareToDM()
                        dismiss()
                    }
                )
                
                Divider()
                    .padding(.leading, 60)
                
                ShareMenuItem(
                    icon: "message.fill",
                    title: "Share via iMessage",
                    subtitle: "Send to contacts",
                    shareURL: shareURL  // Use ShareLink internally
                )
                
                Divider()
                    .padding(.leading, 60)
                
                ShareMenuItem(
                    icon: "doc.on.doc",
                    title: "Copy Link",
                    subtitle: "Share anywhere",
                    action: {
                        copyLink()
                    }
                )
            }
            
            Spacer()
        }
        .overlay(alignment: .bottom) {
            if showCopiedToast {
                ToastView(message: "Link copied to clipboard", icon: "checkmark.circle.fill")
                    .padding(.bottom, SpacingTokens.lg)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .presentationDetents([.height(280)])
        .presentationDragIndicator(.visible)
    }
    
    private func copyLink() {
        DesignSystemBridge.copyURL(shareURL)
        
        withAnimation(.spring(response: 0.3)) {
            showCopiedToast = true
        }
        
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation(.spring(response: 0.3)) {
                showCopiedToast = false
            }
        }
        
        DesignSystemBridge.mediumImpact()
    }
}

/// Individual share menu item (supports action or ShareLink)
struct ShareMenuItem: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: (() -> Void)?
    let shareURL: URL?
    
    @State private var isPressed = false
    
    init(
        icon: String,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.action = action
        self.shareURL = nil
    }
    
    init(
        icon: String,
        title: String,
        subtitle: String,
        shareURL: URL
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.action = nil
        self.shareURL = shareURL
    }
    
    var body: some View {
        Group {
            if let shareURL {
                // Use native ShareLink for system share sheet
                ShareLink(item: shareURL) {
                    shareMenuContent
                }
            } else {
                Button(action: { action?() }) {
                    shareMenuContent
                }
            }
        }
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
    
    private var shareMenuContent: some View {
        HStack(spacing: SpacingTokens.md) {
            ZStack {
                Circle()
                    .fill(ColorTokens.accentPrimary.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(ColorTokens.accentPrimary)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(TypographyScale.body)
                    .foregroundColor(ColorTokens.primaryText)
                
                Text(subtitle)
                    .font(TypographyScale.caption1)
                    .foregroundColor(ColorTokens.tertiaryText)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(ColorTokens.quaternaryText)
        }
        .padding(SpacingTokens.md)
        .background(ColorTokens.background)
        .contentShape(Rectangle())
    }
}

/// Toast notification view
struct ToastView: View {
    let message: String
    let icon: String
    
    var body: some View {
        HStack(spacing: SpacingTokens.sm) {
            Image(systemName: icon)
                .foregroundColor(.white)
            
            Text(message)
                .font(TypographyScale.callout)
                .foregroundColor(.white)
        }
        .padding(.horizontal, SpacingTokens.md)
        .padding(.vertical, SpacingTokens.sm)
        .background(.black.opacity(0.85))
        .cornerRadius(SpacingTokens.md)
        .shadow(color: .black.opacity(0.1), radius: SpacingTokens.sm, y: 4)
    }
}

// MARK: - Previews

#Preview("Share Menu") {
    Text("Tap to open")
        .sheet(isPresented: .constant(true)) {
            ShareMenu(
                post: Post(
                    id: "1",
                    authorId: "user-1",
                    authorDisplayHandle: "test_user",
                    text: "This is a sample post",
                    createdAt: Date()
                ),
                shareURL: URL(string: "https://agora.app/p/123")!,
                onShareToDM: { print("Share to DM") },
                onDismiss: {}
            )
        }
}

