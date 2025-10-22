//
//  SelfDestructPicker.swift
//  Agora
//
//  Self-destruct duration picker for posts
//

import SwiftUI
import UIKitBridge
import DesignSystem

/// Self-destruct duration options
public enum SelfDestructDuration: Identifiable {
    case none
    case twentyFourHours
    case threeDays
    case oneWeek
    case custom(Date)
    
    public var id: String { 
        switch self {
        case .none: return "Never"
        case .twentyFourHours: return "24 hours"
        case .threeDays: return "3 days"
        case .oneWeek: return "1 week"
        case .custom(let date): return "Custom \(date.formatted(date: .abbreviated, time: .shortened))"
        }
    }
    
    public var rawValue: String {
        switch self {
        case .none: return "Never"
        case .twentyFourHours: return "24 hours"
        case .threeDays: return "3 days"
        case .oneWeek: return "1 week"
        case .custom: return "Custom"
        }
    }
    
    // Static property for predefined cases
    public static var predefinedCases: [SelfDestructDuration] {
        [.none, .twentyFourHours, .threeDays, .oneWeek]
    }
    
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
        case .custom(let date):
            return date
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
        case .custom(let date):
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .full
            return "Deletes \(formatter.localizedString(for: date, relativeTo: Date()))"
        }
    }
    
    /// SF Symbol icon
    public var icon: String {
        switch self {
        case .none:
            return "infinity"
        case .twentyFourHours, .threeDays, .oneWeek, .custom:
            return "clock.badge.xmark"
        }
    }
}

/// Self-destruct duration picker component
public struct SelfDestructPicker: View {
    @Binding var selectedDuration: SelfDestructDuration
    @State private var isExpanded = false
    @State private var showingCustomDatePicker = false
    @State private var customDate = Date().addingTimeInterval(86400) // Default to 24 hours from now
    
    public init(selectedDuration: Binding<SelfDestructDuration>) {
        self._selectedDuration = selectedDuration
    }
    
    // Predefined duration cases (excluding custom)
    private var predefinedCases: [SelfDestructDuration] {
        SelfDestructDuration.predefinedCases
    }
    
    public var body: some View {
        Menu {
            predefinedOptionsMenu
            Divider()
            customOptionMenu
        } label: {
            pickerLabel
        }
        .accessibilityLabel("Self-destruct duration")
        .accessibilityHint("Choose when this post should automatically delete")
        .accessibilityValue(selectedDuration.rawValue)
        .sheet(isPresented: $showingCustomDatePicker) {
            CustomDatePickerSheet(
                selectedDate: $customDate,
                onDateSelected: { date in
                    selectedDuration = .custom(date)
                }
            )
        }
    }
    
