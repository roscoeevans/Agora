import SwiftUI
import AppFoundation
import Moderation

/// Handles moderation actions for direct messages
@MainActor
public final class DMModerationHandler: ObservableObject {
    @Published var showingReportSheet = false
    @Published var showingBlockConfirmation = false
    
    private var currentMessageToReport: Message?
    private var currentUserToBlock: String?
    
    private let contentFilter = ContentFilter.shared
    
    public init() {}
    
    /// Reports a message for policy violation
    /// - Parameter message: The message to report
    public func reportMessage(_ message: Message) {
        currentMessageToReport = message
        showingReportSheet = true
    }
    
    /// Blocks a user from sending messages
    /// - Parameter userId: The user ID to block
    public func blockUser(_ userId: String) {
        currentUserToBlock = userId
        showingBlockConfirmation = true
    }
    
    /// Confirms blocking a user
    public func confirmBlockUser() {
        guard let userId = currentUserToBlock else { return }
        
        // Add user to muted users list
        contentFilter.muteUser(userId)
        
        // Reset state
        currentUserToBlock = nil
        showingBlockConfirmation = false
        
        // TODO: Also block user on server side
        print("User \(userId) has been blocked")
    }
    
    /// Cancels blocking a user
    public func cancelBlockUser() {
        currentUserToBlock = nil
        showingBlockConfirmation = false
    }
    
    /// Checks if a message should be filtered
    /// - Parameter message: The message to check
    /// - Returns: Filter result indicating if message should be shown
    public func filterMessage(_ message: Message) -> FilterResult {
        let filterableMessage = FilterableMessage(message: message)
        return contentFilter.filterContent(filterableMessage)
    }
    
    /// Creates a report composer view for the current message
    public func createReportView() -> some View {
        Group {
            if let message = currentMessageToReport {
                ReportComposerView(
                    contentId: message.id.uuidString,
                    contentType: .directMessage
                )
            } else {
                EmptyView()
            }
        }
    }
    
    /// Creates a block confirmation dialog
    public func createBlockConfirmationDialog() -> Alert {
        Alert(
            title: Text("Block User"),
            message: Text("Are you sure you want to block this user? You won't receive messages from them anymore."),
            primaryButton: .destructive(Text("Block")) {
                self.confirmBlockUser()
            },
            secondaryButton: .cancel {
                self.cancelBlockUser()
            }
        )
    }
}

/// Wrapper to make Message conform to FilterableContent
private struct FilterableMessage: FilterableContent {
    let message: Message
    
    var id: String { message.id.uuidString }
    var authorId: String { message.senderId.uuidString }
    var text: String { message.content }
    var isReply: Bool { message.replyTo != nil }
    var isRepost: Bool { false } // DMs don't have reposts
    var isSensitive: Bool { false } // TODO: Add sensitive content detection
    var isReported: Bool { false } // TODO: Track reported messages
    
    init(message: Message) {
        self.message = message
    }
}

/// View modifier for adding moderation capabilities to message views
public struct MessageModerationModifier: ViewModifier {
    @StateObject private var moderationHandler = DMModerationHandler()
    let message: Message
    let currentUserId: String
    
    public func body(content: Content) -> some View {
        content
            .sheet(isPresented: $moderationHandler.showingReportSheet) {
                moderationHandler.createReportView()
            }
            .alert("Block User", isPresented: $moderationHandler.showingBlockConfirmation) {
                Button("Block", role: .destructive) {
                    moderationHandler.confirmBlockUser()
                }
                Button("Cancel", role: .cancel) {
                    moderationHandler.cancelBlockUser()
                }
            } message: {
                Text("Are you sure you want to block this user? You won't receive messages from them anymore.")
            }
            .environmentObject(moderationHandler)
    }
}

public extension View {
    /// Adds moderation capabilities to a message view
    /// - Parameters:
    ///   - message: The message being displayed
    ///   - currentUserId: The current user's ID
    /// - Returns: View with moderation capabilities
    func messageModeration(message: Message, currentUserId: String) -> some View {
        modifier(MessageModerationModifier(message: message, currentUserId: currentUserId))
    }
}