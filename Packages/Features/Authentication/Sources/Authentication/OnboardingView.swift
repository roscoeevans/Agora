import SwiftUI
import DesignSystem
import UIKitBridge
#if canImport(UIKit)
import UIKit
#endif

/// Onboarding flow for creating user profile
public struct OnboardingView: View {
    @Environment(AuthStateManager.self) private var authManager
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    @State private var currentStep: OnboardingStep = .handle
    @State private var handle = ""
    @State private var displayHandle = ""
    @State private var displayName = ""
    @State private var profileImageData: Data?
    @State private var showImagePicker = false
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
                .background(ColorTokens.background)
                
                // Bottom navigation
                VStack {
                    Spacer()
                    navigationButtons
                        .padding(24)
                        .background(.ultraThinMaterial)
                }
            }
            .navigationTitle("Create Profile")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(ColorTokens.background, for: .navigationBar)
            #endif
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
        .preferredColorScheme(.dark)
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
        VStack(alignment: .leading, spacing: 20) {
            Text("What's Your Name?")
                .font(.title2.weight(.semibold))
                .foregroundStyle(ColorTokens.primaryText)
                .accessibilityAddTraits(.isHeader)
            
            Text("This is your display name that appears on your profile")
                .font(.body)
                .foregroundStyle(ColorTokens.secondaryText)
            
            // Profile picture upload (optional)
            VStack(spacing: 12) {
                Button {
                    showImagePicker = true
                } label: {
                    if let profileImageData = profileImageData {
                        // Convert Data to UIImage for SwiftUI display (UIKit conversion isolated in UI layer)
                        #if canImport(UIKit)
                        if let uiImage = UIImage(data: profileImageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(ColorTokens.primary, lineWidth: 2)
                                )
                        } else {
                            // Fallback for invalid image data
                            Circle()
                                .fill(ColorTokens.primary.opacity(0.2))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .foregroundColor(.primary)
                                        .font(.title2)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(ColorTokens.primary, lineWidth: 2)
                                )
                        }
                        #else
                        // Fallback for non-UIKit platforms
                        Circle()
                            .fill(ColorTokens.primary.opacity(0.2))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.primary)
                                    .font(.title2)
                            )
                            .overlay(
                                Circle()
                                    .stroke(ColorTokens.primary, lineWidth: 2)
                            )
                        #endif
                    } else {
                        ZStack {
                            Circle()
                                .fill(ColorTokens.secondaryBackground)
                                .frame(width: 80, height: 80)
                            
                            VStack(spacing: 4) {
                                Image(systemName: "person.crop.circle.fill.badge.plus")
                                    .font(.system(size: 32))
                                    .foregroundStyle(ColorTokens.secondaryText)
                            }
                        }
                    }
                }
                .accessibilityLabel("Add profile picture")
                .accessibilityHint("Optional. Tap to select a photo")
                
                Text("Add Photo")
                    .font(.caption)
                    .foregroundStyle(ColorTokens.secondaryText)
                
                if profileImageData != nil {
                    Button("Remove Photo", role: .destructive) {
                        profileImageData = nil
                    }
                    .font(.caption)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            
            // Display name input - allows spaces, emojis, any characters
            TextField("Display Name", text: $displayName, axis: .vertical)
                .font(.title3)
                .padding(16)
                .background(ColorTokens.secondaryBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(ColorTokens.separator, lineWidth: 1)
                )
                #if os(iOS)
                .textInputAutocapitalization(.never)
                #endif
                .autocorrectionDisabled()
                .accessibilityLabel("Display name input")
                .accessibilityHint("Enter your full name, can include spaces, emojis, and special characters")
                .onChange(of: displayName) { _, newValue in
                    // Limit to 64 characters (Instagram limit)
                    if newValue.count > 64 {
                        displayName = String(newValue.prefix(64))
                    }
                }
            
            // Character count (only show when approaching limit)
            if displayName.count > 50 || displayName.count > 64 {
                HStack {
                    Spacer()
                    Text("\(displayName.count)/64")
                        .font(.caption)
                        .foregroundStyle(displayName.count > 64 ? .red : ColorTokens.tertiaryText)
                }
            }
            
            // Preview
            if !displayName.isEmpty && !displayHandle.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Preview")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(ColorTokens.secondaryText)
                    
                    HStack(spacing: 12) {
                        // Profile picture or initial
                        if let profileImageData = profileImageData {
                            // Convert Data to UIImage for SwiftUI display (UIKit conversion isolated in UI layer)
                            #if canImport(UIKit)
                            if let uiImage = UIImage(data: profileImageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 48, height: 48)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(ColorTokens.primary.opacity(0.2))
                                    .frame(width: 48, height: 48)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .foregroundColor(.primary)
                                            .font(.caption)
                                    )
                            }
                            #else
                            Circle()
                                .fill(ColorTokens.primary.opacity(0.2))
                                .frame(width: 48, height: 48)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .foregroundColor(.primary)
                                        .font(.caption)
                                )
                            #endif
                        } else {
                            Circle()
                                .fill(ColorTokens.primary.opacity(0.2))
                                .frame(width: 48, height: 48)
                                .overlay(
                                    Text(String(displayName.prefix(1)))
                                        .font(.title3.weight(.semibold))
                                        .foregroundStyle(ColorTokens.primary)
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(displayName)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(ColorTokens.primaryText)
                                .lineLimit(1)
                            
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
        .sheet(isPresented: $showImagePicker) {
            #if os(iOS)
            ImageDataPickerBridge(imageData: $profileImageData)
            #else
            Text("Image picker not available on macOS")
            #endif
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
            return !displayName.isEmpty && displayName.count <= 64
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
                displayName: displayName,
                avatarImageData: profileImageData
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