    @ViewBuilder
    private var predefinedOptionsMenu: some View {
        ForEach(predefinedCases, id: \.id) { duration in
            Button {
                DesignSystemBridge.lightImpact()
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
                    
                    if isSelected(duration) {
                        Spacer()
                        Image(systemName: "checkmark")
                            .foregroundColor(ColorTokens.agoraBrand)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var customOptionMenu: some View {
        Button {
            DesignSystemBridge.lightImpact()
            showingCustomDatePicker = true
        } label: {
            HStack {
                Image(systemName: "calendar")
                VStack(alignment: .leading, spacing: SpacingTokens.xxs) {
                    Text("Custom")
                        .font(TypographyScale.callout)
                    Text("Pick a specific date & time")
                        .font(TypographyScale.caption2)
                        .foregroundColor(ColorTokens.secondaryText)
                }
                
                if case .custom = selectedDuration {
                    Spacer()
                    Image(systemName: "checkmark")
                        .foregroundColor(ColorTokens.agoraBrand)
                }
            }
        }
    }
    
    @ViewBuilder
    private var pickerLabel: some View {
        HStack(spacing: SpacingTokens.xs) {
            pickerIcon
            pickerText
            chevronIcon
        }
        .foregroundColor(pickerTextColor)
        .padding(.vertical, SpacingTokens.sm)
        .padding(.horizontal, SpacingTokens.md)
        .background(pickerBackground)
        .overlay(pickerBorder)
        .frame(minHeight: 44)
    }
    
    @ViewBuilder
    private var pickerIcon: some View {
        Image(systemName: selectedDuration.icon)
            .font(TypographyScale.callout)
    }
    
    @ViewBuilder
    private var pickerText: some View {
        Text(selectedDurationText)
            .font(TypographyScale.callout)
    }
    
    private var selectedDurationText: String {
        switch selectedDuration {
        case .none:
            return "Self-destruct"
        default:
            return selectedDuration.rawValue
        }
    }
    
    @ViewBuilder
    private var chevronIcon: some View {
        Image(systemName: "chevron.down")
            .font(.system(size: 10))
            .foregroundColor(ColorTokens.tertiaryText)
    }
    
    private var pickerTextColor: Color {
        switch selectedDuration {
        case .none:
            return ColorTokens.secondaryText
        default:
            return ColorTokens.agoraBrand
        }
    }
    
    @ViewBuilder
    private var pickerBackground: some View {
        Group {
            switch selectedDuration {
            case .none:
                Color.clear
            default:
                ColorTokens.agoraBrand.opacity(0.1)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: BorderRadiusTokens.sm))
    }
    
    @ViewBuilder
    private var pickerBorder: some View {
        RoundedRectangle(cornerRadius: BorderRadiusTokens.sm)
            .stroke(
                pickerBorderColor, 
                lineWidth: 1
            )
    }
    
    private var pickerBorderColor: Color {
        switch selectedDuration {
        case .none:
            return ColorTokens.separator.opacity(0.3)
        default:
            return ColorTokens.agoraBrand.opacity(0.3)
        }
    }
    
    // Helper function to check if a duration is selected
    private func isSelected(_ duration: SelfDestructDuration) -> Bool {
        switch (selectedDuration, duration) {
        case (.none, .none):
            return true
        case (.twentyFourHours, .twentyFourHours):
            return true
        case (.threeDays, .threeDays):
            return true
        case (.oneWeek, .oneWeek):
            return true
        case (.custom, _):
            return false
        case (_, .custom):
            return false
        default:
            return false
        }
    }
}

/// Custom date picker sheet for self-destruct
struct CustomDatePickerSheet: View {
    @Binding var selectedDate: Date
    let onDateSelected: (Date) -> Void
    @Environment(\.dismiss) private var dismiss
    
    private let minDate = Date()
    private let maxDate = Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: SpacingTokens.lg) {
                Text("Choose when to delete this post")
                    .font(TypographyScale.title3)
                    .foregroundColor(ColorTokens.primaryText)
                    .multilineTextAlignment(.center)
                
                DatePicker(
                    "Self-destruct date",
                    selection: $selectedDate,
                    in: minDate...maxDate,
                    displayedComponents: [.date, .hourAndMinute]
                )
                #if os(iOS)
                .datePickerStyle(.wheel)
                #endif
                .labelsHidden()
                
                Text("Post will be deleted on \(selectedDate.formatted(date: .abbreviated, time: .shortened))")
                    .font(TypographyScale.caption1)
                    .foregroundColor(ColorTokens.secondaryText)
                    .multilineTextAlignment(.center)
                
                Spacer()
            }
            .padding(SpacingTokens.lg)
            .navigationTitle("Custom Self-Destruct")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Set") {
                        onDateSelected(selectedDate)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
                #else
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Set") {
                        onDateSelected(selectedDate)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
                #endif
            }
        }
    }
}

#Preview("Self-Destruct Picker") {
    VStack(spacing: SpacingTokens.lg) {
        SelfDestructPicker(selectedDuration: .constant(.none))
        SelfDestructPicker(selectedDuration: .constant(.twentyFourHours))
        SelfDestructPicker(selectedDuration: .constant(.threeDays))
        SelfDestructPicker(selectedDuration: .constant(.oneWeek))
        SelfDestructPicker(selectedDuration: .constant(.custom(Date().addingTimeInterval(86400 * 2))))
    }
    .padding()
}

