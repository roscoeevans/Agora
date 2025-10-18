//
//  AuthorRow.swift
//  DesignSystem
//
//  Reusable author row component with avatar, handle, and timestamp
//

import SwiftUI

/// Author row with avatar, handle, and timestamp
/// Displays user information in a compact horizontal layout
public struct AuthorRow: View {
    let displayHandle: String
    let displayName: String?
    let avatarUrl: String?
    let timestamp: Date
    let editedAt: Date?
    let onTap: () -> Void
    
    public init(
        displayHandle: String,
        displayName: String? = nil,
        avatarUrl: String? = nil,
        timestamp: Date,
        editedAt: Date? = nil,
        onTap: @escaping () -> Void = {}
    ) {
        self.displayHandle = displayHandle
        self.displayName = displayName
        self.avatarUrl = avatarUrl
        self.timestamp = timestamp
        self.editedAt = editedAt
        self.onTap = onTap
    }
    
    public var body: some View {
        HStack(spacing: SpacingTokens.xs) {
            // Avatar
            Button(action: onTap) {
                if let avatarUrl = avatarUrl, let url = URL(string: avatarUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            placeholderAvatar
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            placeholderAvatar
                        @unknown default:
                            placeholderAvatar
                        }
                    }
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                } else {
                    placeholderAvatar
                }
            }
            .frame(width: 44, height: 44) // Ensure 44pt touch target
            
            // Handle and timestamp (no display name)
            HStack(alignment: .firstTextBaseline, spacing: SpacingTokens.xxs) {
                Text("@\(displayHandle)")
                    .font(TypographyScale.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(ColorTokens.primaryText)
                
                Text("·")
                    .foregroundColor(ColorTokens.quaternaryText)
                
                Text(formatTimestamp(timestamp))
                    .font(TypographyScale.caption1)
                    .foregroundColor(ColorTokens.tertiaryText)
                
                if editedAt != nil {
                    Text("·")
                        .foregroundColor(ColorTokens.quaternaryText)
                    
                    HStack(spacing: 2) {
                        Image(systemName: "pencil.circle")
                        Text("Edited")
                    }
                    .font(TypographyScale.caption2)
                    .foregroundColor(ColorTokens.tertiaryText)
                }
            }
            
            Spacer()
        }
    }
    
    private var placeholderAvatar: some View {
        Circle()
            .fill(ColorTokens.separator.opacity(0.3))
            .frame(width: 40, height: 40)
            .overlay {
                Image(systemName: "person.fill")
                    .foregroundColor(ColorTokens.tertiaryText)
                    .font(.system(size: 18))
            }
    }
    
    /// Format timestamp using Twitter-style relative time
    /// - < 5s: "just now"
    /// - 5s-59s: "24 sec"
    /// - 1m-59m: "17m"
    /// - 1h-23h: "1h"
    /// - 24h+: "1d", "2d", etc.
    private func formatTimestamp(_ date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        
        if seconds < 5 {
            return "just now"
        } else if seconds < 60 {
            return "\(seconds) sec"
        } else if seconds < 3600 { // Less than 1 hour
            let minutes = seconds / 60
            return "\(minutes)m"
        } else if seconds < 86400 { // Less than 24 hours
            let hours = seconds / 3600
            return "\(hours)h"
        } else {
            let days = seconds / 86400
            return "\(days)d"
        }
    }
}

// MARK: - Previews

#Preview("Author Row - Various Timestamps") {
    VStack(spacing: SpacingTokens.md) {
        // Just now
        AuthorRow(
            displayHandle: "rocky.evans",
            displayName: "Rocky Evans",
            avatarUrl: nil,
            timestamp: Date().addingTimeInterval(-2)
        )
        
        Divider()
        
        // Seconds ago
        AuthorRow(
            displayHandle: "jane.doe",
            displayName: nil,
            avatarUrl: nil,
            timestamp: Date().addingTimeInterval(-24)
        )
        
        Divider()
        
        // Minutes ago
        AuthorRow(
            displayHandle: "john.smith",
            displayName: nil,
            avatarUrl: nil,
            timestamp: Date().addingTimeInterval(-684) // 11m 24s
        )
        
        Divider()
        
        // Hours ago
        AuthorRow(
            displayHandle: "sarah.connor",
            displayName: nil,
            avatarUrl: nil,
            timestamp: Date().addingTimeInterval(-7200) // 2h
        )
        
        Divider()
        
        // Days ago with edited
        AuthorRow(
            displayHandle: "alex.james",
            displayName: nil,
            avatarUrl: nil,
            timestamp: Date().addingTimeInterval(-172800), // 2d
            editedAt: Date().addingTimeInterval(-86400) // 1d
        )
    }
    .padding()
}

