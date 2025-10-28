//
//  NotificationsView.swift
//  Agora
//
//  Created by Agora Team on 2024.
//

import SwiftUI
import DesignSystem
import AppFoundation

public struct NotificationsView: View {
    @Environment(\.deps) private var deps
    @State private var viewModel: NotificationsViewModel?
    
    public init() {}
    
    public var body: some View {
        Group {
            if let viewModel = viewModel {
                ScrollView {
                    LazyVStack(spacing: SpacingTokens.xs) {
                        if viewModel.notifications.isEmpty && !viewModel.isLoading {
                            EmptyStateView()
                        } else {
                            ForEach(viewModel.notifications, id: \.id) { notification in
                                NotificationRowView(notification: notification)
                            }
                        }
                    }
                    .padding(.bottom, 100) // Add bottom padding to ensure content extends under tab bar
                }
                .navigationTitle("notifications")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.large)
                #endif
                .refreshable {
                    await viewModel.refresh()
                }
                .overlay {
                    if viewModel.isLoading && viewModel.notifications.isEmpty {
                        LoadingView()
                    }
                }
                .task {
                    await viewModel.loadNotifications()
                }
            } else {
                LoadingView()
            }
        }
        .task {
            // Initialize view model with dependencies from environment
            // Following DI rule: dependencies injected from environment
            self.viewModel = NotificationsViewModel(networking: deps.networking)
        }
    }
}

struct NotificationRowView: View {
    let notification: NotificationItem
    @State private var isPressed = false
    @State private var hapticTrigger = false
    @Environment(\.navigateToPost) private var navigateToPost
    
    var body: some View {
        HStack(alignment: .top, spacing: SpacingTokens.sm) {
            // Icon
            Circle()
                .fill(iconColor)
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: iconName)
                        .font(TypographyScale.callout)
                        .foregroundColor(.white)
                }
                .symbolEffect(.bounce, value: isPressed)
            
            // Content
            VStack(alignment: .leading, spacing: SpacingTokens.xxs) {
                HStack {
                    Text(notification.title)
                        .font(TypographyScale.calloutEmphasized)
                        .foregroundColor(ColorTokens.primaryText)
                    
                    Spacer()
                    
                    Text(notification.timestamp, style: .relative)
                        .font(TypographyScale.caption1)
                        .foregroundColor(ColorTokens.tertiaryText)
                }
                
                Text(notification.message)
                    .font(TypographyScale.body)
                    .foregroundColor(ColorTokens.secondaryText)
                    .multilineTextAlignment(.leading)
                
                if let actionText = notification.actionText {
                    Text(actionText)
                        .font(TypographyScale.callout)
                        .foregroundColor(ColorTokens.tertiaryText)
                        .padding(.top, SpacingTokens.xxs)
                }
            }
            
            // Unread indicator
            if !notification.isRead {
                Circle()
                    .fill(ColorTokens.agoraBrand)
                    .frame(width: 10, height: 10)
                    .shadow(color: ColorTokens.agoraBrand.opacity(0.3), radius: 2, x: 0, y: 1)
            }
        }
        .padding(SpacingTokens.md)
        .background(
            notification.isRead ? 
            .regularMaterial : 
            .thickMaterial,
            in: RoundedRectangle(cornerRadius: SpacingTokens.sm)
        )
        .overlay(
            RoundedRectangle(cornerRadius: SpacingTokens.sm)
                .stroke(
                    notification.isRead ? 
                    ColorTokens.separator.opacity(0.3) : 
                    ColorTokens.agoraBrand.opacity(0.2), 
                    lineWidth: notification.isRead ? 0.5 : 1
                )
        )
        .shadow(
            color: notification.isRead ? 
            .black.opacity(0.05) : 
            .black.opacity(0.1), 
            radius: notification.isRead ? SpacingTokens.xxs : SpacingTokens.xxs, 
            x: 0, 
            y: notification.isRead ? 1 : 2
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onTapGesture {
            hapticTrigger.toggle()
            // Navigate to related post (using notification id as a placeholder)
            if let navigate = navigateToPost, let uuid = UUID(uuidString: notification.id) {
                navigate.action(uuid)
            }
        }
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .frame(minHeight: 60) // Ensure adequate touch target
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Double tap to view notification details")
        .sensoryFeedback(.selection, trigger: hapticTrigger)
    }
    
    private var accessibilityLabel: String {
        var label = notification.title
        label += ". \(notification.message)"
        if let actionText = notification.actionText {
            label += ". \(actionText)"
        }
        if !notification.isRead {
            label += ". Unread notification"
        }
        return label
    }
    
    private var iconName: String {
        switch notification.type {
        case .like:
            return "heart.fill"
        case .repost:
            return "arrow.2.squarepath"
        case .reply:
            return "bubble.right.fill"
        case .follow:
            return "person.badge.plus"
        case .mention:
            return "at"
        }
    }
    
    private var iconColor: Color {
        switch notification.type {
        case .like:
            return ColorTokens.error
        case .repost:
            return ColorTokens.success
        case .reply:
            return ColorTokens.agoraBrand
        case .follow:
            return ColorTokens.agoraBrand
        case .mention:
            return ColorTokens.warning
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: SpacingTokens.lg) {
            Image(systemName: "bell")
                .font(.system(size: 48))
                .foregroundColor(ColorTokens.tertiaryText)
                .symbolEffect(.pulse, isActive: true)
            
            Text("No Notifications")
                .font(TypographyScale.title2)
                .foregroundColor(ColorTokens.primaryText)
            
            Text("When people interact with your posts, you'll see notifications here.")
                .font(TypographyScale.body)
                .foregroundColor(ColorTokens.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(SpacingTokens.xl)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(ColorTokens.separator.opacity(0.2), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No notifications. When people interact with your posts, you'll see notifications here.")
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: SpacingTokens.md) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading notifications...")
                .font(TypographyScale.callout)
                .foregroundColor(ColorTokens.secondaryText)
        }
        .padding(SpacingTokens.xl)
    }
}

#if DEBUG
#Preview("Notifications") {
    PreviewDeps.scoped {
        NotificationsView()
    }
}
#endif