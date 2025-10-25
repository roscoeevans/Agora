import SwiftUI
import DesignSystem
import AppFoundation

/// Individual message display component with sender-appropriate styling
public struct MessageBubble: View {
    let message: Message
    let currentUserId: String
    let onCopy: () -> Void
    let onReply: () -> Void
    let onDelete: () -> Void
    let onReport: () -> Void
    let onBlock: () -> Void
    
    @Environment(\.layoutDirection) private var layoutDirection
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    public init(
        message: Message,
        currentUserId: String,
        onCopy: @escaping () -> Void,
        onReply: @escaping () -> Void,
        onDelete: @escaping () -> Void,
        onReport: @escaping () -> Void,
        onBlock: @escaping () -> Void
    ) {
        self.message = message
        self.currentUserId = currentUserId
        self.onCopy = onCopy
        self.onReply = onReply
        self.onDelete = onDelete
        self.onReport = onReport
        self.onBlock = onBlock
    }
    
    public var body: some View {
        messageContent
            .contextMenu {
                contextMenuActions
            }
    }
    
    private var messageContent: some View {
        HStack {
            if isFromCurrentUser { Spacer(minLength: 48) }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                // Text content
                if !message.content.isEmpty {
                    Text(message.content)
                        .font(TypographyScale.body)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(isFromCurrentUser ? Color.blue : ColorTokens.secondaryBackground)
                        )
                        .foregroundStyle(isFromCurrentUser ? .white : ColorTokens.primaryText)
                }
                
                // Timestamp
                Text(message.timestamp, style: .time)
                    .font(TypographyScale.caption2)
                    .foregroundStyle(ColorTokens.secondaryText)
                    .monospacedDigit()
            }
            
            if !isFromCurrentUser { Spacer(minLength: 48) }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }
    
    private var isFromCurrentUser: Bool {
        message.senderId.uuidString == currentUserId
    }
    
    private var accessibilityLabel: String {
        let sender = isFromCurrentUser ? "You" : "Other user"
        let time = message.timestamp.formatted(date: .omitted, time: .shortened)
        return "\(sender), \(time): \(message.content)"
    }
    
    @ViewBuilder
    private var contextMenuActions: some View {
        Button("Copy", action: onCopy)
        Button("Reply", action: onReply)
        
        if isFromCurrentUser {
            Button("Delete", role: .destructive, action: onDelete)
        } else {
            Button("Report", role: .destructive, action: onReport)
            Button("Block User", role: .destructive, action: onBlock)
        }
    }
}

#Preview {
    let sampleMessage1 = Message(
        id: UUID(),
        conversationId: UUID(),
        senderId: UUID(),
        content: "Hello there!",
        timestamp: Date()
    )
    
    let sampleMessage2 = Message(
        id: UUID(),
        conversationId: UUID(),
        senderId: UUID(),
        content: "Hi! How are you?",
        timestamp: Date()
    )
    
    VStack(spacing: 8) {
        MessageBubble(
            message: sampleMessage1,
            currentUserId: UUID().uuidString,
            onCopy: {},
            onReply: {},
            onDelete: {},
            onReport: {},
            onBlock: {}
        )
        MessageBubble(
            message: sampleMessage2,
            currentUserId: sampleMessage2.senderId.uuidString,
            onCopy: {},
            onReply: {},
            onDelete: {},
            onReport: {},
            onBlock: {}
        )
    }
    .padding()
}