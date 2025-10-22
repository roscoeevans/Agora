import SwiftUI
import DesignSystem

/// Individual message display component with sender-appropriate styling
public struct MessageBubble: View {
    let message: String // Placeholder - will be replaced with Message model
    let isFromCurrentUser: Bool
    
    public init(message: String, isFromCurrentUser: Bool) {
        self.message = message
        self.isFromCurrentUser = isFromCurrentUser
    }
    
    public var body: some View {
        HStack {
            if isFromCurrentUser { Spacer(minLength: 48) }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(message)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(isFromCurrentUser ? .blue : .gray.opacity(0.2))
                    )
                    .foregroundStyle(isFromCurrentUser ? .white : .primary)
                
                Text("12:34 PM") // Placeholder timestamp
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            
            if !isFromCurrentUser { Spacer(minLength: 48) }
        }
    }
}

#Preview {
    VStack(spacing: 8) {
        MessageBubble(message: "Hello there!", isFromCurrentUser: false)
        MessageBubble(message: "Hi! How are you?", isFromCurrentUser: true)
    }
    .padding()
}