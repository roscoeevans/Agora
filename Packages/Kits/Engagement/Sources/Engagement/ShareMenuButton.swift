//
//  ShareMenuButton.swift
//  Engagement
//
//  Icon-only share menu with auto-send DM, iMessage, and copy link
//

import SwiftUI
import AppFoundation
import UIKitBridge

#if canImport(UIKit) && canImport(MessageUI)
import UIKit
import MessageUI
#endif

/// Avatar icon for share menu recipients
struct AvatarIcon: View {
    let url: URL?
    let size: CGFloat
    
    var body: some View {
        Group {
            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().scaledToFill()
                    case .empty:
                        Color.secondary.opacity(0.15)
                            .redacted(reason: .placeholder)
                    case .failure:
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFill()
                    @unknown default:
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFill()
                    }
                }
            } else {
                Color.secondary.opacity(0.15)
                    .redacted(reason: .placeholder)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(.quaternary, lineWidth: 0.5))
        .contentShape(Circle())
    }
}

/// Share menu button with icon-only items (avatars, iMessage, copy)
/// Auto-sends DMs without navigation
/// Records share count (idempotent - one per user) when any option is used
@available(iOS 26.0, *)
public struct ShareMenuButton: View {
    public let shareURL: URL
    public let postId: String
    
    // UI state
    @State private var recipients: [ShareRecipient] = []
    @State private var isLoadingRecipients = true
    @State private var hud: HUDState = .hidden
    @State private var toast: Toast?
    @State private var showMessageComposer = false
    
    @Environment(\.deps) private var deps
    
    private let avatarSize: CGFloat = 32
    
    public init(shareURL: URL, postId: String) {
        self.shareURL = shareURL
        self.postId = postId
    }
    
    public var body: some View {
        Menu {
            // 1) DM Avatars (icon-only)
            if isLoadingRecipients && recipients.isEmpty {
                ForEach(0..<3, id: \.self) { _ in
                    Button(action: {}) {
                        Label {
                            Text("").opacity(0)
                        } icon: {
                            AvatarIcon(url: nil, size: avatarSize)
                        }
                    }
                    .disabled(true)
                    .labelStyle(.iconOnly)
                    .accessibilityHidden(true)
                }
                Divider()
            } else if !recipients.isEmpty {
                ForEach(recipients.prefix(3)) { recipient in
                    Button {
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        #endif
                        Task { 
                            await recordShare()
                            await autoSend(recipient) 
                        }
                    } label: {
                        Label {
                            Text(recipient.displayName)
                                .font(.caption)
                        } icon: {
                            AvatarIcon(url: recipient.avatarURL, size: avatarSize)
                        }
                    }
                    .accessibilityLabel("Share to \(recipient.displayName)")
                    .accessibilityHint("Sends this post via Agora DM")
                }
                Divider()
            }
            
            // 2) iMessage
            Button {
                #if os(iOS)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                #endif
                Task { await recordShare() }
                showMessageComposer = true
            } label: {
                Label {
                    Text("iMessage")
                        .font(.caption)
                } icon: {
                    Image(systemName: "message.fill")
                        .imageScale(.large)
                }
            }
            .accessibilityLabel("Share via iMessage")
            
            // 3) Copy Link
            Button {
                #if os(iOS)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                UIPasteboard.general.url = shareURL
                #endif
                Task { await recordShare() }
                showToast("Link copied")
            } label: {
                Label {
                    Text("Copy Link")
                        .font(.caption)
                } icon: {
                    Image(systemName: "link")
                        .imageScale(.large)
                }
            }
            .accessibilityLabel("Copy Link")
            
        } label: {
            Image(systemName: "arrow.turn.up.right")
                .foregroundStyle(.secondary)
        }
        .task { await loadRecipients() }
        .overlay(alignment: .center) {
            if hud != .hidden {
                FeedbackHUD(state: hud)
                    .padding(.bottom, 80)
            }
        }
        .overlay(alignment: .bottom) {
            if let toast {
                ToastView(message: toast.message)
                    .padding(.bottom, 18)
            }
        }
        .sheet(isPresented: $showMessageComposer) {
            #if canImport(UIKit) && canImport(MessageUI)
            if MFMessageComposeViewController.canSendText() {
                MessageComposer(
                    body: shareURL.absoluteString,
                    onFinish: { result in
                        switch result {
                        case .sent:
                            #if os(iOS)
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                            #endif
                            Task { await recordShare() }
                            showToast("Sent with Messages")
                        case .failed:
                            #if os(iOS)
                            UINotificationFeedbackGenerator().notificationOccurred(.error)
                            #endif
                            showToast("Send failed")
                        case .cancelled:
                            break
                        @unknown default:
                            break
                        }
                    }
                )
                .ignoresSafeArea()
            } else {
                UIActivityViewControllerWrapper(items: [shareURL])
            }
            #else
            EmptyView()
            #endif
        }
    }
    
    // MARK: - Helpers
    
    private func loadRecipients() async {
        isLoadingRecipients = true
        defer { isLoadingRecipients = false }
        
        guard let messaging = deps.messaging else {
            recipients = []
            return
        }
        
        do {
            let dms = try await messaging.recentDMRecipients(limit: 3)
            if !dms.isEmpty {
                recipients = dms
                return
            }
            recipients = try await messaging.recentFollows(limit: 3)
        } catch {
            recipients = []
        }
    }
    
    private func autoSend(_ recipient: ShareRecipient) async {
        await setHUD(.sending)
        
        guard let messaging = deps.messaging else {
            await setHUD(.failure)
            try? await Task.sleep(for: .seconds(1.2))
            await setHUD(.hidden)
            return
        }
        
        do {
            try await messaging.autoSendDM(to: recipient.id, text: shareURL.absoluteString)
            #if os(iOS)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            #endif
            await setHUD(.success)
            try? await Task.sleep(for: .seconds(0.9))
            await setHUD(.hidden)
        } catch {
            #if os(iOS)
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            #endif
            await setHUD(.failure)
            try? await Task.sleep(for: .seconds(1.2))
            await setHUD(.hidden)
        }
    }
    
    @MainActor
    private func setHUD(_ state: HUDState) {
        withAnimation {
            hud = state
        }
    }
    
    @MainActor
    private func showToast(_ message: String, duration: Double = 1.5) {
        withAnimation {
            toast = Toast(message: message)
        }
        
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(duration))
            withAnimation {
                toast = nil
            }
        }
    }
    
    /// Record share (idempotent - only counts once per user)
    private func recordShare() async {
        guard let engagement = deps.engagement else { return }
        
        // Fire and forget - don't block UI or show errors
        // Idempotent call, so safe to call multiple times
        do {
            _ = try await engagement.recordShare(postId: postId)
        } catch {
            // Silently fail - share count is not critical UX
        }
    }
}

