import SwiftUI
import DesignSystem
import AppFoundation

/// Typing indicator component with animated dots for showing when users are typing
public struct TypingIndicator: View {
    let typingUsers: Set<UUID>
    let currentUserId: UUID
    let getUserName: (UUID) -> String
    
    @State private var animationPhase = 0
    @State private var animationTimer: Timer?
    
    public init(
        typingUsers: Set<UUID>,
        currentUserId: UUID,
        getUserName: @escaping (UUID) -> String = { _ in "Someone" }
    ) {
        self.typingUsers = typingUsers
        self.currentUserId = currentUserId
        self.getUserName = getUserName
    }
    
    public var body: some View {
        if !typingUsers.isEmpty {
            HStack {
                HStack(spacing: SpacingTokens.sm) {
                    // Animated dots
                    animatedDots
                    
                    // Typing text
                    Text(typingText)
                        .font(TypographyScale.caption1)
                        .foregroundStyle(ColorTokens.secondaryText)
                }
                .padding(.horizontal, SpacingTokens.md)
                .padding(.vertical, SpacingTokens.sm)
                .background(ColorTokens.secondaryBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                
                Spacer()
            }
            .transition(.asymmetric(
                insertion: .scale(scale: 0.8).combined(with: .opacity).combined(with: .move(edge: .bottom)),
                removal: .scale(scale: 0.8).combined(with: .opacity)
            ))
            .onAppear {
                startAnimation()
            }
            .onDisappear {
                stopAnimation()
            }
            .accessibilityElement()
            .accessibilityLabel(accessibilityLabel)
        }
    }
    
    @ViewBuilder
    private var animatedDots: some View {
        HStack(spacing: SpacingTokens.xs) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(ColorTokens.secondaryText)
                    .frame(width: 6, height: 6)
                    .scaleEffect(animationPhase == index ? 1.3 : 0.8)
                    .opacity(animationPhase == index ? 1.0 : 0.6)
                    .animation(
                        .easeInOut(duration: 0.4),
                        value: animationPhase
                    )
            }
        }
    }
    
    private var typingText: String {
        let otherUsers = typingUsers.filter { $0 != currentUserId }
        let count = otherUsers.count
        
        switch count {
        case 0:
            return ""
        case 1:
            let userName = getUserName(otherUsers.first!)
            return "\(userName) is typing"
        case 2:
            let names = otherUsers.prefix(2).map(getUserName)
            return "\(names[0]) and \(names[1]) are typing"
        case 3:
            let names = otherUsers.prefix(2).map(getUserName)
            return "\(names[0]), \(names[1]), and 1 other are typing"
        default:
            let names = otherUsers.prefix(2).map(getUserName)
            return "\(names[0]), \(names[1]), and \(count - 2) others are typing"
        }
    }
    
    private var accessibilityLabel: String {
        let otherUsers = typingUsers.filter { $0 != currentUserId }
        let count = otherUsers.count
        
        switch count {
        case 0:
            return ""
        case 1:
            let userName = getUserName(otherUsers.first!)
            return "\(userName) is typing a message"
        case 2:
            let names = otherUsers.prefix(2).map(getUserName)
            return "\(names[0]) and \(names[1]) are typing messages"
        default:
            return "\(count) people are typing messages"
        }
    }
    
    private func startAnimation() {
        // Use TimelineView for smooth animation that respects Reduce Motion
        // Note: Timer callbacks are not ideal with @Observable structs.
        // In production, use TimelineView for SwiftUI-native animations.
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { _ in
            // Animation is handled by TimelineView implementation below
        }
    }
    
    private func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
}

/// Alternative implementation using TimelineView for better performance and Reduce Motion support
public struct TypingIndicatorTimelineView: View {
    let typingUsers: Set<UUID>
    let currentUserId: UUID
    let getUserName: (UUID) -> String
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    public init(
        typingUsers: Set<UUID>,
        currentUserId: UUID,
        getUserName: @escaping (UUID) -> String = { _ in "Someone" }
    ) {
        self.typingUsers = typingUsers
        self.currentUserId = currentUserId
        self.getUserName = getUserName
    }
    
