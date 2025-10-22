import SwiftUI
import DesignSystem
import AppFoundation
import Networking

/// View for handle input with real-time validation
public struct HandleInputView: View {
    @Binding var handle: String
    @Binding var displayHandle: String
    @Binding var isValid: Bool
    
    let validator: HandleValidator
    
    @State private var formatValidation: HandleFormatValidation = .valid
    @State private var availabilityStatus: AvailabilityStatus = .unchecked
    @State private var suggestions: [String] = []
    @FocusState private var isFocused: Bool
    
    public init(
        handle: Binding<String>,
        displayHandle: Binding<String>,
        isValid: Binding<Bool>,
        validator: HandleValidator
    ) {
        self._handle = handle
        self._displayHandle = displayHandle
        self._isValid = isValid
        self.validator = validator
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title
            Text("Choose Your Handle")
                .font(.title2.weight(.semibold))
                .foregroundStyle(ColorTokens.primaryText)
                .accessibilityAddTraits(.isHeader)
            
            // Description
            Text("This is how others will find and mention you")
                .font(.body)
                .foregroundStyle(ColorTokens.secondaryText)
            
            // Handle input field
            handleInputField
            
            // Validation feedback
            validationFeedback
            
            // Suggestions if handle is taken
            if !suggestions.isEmpty {
                suggestionsSection
            }
        }
        .onChange(of: displayHandle) { oldValue, newValue in
            // Update handle to lowercase version
            let lowercased = newValue.lowercased()
            handle = lowercased
            // Trigger validation immediately
            handleTextChange(lowercased)
        }
    }
    
    // MARK: - Handle Input Field
    
    private var handleInputField: some View {
        HStack(spacing: 12) {
            // @ prefix
            Text("@")
                .font(.title3.weight(.medium))
                .foregroundStyle(ColorTokens.secondaryText)
            
            // Text field
            TextField("yourhandle", text: $displayHandle)
                .font(.title3)
                .foregroundStyle(ColorTokens.primaryText)
                #if os(iOS)
                .textInputAutocapitalization(.never)
                #endif
                .autocorrectionDisabled()
                .focused($isFocused)
                .accessibilityLabel("Handle input")
                .accessibilityHint("Enter your desired handle, 3 to 30 characters")
                .onChange(of: displayHandle) { _, newValue in
                    // Limit to 30 characters
                    if newValue.count > 30 {
                        displayHandle = String(newValue.prefix(30))
                    }
                }
            
            // Status indicator
            statusIndicator
        }
        .padding(16)
        .background(ColorTokens.secondaryBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: 2)
        )
    }
    
    // MARK: - Status Indicator
    
    @ViewBuilder
    private var statusIndicator: some View {
        switch availabilityStatus {
        case .unchecked:
            EmptyView()
            
        case .checking:
            ProgressView()
                .controlSize(.small)
                .accessibilityLabel("Checking availability")
            
        case .available:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .accessibilityLabel("Handle available")
            
        case .unavailable:
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.red)
                .accessibilityLabel("Handle unavailable")
        }
    }
    
    // MARK: - Validation Feedback
    
    @ViewBuilder
    private var validationFeedback: some View {
        // Only show errors (unmet requirements), not success messages
        if let errorMessage = formatValidation.errorMessage {
            Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundStyle(.red)
                .accessibilityLabel("Error: \(errorMessage)")
        } else if case .unavailable = availabilityStatus {
            Label("This handle is already taken", systemImage: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundStyle(.red)
                .accessibilityLabel("Error: Handle is already taken")
        }
        
        // Character count (only show if approaching or exceeding limit)
        if handle.count > 25 || handle.count > 30 {
            HStack {
                Spacer()
                Text("\(handle.count)/30")
                    .font(.caption)
                    .foregroundStyle(handle.count > 30 ? .red : ColorTokens.tertiaryText)
                    .accessibilityLabel("\(handle.count) out of 30 characters")
            }
        }
    }
    
    // MARK: - Suggestions Section
    
    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Try these instead:")
                .font(.caption.weight(.medium))
                .foregroundStyle(ColorTokens.secondaryText)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(suggestions, id: \.self) { suggestion in
                        Button {
                            displayHandle = suggestion
                            handle = suggestion.lowercased()
                        } label: {
                            Text("@\(suggestion)")
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(ColorTokens.secondaryBackground)
                                .foregroundStyle(ColorTokens.primary)
                                .cornerRadius(16)
                        }
                        .accessibilityLabel("Suggestion: \(suggestion)")
                        .accessibilityHint("Tap to use this handle")
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Properties
    
    private var borderColor: Color {
        if isFocused {
            return ColorTokens.primary
        } else if formatValidation != .valid {
            return .red
        } else if case .unavailable = availabilityStatus {
            return .red
        } else if case .available = availabilityStatus {
            return .green
        }
        return ColorTokens.separator
    }
    
    // MARK: - Actions
    
    private func handleTextChange(_ newValue: String) {
        // Skip validation for empty handles
        guard !newValue.isEmpty else {
            formatValidation = .valid
            availabilityStatus = .unchecked
            isValid = false
            return
        }
        
        // Show progress immediately when validation starts
        availabilityStatus = .checking
        
        Task {
            // Validate format first
            let validation = await validator.validateFormat(newValue)
            await MainActor.run {
                formatValidation = validation
            }
            
            // If format is valid, check availability
            if validation == .valid {
                // Keep showing progress while checking availability
                do {
                    let availability = try await validator.checkAvailability(newValue)
                    await MainActor.run {
                        availabilityStatus = availability.available ? .available : .unavailable
                        suggestions = availability.suggestions
                        isValid = availability.available
                    }
                } catch {
                    await MainActor.run {
                        availabilityStatus = .unchecked
                        isValid = false
                    }
                }
            } else {
                await MainActor.run {
                    availabilityStatus = .unchecked
                    isValid = false
                }
            }
        }
    }
}

// MARK: - Availability Status

enum AvailabilityStatus {
    case unchecked
    case checking
    case available
    case unavailable
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var handle = ""
        @State private var displayHandle = ""
        @State private var isValid = false
        
        var body: some View {
            VStack {
                HandleInputView(
                    handle: $handle,
                    displayHandle: $displayHandle,
                    isValid: $isValid,
                    validator: HandleValidator(apiClient: ServiceProvider.shared.apiClient() as! any AgoraAPIClient)
                )
                .padding()
                
                Text("Handle: \(handle)")
                Text("Display: \(displayHandle)")
                Text("Valid: \(isValid ? "Yes" : "No")")
            }
        }
    }
    
    return PreviewWrapper()
}

