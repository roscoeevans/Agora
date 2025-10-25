import SwiftUI
import DesignSystem
import AppFoundation

/// List item component for displaying conversation previews
public struct ConversationRow: View {
    let conversation: Conversation
    @Environment(\.layoutDirection) private var layoutDirection
    
    public init(conversation: Conversation) {
        self.conversation = conversation
    }
    
    public var body: some View {
        rowContent
            .padding(.vertical, 4)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityHint("Double tap to open conversation")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction(named: "Mark as read") {
                if conversation.unreadCount > 0 {
                    // TODO: Implement mark as read action
                }
            }
            .accessibilityAction(named: conversation.isPinned ? "Unpin" : "Pin") {
                // TODO: Implement pin/unpin action
            }
            .accessibilityAction(named: conversation.isMuted ? "Unmute" : "Mute") {
                // TODO: Implement mute/unmute action
            }
    }
    
    private var rowContent: some View {
        HStack(spacing: 12) {
            // Avatar
            avatarView
            
            // Content
            contentColumn
        }
    }
    
    private var contentColumn: some View {
        VStack(alignment: .leading, spacing: 2) {
            titleRow
            messagePreviewRow
        }
    }
    
    private var titleRow: some View {
        HStack {
            // Title with unread styling
            let titleWeight: Font.Weight = conversation.unreadCount > 0 ? .semibold : .regular
            Text(displayTitle)
                .font(.headline)
                .fontWeight(titleWeight)
                .foregroundStyle(.primary)
            
            // Pinned indicator
            if conversation.isPinned {
                Image(systemName: "pin.fill")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }
            
            // Muted indicator
            if conversation.isMuted {
                Image(systemName: "bell.slash.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Timestamp
            Text(formattedTimestamp)
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }
    
    private var messagePreviewRow: some View {
        HStack {
            // Last message preview or draft
            let previewColor: Color = isDraft ? .blue : .secondary
            Text(messagePreview)
                .font(.subheadline)
                .foregroundStyle(previewColor)
                .lineLimit(2)
                .italic(isDraft)
            
            Spacer()
            
            // Unread indicators
            unreadIndicators
        }
    }
    
    // MARK: - Computed Properties
    
    private var displayTitle: String {
        if let title = conversation.title {
            return title
        }
        
        // For non-group conversations, use participant names
        let otherParticipants = conversation.participants
        if otherParticipants.isEmpty {
            return "Unknown"
        } else if otherParticipants.count == 1 {
            return otherParticipants[0].displayName
        } else {
            // For group conversations without a title, show participant names
            let names = otherParticipants.prefix(2).map { $0.displayName }
            if otherParticipants.count > 2 {
                return names.joined(separator: ", ") + " and \(otherParticipants.count - 2) others"
            } else {
                return names.joined(separator: ", ")
            }
        }
    }
    
    private var messagePreview: String {
        if let draftText = conversation.draftText, !draftText.isEmpty {
            return "Draft: \(draftText)"
        }
        
        if let lastMessage = conversation.lastMessage {
            if lastMessage.content.isEmpty && !lastMessage.attachments.isEmpty {
                // Show attachment indicator
                let attachmentCount = lastMessage.attachments.count
                if attachmentCount == 1 {
                    let attachment = lastMessage.attachments[0]
                    switch attachment.type {
                    case .image:
                        return "📷 Photo"
                    case .video:
                        return "🎥 Video"
                    case .audio:
                        return "🎵 Audio"
                    case .document:
                        return "📄 Document"
                    }
                } else {
                    return "📎 \(attachmentCount) attachments"
                }
            } else {
                return lastMessage.content
            }
        }
        
        return "No messages yet"
    }
    
    private var isDraft: Bool {
        return conversation.draftText != nil && !conversation.draftText!.isEmpty
    }
    
    private var formattedTimestamp: String {
        let now = Date()
        let calendar = Calendar.current
        
        // If it's today, show time
        if calendar.isDate(conversation.lastActivity, inSameDayAs: now) {
            let timeFormatter = DateFormatter()
            timeFormatter.timeStyle = .short
            timeFormatter.locale = Locale.current
            return timeFormatter.string(from: conversation.lastActivity)
        }
        
        // Use RelativeDateTimeFormatter for relative dates
        let relativeFormatter = RelativeDateTimeFormatter()
        relativeFormatter.dateTimeStyle = .named
        relativeFormatter.unitsStyle = .abbreviated
        relativeFormatter.locale = Locale.current
        
        // If it's within the last week, use relative formatting
        if conversation.lastActivity.timeIntervalSinceNow > -604800 {
            return relativeFormatter.localizedString(for: conversation.lastActivity, relativeTo: now)
        }
        
        // Otherwise show date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.locale = Locale.current
        return dateFormatter.string(from: conversation.lastActivity)
    }
    
    private var accessibilityLabel: String {
        var components: [String] = []
        
        // Conversation title
        components.append("Conversation with \(displayTitle)")
        
        // Unread status (most important first)
        if conversation.unreadMentionsCount > 0 {
            components.append("\(conversation.unreadMentionsCount) unread mentions")
        } else if conversation.unreadCount > 0 {
            components.append("\(conversation.unreadCount) unread messages")
        }
        
        // Last activity time
        components.append("Last activity \(formattedTimestamp)")
        
        // Message preview
        if !messagePreview.isEmpty {
            if isDraft {
                components.append("Draft message: \(conversation.draftText ?? "")")
            } else {
                components.append("Last message: \(messagePreview)")
            }
        }
        
        // Status indicators
        var statusItems: [String] = []
        if conversation.isPinned {
            statusItems.append("pinned")
        }
        if conversation.isMuted {
            statusItems.append("muted")
        }
        if conversation.isArchived {
            statusItems.append("archived")
        }
        
        if !statusItems.isEmpty {
            components.append("Status: \(statusItems.joined(separator: ", "))")
        }
        
        return components.joined(separator: ". ")
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var avatarView: some View {
        if let avatarUrl = conversation.avatarUrl {
            AsyncImage(url: avatarUrl) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                avatarPlaceholder
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
        } else {
            avatarPlaceholder
        }
    }
    
    private var avatarPlaceholder: some View {
        Circle()
            .fill(.secondary.opacity(0.3))
            .frame(width: 50, height: 50)
            .overlay {
                if conversation.isGroup {
                    Image(systemName: "person.2.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                } else {
                    Text(String(displayTitle.prefix(1).uppercased()))
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
            }
    }
    
    @ViewBuilder
    private var unreadIndicators: some View {
        HStack(spacing: 4) {
            // Mention indicator (higher priority)
            if conversation.unreadMentionsCount > 0 {
                Text("\(conversation.unreadMentionsCount)")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.red, in: Capsule())
                    .accessibilityLabel("\(conversation.unreadMentionsCount) mentions")
            }
            // Regular unread indicator
            else if conversation.unreadCount > 0 {
                if conversation.unreadCount > 99 {
                    Text("99+")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.blue, in: Capsule())
                        .accessibilityLabel("More than 99 unread messages")
                } else if conversation.unreadCount > 1 {
                    Text("\(conversation.unreadCount)")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.blue, in: Capsule())
                        .accessibilityLabel("\(conversation.unreadCount) unread messages")
                } else {
                    Circle()
                        .fill(.blue)
                        .frame(width: 8, height: 8)
                        .accessibilityLabel("1 unread message")
                }
            }
        }
    }
}

#Preview {
    List {
        ConversationRow(
            conversation: Conversation(
                id: UUID(),
                participants: [
                    User(id: UUID().uuidString, handle: "johndoe", displayHandle: "@johndoe", displayName: "John Doe", bio: nil, avatarUrl: nil, createdAt: Date())
                ],
                lastMessage: Message(
                    id: UUID(),
                    conversationId: UUID(),
                    senderId: UUID(),
                    content: "Hey, how's it going?",
                    attachments: [],
                    timestamp: Date(),
                    deliveryStatus: .delivered,
                    replyTo: nil,
                    nonce: nil,
                    editedAt: nil,
                    deletedAt: nil,
                    expiresAt: nil,
                    systemKind: nil,
                    linkPreview: nil
                ),
                lastActivity: Date(),
                unreadCount: 2,
                unreadMentionsCount: 0,
                isArchived: false,
                isPinned: false,
                isMuted: false,
                lastReadMessageId: nil,
                draftText: nil,
                isGroup: false,
                title: nil,
                avatarUrl: nil
            )
        )
        
        ConversationRow(
            conversation: Conversation(
                id: UUID(),
                participants: [
                    User(id: UUID().uuidString, handle: "janesmith", displayHandle: "@janesmith", displayName: "Jane Smith", bio: nil, avatarUrl: nil, createdAt: Date())
                ],
                lastMessage: Message(
                    id: UUID(),
                    conversationId: UUID(),
                    senderId: UUID(),
                    content: "Thanks for the help earlier!",
                    attachments: [],
                    timestamp: Date().addingTimeInterval(-86400),
                    deliveryStatus: .read,
                    replyTo: nil,
                    nonce: nil,
                    editedAt: nil,
                    deletedAt: nil,
                    expiresAt: nil,
                    systemKind: nil,
                    linkPreview: nil
                ),
                lastActivity: Date().addingTimeInterval(-86400),
                unreadCount: 0,
                unreadMentionsCount: 0,
                isArchived: false,
                isPinned: true,
                isMuted: false,
                lastReadMessageId: nil,
                draftText: "I was thinking about...",
                isGroup: false,
                title: nil,
                avatarUrl: nil
            )
        )
        
        ConversationRow(
            conversation: Conversation(
                id: UUID(),
                participants: [
                    User(id: UUID().uuidString, handle: "alice", displayHandle: "@alice", displayName: "Alice", bio: nil, avatarUrl: nil, createdAt: Date()),
                    User(id: UUID().uuidString, handle: "bob", displayHandle: "@bob", displayName: "Bob", bio: nil, avatarUrl: nil, createdAt: Date())
                ],
                lastMessage: Message(
                    id: UUID(),
                    conversationId: UUID(),
                    senderId: UUID(),
                    content: "Meeting at 3 PM today",
                    attachments: [],
                    timestamp: Date().addingTimeInterval(-7200),
                    deliveryStatus: .delivered,
                    replyTo: nil,
                    nonce: nil,
                    editedAt: nil,
                    deletedAt: nil,
                    expiresAt: nil,
                    systemKind: nil,
                    linkPreview: nil
                ),
                lastActivity: Date().addingTimeInterval(-7200),
                unreadCount: 5,
                unreadMentionsCount: 1,
                isArchived: false,
                isPinned: false,
                isMuted: false,
                lastReadMessageId: nil,
                draftText: nil,
                isGroup: true,
                title: "Team Chat",
                avatarUrl: nil
            )
        )
    }
}