    public var body: some View {
        if !typingUsers.isEmpty {
            HStack {
                HStack(spacing: SpacingTokens.sm) {
                    // Animated dots with Reduce Motion support
                    if reduceMotion {
                        staticDots
                    } else {
                        timelineAnimatedDots
                    }
                    
                    // Typing text
                    Text(typingText)
                        .font(TypographyScale.caption1)
                        .foregroundStyle(ColorTokens.secondaryText)
                }
                .padding(.horizontal, SpacingTokens.md)
                .padding(.vertical, SpacingTokens.sm)
                .background(ColorTokens.secondaryBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                
                Spacer()
            }
            .transition(.asymmetric(
                insertion: .scale(scale: 0.8).combined(with: .opacity).combined(with: .move(edge: .bottom)),
                removal: .scale(scale: 0.8).combined(with: .opacity)
            ))
            .accessibilityElement()
            .accessibilityLabel(accessibilityLabel)
        }
    }
    
    @ViewBuilder
    private var timelineAnimatedDots: some View {
        TimelineView(.periodic(from: .now, by: 0.6)) { timeline in
            let phase = Int(timeline.date.timeIntervalSince1970 * 1.67) % 3
            
            HStack(spacing: SpacingTokens.xs) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(ColorTokens.secondaryText)
                        .frame(width: 6, height: 6)
                        .scaleEffect(phase == index ? 1.3 : 0.8)
                        .opacity(phase == index ? 1.0 : 0.6)
                        .animation(
                            .easeInOut(duration: 0.4),
                            value: phase
                        )
                }
            }
        }
    }
    
    @ViewBuilder
    private var staticDots: some View {
        HStack(spacing: SpacingTokens.xs) {
            ForEach(0..<3, id: \.self) { _ in
                Circle()
                    .fill(ColorTokens.secondaryText)
                    .frame(width: 6, height: 6)
            }
        }
    }
    
    private var typingText: String {
        let otherUsers = typingUsers.filter { $0 != currentUserId }
        let count = otherUsers.count
        
        switch count {
        case 0:
            return ""
        case 1:
            let userName = getUserName(otherUsers.first!)
            return "\(userName) is typing"
        case 2:
            let names = otherUsers.prefix(2).map(getUserName)
            return "\(names[0]) and \(names[1]) are typing"
        case 3:
            let names = otherUsers.prefix(2).map(getUserName)
            return "\(names[0]), \(names[1]), and 1 other are typing"
        default:
            let names = otherUsers.prefix(2).map(getUserName)
            return "\(names[0]), \(names[1]), and \(count - 2) others are typing"
        }
    }
    
    private var accessibilityLabel: String {
        let otherUsers = typingUsers.filter { $0 != currentUserId }
        let count = otherUsers.count
        
        switch count {
        case 0:
            return ""
        case 1:
            let userName = getUserName(otherUsers.first!)
            return "\(userName) is typing a message"
        case 2:
            let names = otherUsers.prefix(2).map(getUserName)
            return "\(names[0]) and \(names[1]) are typing messages"
        default:
            return "\(count) people are typing messages"
        }
    }
}

#Preview("Single User Typing") {
    VStack(spacing: SpacingTokens.lg) {
        TypingIndicator(
            typingUsers: [UUID()],
            currentUserId: UUID(),
            getUserName: { _ in "Alice" }
        )
        
        TypingIndicatorTimelineView(
            typingUsers: [UUID()],
            currentUserId: UUID(),
            getUserName: { _ in "Alice" }
        )
    }
    .padding()
}

#Preview("Multiple Users Typing") {
    let user1 = UUID()
    let user2 = UUID()
    let user3 = UUID()
    let user4 = UUID()
    
    VStack(spacing: SpacingTokens.lg) {
        // Two users
        TypingIndicator(
            typingUsers: [user1, user2],
            currentUserId: UUID(),
            getUserName: { id in
                if id == user1 { return "Alice" }
                if id == user2 { return "Bob" }
                return "Someone"
            }
        )
        
        // Three users
        TypingIndicator(
            typingUsers: [user1, user2, user3],
            currentUserId: UUID(),
            getUserName: { id in
                if id == user1 { return "Alice" }
                if id == user2 { return "Bob" }
                if id == user3 { return "Charlie" }
                return "Someone"
            }
        )
        
        // Four users
        TypingIndicator(
            typingUsers: [user1, user2, user3, user4],
            currentUserId: UUID(),
            getUserName: { id in
                if id == user1 { return "Alice" }
                if id == user2 { return "Bob" }
                if id == user3 { return "Charlie" }
                if id == user4 { return "David" }
                return "Someone"
            }
        )
    }
    .padding()
}

#Preview("Empty State") {
    TypingIndicator(
        typingUsers: [],
        currentUserId: UUID(),
        getUserName: { _ in "Someone" }
    )
    .padding()
}