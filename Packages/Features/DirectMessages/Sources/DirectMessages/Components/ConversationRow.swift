import SwiftUI
import DesignSystem

/// List item component for displaying conversation previews
public struct ConversationRow: View {
    let title: String
    let lastMessage: String
    let timestamp: String
    let hasUnread: Bool
    
    public init(title: String, lastMessage: String, timestamp: String, hasUnread: Bool = false) {
        self.title = title
        self.lastMessage = lastMessage
        self.timestamp = timestamp
        self.hasUnread = hasUnread
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            // Avatar placeholder
            Circle()
                .fill(.secondary.opacity(0.3))
                .frame(width: 50, height: 50)
                .overlay {
                    Text(String(title.prefix(1)))
                        .font(.title2)
                        .fontWeight(.medium)
                }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(title)
                        .font(.headline)
                        .fontWeight(hasUnread ? .semibold : .regular)
                    
                    Spacer()
                    
                    Text(timestamp)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Text(lastMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    if hasUnread {
                        Circle()
                            .fill(.blue)
                            .frame(width: 8, height: 8)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    List {
        ConversationRow(
            title: "John Doe",
            lastMessage: "Hey, how's it going?",
            timestamp: "2:34 PM",
            hasUnread: true
        )
        ConversationRow(
            title: "Jane Smith",
            lastMessage: "Thanks for the help earlier!",
            timestamp: "Yesterday",
            hasUnread: false
        )
    }
}