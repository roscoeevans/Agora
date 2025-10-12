import SwiftUI
import DesignSystem

/// Onboarding flow for creating user profile
public struct OnboardingView: View {
    @Environment(AuthStateManager.self) private var authManager
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    @State private var currentStep: OnboardingStep = .handle
    @State private var handle = ""
    @State private var displayHandle = ""
    @State private var displayName = ""
    @State private var isHandleValid = false
    @State private var isCreating = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                // Background
                ColorTokens.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Progress indicator
                        progressIndicator
                        
                        // Current step content
                        currentStepView
                            .animation(.easeInOut(duration: 0.3), value: currentStep)
                        
                        Spacer()
                    }
                    .padding(24)
                }
                
                // Bottom navigation
                VStack {
                    Spacer()
                    navigationButtons
                        .padding(24)
                        .background(.ultraThinMaterial)
                }
            }
            .navigationTitle("Create Profile")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Progress Indicator
    
    private var progressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(OnboardingStep.allCases, id: \.self) { step in
                Capsule()
                    .fill(step.rawValue <= currentStep.rawValue ? ColorTokens.primary : ColorTokens.separator)
                    .frame(height: 4)
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
        .frame(maxWidth: 200)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(currentStep.rawValue + 1) of \(OnboardingStep.allCases.count)")
    }
    
    // MARK: - Current Step View
    
    @ViewBuilder
    private var currentStepView: some View {
        switch currentStep {
        case .handle:
            HandleInputView(
                handle: $handle,
                displayHandle: $displayHandle,
                isValid: $isHandleValid,
                validator: authManager.getValidator()
            )
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
            
        case .displayName:
            displayNameStep
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
        }
    }
    
    // MARK: - Display Name Step
    
    private var displayNameStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What's Your Name?")
                .font(.title2.weight(.semibold))
                .foregroundStyle(ColorTokens.primaryText)
                .accessibilityAddTraits(.isHeader)
            
            Text("This is your display name that appears on your profile")
                .font(.body)
                .foregroundStyle(ColorTokens.secondaryText)
            
            TextField("Display Name", text: $displayName)
                .font(.title3)
                .padding(16)
                .background(ColorTokens.secondaryBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(ColorTokens.separator, lineWidth: 1)
                )
                .accessibilityLabel("Display name input")
                .accessibilityHint("Enter your full name or display name")
            
            // Character count
            HStack {
                Spacer()
                Text("\(displayName.count)/50")
                    .font(.caption)
                    .foregroundStyle(displayName.count > 50 ? .red : ColorTokens.tertiaryText)
            }
            
            // Preview
            if !displayName.isEmpty && !displayHandle.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Preview")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(ColorTokens.secondaryText)
                    
                    HStack(spacing: 12) {
                        Circle()
                            .fill(ColorTokens.primary.opacity(0.2))
                            .frame(width: 48, height: 48)
                            .overlay(
                                Text(String(displayName.prefix(1)))
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(ColorTokens.primary)
                            )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(displayName)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(ColorTokens.primaryText)
                            
                            Text("@\(displayHandle)")
                                .font(.subheadline)
                                .foregroundStyle(ColorTokens.secondaryText)
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(ColorTokens.secondaryBackground)
                    .cornerRadius(12)
                }
            }
        }
    }
    
    // MARK: - Navigation Buttons
    
    private var navigationButtons: some View {
        HStack(spacing: 16) {
            // Back button
            if currentStep != .handle {
                Button {
                    withAnimation {
                        currentStep = currentStep.previous ?? .handle
                    }
                } label: {
                    Text("Back")
                        .font(.body.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(ColorTokens.secondaryBackground)
                        .foregroundStyle(ColorTokens.primaryText)
                        .cornerRadius(12)
                }
                .accessibilityLabel("Go back to previous step")
            }
            
            // Continue / Create button
            Button {
                handleContinue()
            } label: {
                HStack {
                    if isCreating {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    } else {
                        Text(currentStep.nextButtonTitle)
                            .font(.body.weight(.semibold))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(canContinue ? ColorTokens.primary : ColorTokens.primary.opacity(0.5))
                .foregroundStyle(.white)
                .cornerRadius(12)
            }
            .disabled(!canContinue || isCreating)
            .accessibilityLabel(currentStep.nextButtonTitle)
            .accessibilityHint(canContinue ? "Tap to continue" : "Complete current step first")
        }
        .padding(.horizontal, dynamicTypeSize > .large ? 16 : 0)
    }
    
    // MARK: - Helper Properties
    
    private var canContinue: Bool {
        switch currentStep {
        case .handle:
            return isHandleValid && !handle.isEmpty && !displayHandle.isEmpty
        case .displayName:
            return !displayName.isEmpty && displayName.count <= 50
        }
    }
    
    // MARK: - Actions
    
    private func handleContinue() {
        switch currentStep {
        case .handle:
            withAnimation {
                currentStep = .displayName
            }
            
        case .displayName:
            Task {
                await createProfile()
            }
        }
    }
    
    private func createProfile() async {
        isCreating = true
        
        do {
            try await authManager.createProfile(
                handle: handle,
                displayHandle: displayHandle,
                displayName: displayName
            )
            
            // Success! AuthStateManager will update state
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isCreating = false
    }
}

// MARK: - Onboarding Step

enum OnboardingStep: Int, CaseIterable {
    case handle = 0
    case displayName = 1
    
    var nextButtonTitle: String {
        switch self {
        case .handle:
            return "Continue"
        case .displayName:
            return "Create Profile"
        }
    }
    
    var previous: OnboardingStep? {
        guard rawValue > 0 else { return nil }
        return OnboardingStep(rawValue: rawValue - 1)
    }
}

// MARK: - Preview

#Preview {
    OnboardingView()
        .environment(AuthStateManager())
}

