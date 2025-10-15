//
//  SelfDestructPicker.swift
//  Agora
//
//  Self-destruct duration picker for posts
//

import SwiftUI
import DesignSystem

/// Self-destruct duration options
public enum SelfDestructDuration: String, CaseIterable, Identifiable {
    case none = "Never"
    case twentyFourHours = "24 hours"
    case threeDays = "3 days"
    case oneWeek = "1 week"
    
    public var id: String { rawValue }
    
    /// Convert to Date offset from now
    public func date(from now: Date = Date()) -> Date? {
        switch self {
        case .none:
            return nil
        case .twentyFourHours:
            return Calendar.current.date(byAdding: .hour, value: 24, to: now)
        case .threeDays:
            return Calendar.current.date(byAdding: .day, value: 3, to: now)
        case .oneWeek:
            return Calendar.current.date(byAdding: .day, value: 7, to: now)
        }
    }
    
    /// Descriptive text for UI
    public var description: String {
        switch self {
        case .none:
            return "Post stays forever"
        case .twentyFourHours:
            return "Deletes in 24 hours"
        case .threeDays:
            return "Deletes in 3 days"
        case .oneWeek:
            return "Deletes in 1 week"
        }
    }
    
    /// SF Symbol icon
    public var icon: String {
        switch self {
        case .none:
            return "infinity"
        case .twentyFourHours, .threeDays, .oneWeek:
            return "clock.badge.xmark"
        }
    }
}

/// Self-destruct duration picker component
public struct SelfDestructPicker: View {
    @Binding var selectedDuration: SelfDestructDuration
    @State private var isExpanded = false
    
    public init(selectedDuration: Binding<SelfDestructDuration>) {
        self._selectedDuration = selectedDuration
    }
    
    public var body: some View {
        Menu {
            ForEach(SelfDestructDuration.allCases) { duration in
                Button {
                    // Add haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    
                    selectedDuration = duration
                } label: {
                    HStack {
                        Image(systemName: duration.icon)
                        VStack(alignment: .leading, spacing: SpacingTokens.xxs) {
                            Text(duration.rawValue)
                                .font(TypographyScale.callout)
                            Text(duration.description)
                                .font(TypographyScale.caption2)
                                .foregroundColor(ColorTokens.secondaryText)
                        }
                        
                        if selectedDuration == duration {
                            Spacer()
                            Image(systemName: "checkmark")
                                .foregroundColor(ColorTokens.agoraBrand)
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: SpacingTokens.xs) {
                Image(systemName: selectedDuration.icon)
                    .font(TypographyScale.callout)
                
                Text(selectedDuration == .none ? "Self-destruct" : selectedDuration.rawValue)
                    .font(TypographyScale.callout)
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 10))
                    .foregroundColor(ColorTokens.tertiaryText)
            }
            .foregroundColor(selectedDuration == .none ? ColorTokens.secondaryText : ColorTokens.agoraBrand)
            .padding(.vertical, SpacingTokens.sm)
            .padding(.horizontal, SpacingTokens.md)
            .background(
                selectedDuration == .none 
                    ? Color.clear 
                    : ColorTokens.agoraBrand.opacity(0.1),
                in: RoundedRectangle(cornerRadius: BorderRadiusTokens.sm)
            )
            .overlay(
                RoundedRectangle(cornerRadius: BorderRadiusTokens.sm)
                    .stroke(
                        selectedDuration == .none 
                            ? ColorTokens.separator.opacity(0.3) 
                            : ColorTokens.agoraBrand.opacity(0.3), 
                        lineWidth: 1
                    )
            )
            .frame(minHeight: 44) // Ensure 44pt minimum height
        }
        .accessibilityLabel("Self-destruct duration")
        .accessibilityHint("Choose when this post should automatically delete")
        .accessibilityValue(selectedDuration.rawValue)
    }
}

#Preview("Self-Destruct Picker") {
    VStack(spacing: SpacingTokens.lg) {
        SelfDestructPicker(selectedDuration: .constant(.none))
        SelfDestructPicker(selectedDuration: .constant(.twentyFourHours))
        SelfDestructPicker(selectedDuration: .constant(.threeDays))
        SelfDestructPicker(selectedDuration: .constant(.oneWeek))
    }
    .padding()
}

