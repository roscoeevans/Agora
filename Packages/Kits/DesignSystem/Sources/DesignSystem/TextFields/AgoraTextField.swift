//
//  AgoraTextField.swift
//  Agora
//
//  Created by Agora Team on 2024.
//

import SwiftUI
import UIKitBridge

/// A standardized text field component for the Agora design system.
///
/// AgoraTextField provides consistent styling, accessibility support, and validation
/// states following Apple's Human Interface Guidelines.
///
/// Example usage:
/// ```swift
/// AgoraTextField("Enter your email", text: $email, style: .standard)
/// ```
@available(iOS 26.0, *)
public struct AgoraTextField: View {
    /// Visual style variants for the text field.
    public enum Style {
        /// Standard text field with subtle background
        case standard
        /// Prominent text field with stronger visual emphasis
        case prominent
        /// Compact text field for tight layouts
        case compact
    }
    
    /// Validation state for the text field.
    public enum ValidationState {
        /// Default state - no validation feedback
        case `default`
        /// Success state - shows success styling
        case success
        /// Error state - shows error styling and message
        case error(String)
        /// Warning state - shows warning styling
        case warning
    }
    
    let title: String
    @Binding var text: String
    let style: Style
    let validationState: ValidationState
    let isSecure: Bool
    let keyboardType: DesignSystemBridge.KeyboardType
    let contentType: DesignSystemBridge.TextContentType
    let onCommit: () -> Void
    
    /// Creates a new AgoraTextField.
    ///
    /// - Parameters:
    ///   - title: The placeholder text for the text field
    ///   - text: Binding to the text field's value
    ///   - style: The visual style of the text field. Defaults to `.standard`
    ///   - validationState: The validation state. Defaults to `.default`
    ///   - isSecure: Whether the text field is secure. Defaults to `false`
    ///   - keyboardType: The keyboard type. Defaults to `.default`
    ///   - textContentType: The text content type for autofill. Defaults to `nil`
    ///   - onCommit: Action to perform when the user commits the text. Defaults to empty closure
    public init(
        _ title: String,
        text: Binding<String>,
        style: Style = .standard,
        validationState: ValidationState = .default,
        isSecure: Bool = false,
        keyboardType: DesignSystemBridge.KeyboardType = .default,
        contentType: DesignSystemBridge.TextContentType = .none,
        onCommit: @escaping () -> Void = {}
    ) {
        self.title = title
        self._text = text
        self.style = style
        self.validationState = validationState
        self.isSecure = isSecure
        self.keyboardType = keyboardType
        self.contentType = contentType
        self.onCommit = onCommit
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.xs) {
            if isSecure {
                SecureField(title, text: $text, onCommit: onCommit)
                    .textFieldStyle(AgoraTextFieldStyle(
                        style: style,
                        validationState: validationState
                    ))
                    #if canImport(UIKit)
                    .keyboardType(keyboardType.uiKeyboardType)
                    .textContentType(contentType.uiTextContentType)
                    #endif
            } else {
                TextField(title, text: $text, onCommit: onCommit)
                    .textFieldStyle(AgoraTextFieldStyle(
                        style: style,
                        validationState: validationState
                    ))
                    #if canImport(UIKit)
                    .keyboardType(keyboardType.uiKeyboardType)
                    .textContentType(contentType.uiTextContentType)
                    #endif
            }
            
            // Validation message
            if case .error(let message) = validationState {
                Text(message)
                    .font(TypographyScale.caption1)
                    .foregroundColor(ColorTokens.error)
                    .padding(.leading, SpacingTokens.xs)
            }
        }
    }
}

// MARK: - Custom Text Field Style
@available(iOS 26.0, *)
@MainActor
private struct AgoraTextFieldStyle: @MainActor TextFieldStyle {
    let style: AgoraTextField.Style
    let validationState: AgoraTextField.ValidationState
    
    @MainActor
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(TypographyScale.body)
            .foregroundColor(ColorTokens.primaryText)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(backgroundColor)
            .cornerRadius(BorderRadiusTokens.sm)
            .overlay(
                RoundedRectangle(cornerRadius: BorderRadiusTokens.sm)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .agoraShadow(ShadowTokens.subtle)
    }
    
    private var horizontalPadding: CGFloat {
        switch style {
        case .standard, .prominent: return SpacingTokens.md
        case .compact: return SpacingTokens.sm
        }
    }
    
    private var verticalPadding: CGFloat {
        switch style {
        case .standard, .prominent: return SpacingTokens.sm
        case .compact: return SpacingTokens.xs
        }
    }
    
    private var backgroundColor: Color {
        switch style {
        case .standard: return ColorTokens.secondaryBackground
        case .prominent: return ColorTokens.tertiaryBackground
        case .compact: return ColorTokens.secondaryBackground
        }
    }
    
    private var borderColor: Color {
        switch validationState {
        case .default: return ColorTokens.separator.opacity(0.3)
        case .success: return ColorTokens.success
        case .error: return ColorTokens.error
        case .warning: return ColorTokens.warning
        }
    }
    
    private var borderWidth: CGFloat {
        switch validationState {
        case .default: return 1
        case .success, .error, .warning: return 2
        }
    }
}

#if DEBUG
@available(iOS 26.0, *)
struct AgoraTextField_Previews: PreviewProvider {
    @State private static var standardText = ""
    @State private static var errorText = "Invalid input"
    @State private static var successText = "Valid input"
    
    static var previews: some View {
        VStack(spacing: SpacingTokens.lg) {
            // Different styles
            AgoraTextField("Standard Text Field", text: $standardText)
            AgoraTextField("Prominent Text Field", text: $standardText, style: .prominent)
            AgoraTextField("Compact Text Field", text: $standardText, style: .compact)
            
            Divider()
            
            // Different validation states
            AgoraTextField("Success State", text: $successText, validationState: .success)
            AgoraTextField("Error State", text: $errorText, validationState: .error("This field is required"))
            AgoraTextField("Warning State", text: $standardText, validationState: .warning)
            
            Divider()
            
            // Secure field
            AgoraTextField("Password", text: $standardText, isSecure: true)
        }
        .padding(SpacingTokens.md)
        .background(ColorTokens.background)
        .previewDisplayName("Light Mode")
        
        VStack(spacing: SpacingTokens.lg) {
            // Different styles
            AgoraTextField("Standard Text Field", text: $standardText)
            AgoraTextField("Prominent Text Field", text: $standardText, style: .prominent)
            AgoraTextField("Compact Text Field", text: $standardText, style: .compact)
            
            Divider()
            
            // Different validation states
            AgoraTextField("Success State", text: $successText, validationState: .success)
            AgoraTextField("Error State", text: $errorText, validationState: .error("This field is required"))
            AgoraTextField("Warning State", text: $standardText, validationState: .warning)
            
            Divider()
            
            // Secure field
            AgoraTextField("Password", text: $standardText, isSecure: true)
        }
        .padding(SpacingTokens.md)
        .background(ColorTokens.background)
        .preferredColorScheme(.dark)
        .previewDisplayName("Dark Mode")
    }
}
#endif
