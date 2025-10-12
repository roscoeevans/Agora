import SwiftUI
import DesignSystem
import AuthenticationServices

/// Welcome screen with Sign in with Apple
public struct WelcomeView: View {
    @Environment(AuthStateManager.self) private var authManager
    @State private var isSigningIn = false
    @AccessibilityFocusState private var isFocused: Bool
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    ColorTokens.background,
                    ColorTokens.background.opacity(0.8)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Logo and branding
                brandingSection
                
                Spacer()
                
                // Sign in button
                signInSection
                    .padding(.bottom, 48)
            }
            .padding(.horizontal, 24)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Welcome to Agora")
    }
    
    // MARK: - Branding Section
    
    private var brandingSection: some View {
        VStack(spacing: 24) {
            // App icon or logo
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 80))
                .foregroundStyle(ColorTokens.primary)
                .symbolRenderingMode(.hierarchical)
                .accessibilityHidden(true)
            
            // App name
            Text("Agora")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(ColorTokens.primaryText)
                .accessibilityAddTraits(.isHeader)
            
            // Tagline
            Text("A human-only social platform")
                .font(.title3)
                .foregroundStyle(ColorTokens.secondaryText)
                .multilineTextAlignment(.center)
                .accessibilityFocused($isFocused)
        }
        .padding(.horizontal, 32)
    }
    
    // MARK: - Sign In Section
    
    private var signInSection: some View {
        VStack(spacing: 16) {
            // Sign in with Apple button
            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                Task {
                    await handleSignInResult(result)
                }
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 56)
            .cornerRadius(12)
            .accessibilityLabel("Sign in with Apple")
            .accessibilityHint("Sign in to Agora using your Apple ID")
            
            // Privacy note
            Text("We use Apple Sign In to verify you're human")
                .font(.caption)
                .foregroundStyle(ColorTokens.tertiaryText)
                .multilineTextAlignment(.center)
                .accessibilityLabel("Privacy note")
        }
        .disabled(isSigningIn)
        .opacity(isSigningIn ? 0.6 : 1.0)
    }
    
    // MARK: - Actions
    
    private func handleSignInResult(_ result: Result<ASAuthorization, Error>) {
        Task {
            isSigningIn = true
            defer { isSigningIn = false }
            
            switch result {
            case .success:
                do {
                    try await authManager.signInWithApple()
                } catch {
                    // Show error alert
                    print("Sign in failed: \(error.localizedDescription)")
                }
                
            case .failure(let error):
                // User cancelled or error occurred
                print("Sign in error: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Preview

#Preview {
    WelcomeView()
        .environment(AuthStateManager())
}

