//
//  DesignSystemBridge.swift
//  UIKitBridge
//
//  Created by Agora Team on 2024.
//

import SwiftUI

#if canImport(UIKit)
import UIKit

/// UIKit bridge utilities for design system configuration
@available(iOS 26.0, macOS 10.15, *)
public struct DesignSystemBridge: Sendable {
    /// Shared instance of the design system bridge
    @MainActor
    public static let shared = DesignSystemBridge()
    
    private init() {}
    
    // MARK: - Dark Mode Configuration
    
    /// Configures the app to use dark mode as the default
    /// Call this in your App's init or SceneDelegate
    public static func configureDarkModeAsDefault() {
        #if canImport(UIKit)
        // Set dark mode as default for the entire app
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.forEach { window in
                window.overrideUserInterfaceStyle = .dark
            }
        }
        #endif
    }
    
    /// Forces the app to use dark mode regardless of system setting
    public static func forceDarkMode() {
        #if canImport(UIKit)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.forEach { window in
                window.overrideUserInterfaceStyle = .dark
            }
        }
        #endif
    }
    
    /// Forces the app to use light mode regardless of system setting
    public static func forceLightMode() {
        #if canImport(UIKit)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.forEach { window in
                window.overrideUserInterfaceStyle = .light
            }
        }
        #endif
    }
    
    /// Allows the app to follow system appearance settings
    public static func followSystemAppearance() {
        #if canImport(UIKit)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.forEach { window in
                window.overrideUserInterfaceStyle = .unspecified
            }
        }
        #endif
    }
    
    /// Checks if the app is currently in dark mode
    public static var isDarkMode: Bool {
        #if canImport(UIKit)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            return window.traitCollection.userInterfaceStyle == .dark
        }
        return false
        #else
        return false
        #endif
    }
    
    /// Gets the current color scheme
    public static var currentColorScheme: ColorScheme? {
        #if canImport(UIKit)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            switch window.traitCollection.userInterfaceStyle {
            case .dark:
                return .dark
            case .light:
                return .light
            case .unspecified:
                return nil
            @unknown default:
                return nil
            }
        }
        return nil
        #else
        return nil
        #endif
    }
    
    // MARK: - Accessibility
    
    /// Checks if the system has increased contrast enabled (Darker System Colors)
    public static var isDarkerSystemColorsEnabled: Bool {
        #if canImport(UIKit)
        return UIAccessibility.isDarkerSystemColorsEnabled
        #else
        return false
        #endif
    }
    
    /// Checks if Reduce Motion is enabled
    public static var isReduceMotionEnabled: Bool {
        #if canImport(UIKit)
        return UIAccessibility.isReduceMotionEnabled
        #else
        return false
        #endif
    }
    
    /// Checks if VoiceOver is running
    public static var isVoiceOverRunning: Bool {
        #if canImport(UIKit)
        return UIAccessibility.isVoiceOverRunning
        #else
        return false
        #endif
    }
    
    /// Checks if Switch Control is enabled
    public static var isSwitchControlRunning: Bool {
        #if canImport(UIKit)
        return UIAccessibility.isSwitchControlRunning
        #else
        return false
        #endif
    }
    
    /// Checks if Bold Text is enabled
    public static var isBoldTextEnabled: Bool {
        #if canImport(UIKit)
        return UIAccessibility.isBoldTextEnabled
        #else
        return false
        #endif
    }
    
    // MARK: - System Colors
    
    /// Gets the system secondary background color
    public static var secondarySystemBackground: Color {
        #if canImport(UIKit)
        return Color(UIColor.secondarySystemBackground)
        #else
        return Color.gray.opacity(0.1)
        #endif
    }
    
    /// Gets the system tertiary background color
    public static var tertiarySystemBackground: Color {
        #if canImport(UIKit)
        return Color(UIColor.tertiarySystemBackground)
        #else
        return Color.gray.opacity(0.05)
        #endif
    }
    
    /// Gets the system grouped background color
    public static var systemGroupedBackground: Color {
        #if canImport(UIKit)
        return Color(UIColor.systemGroupedBackground)
        #else
        return Color.gray.opacity(0.1)
        #endif
    }
    
    /// Gets the system green color
    public static var systemGreen: Color {
        #if canImport(UIKit)
        return Color(UIColor.systemGreen)
        #else
        return Color.green
        #endif
    }
    
    /// Gets the system orange color
    public static var systemOrange: Color {
        #if canImport(UIKit)
        return Color(UIColor.systemOrange)
        #else
        return Color.orange
        #endif
    }
    
    /// Gets the system red color
    public static var systemRed: Color {
        #if canImport(UIKit)
        return Color(UIColor.systemRed)
        #else
        return Color.red
        #endif
    }
    
    // MARK: - Haptic Feedback
    
    /// Triggers a light impact haptic feedback
    public static func lightImpact() {
        #if canImport(UIKit)
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        #endif
    }
    
    /// Triggers a medium impact haptic feedback
    public static func mediumImpact() {
        #if canImport(UIKit)
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        #endif
    }
    
    /// Triggers a heavy impact haptic feedback
    public static func heavyImpact() {
        #if canImport(UIKit)
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
        #endif
    }
    
    // MARK: - Pasteboard
    
    /// Copies a URL to the pasteboard
    public static func copyURL(_ url: URL) {
        #if canImport(UIKit)
        UIPasteboard.general.url = url
        #endif
    }
    
    /// Copies text to the pasteboard
    public static func copyText(_ text: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = text
        #endif
    }
    
    // MARK: - Text Input Types
    
    /// Text input keyboard types
    public enum KeyboardType: Int, CaseIterable {
        case `default` = 0
        case asciiCapable = 1
        case numbersAndPunctuation = 2
        case URL = 3
        case numberPad = 4
        case phonePad = 5
        case namePhonePad = 6
        case emailAddress = 7
        case decimalPad = 8
        case twitter = 9
        case webSearch = 10
        case asciiCapableNumberPad = 11
        
        #if canImport(UIKit)
        public var uiKeyboardType: UIKeyboardType {
            switch self {
            case .default: return .default
            case .asciiCapable: return .asciiCapable
            case .numbersAndPunctuation: return .numbersAndPunctuation
            case .URL: return .URL
            case .numberPad: return .numberPad
            case .phonePad: return .phonePad
            case .namePhonePad: return .namePhonePad
            case .emailAddress: return .emailAddress
            case .decimalPad: return .decimalPad
            case .twitter: return .twitter
            case .webSearch: return .webSearch
            case .asciiCapableNumberPad: return .asciiCapableNumberPad
            }
        }
        #endif
    }
    
    /// Text content types
    public enum TextContentType: String, CaseIterable {
        case none = ""
        case name = "name"
        case givenName = "givenName"
        case familyName = "familyName"
        case middleName = "middleName"
        case namePrefix = "namePrefix"
        case nameSuffix = "nameSuffix"
        case nickname = "nickname"
        case jobTitle = "jobTitle"
        case organizationName = "organizationName"
        case location = "location"
        case fullStreetAddress = "fullStreetAddress"
        case streetAddressLine1 = "streetAddressLine1"
        case streetAddressLine2 = "streetAddressLine2"
        case addressCity = "addressCity"
        case addressState = "addressState"
        case addressCityAndState = "addressCityAndState"
        case postalCode = "postalCode"
        case countryName = "countryName"
        case telephoneNumber = "telephoneNumber"
        case emailAddress = "emailAddress"
        case URL = "URL"
        case creditCardNumber = "creditCardNumber"
        case username = "username"
        case password = "password"
        case newPassword = "newPassword"
        case oneTimeCode = "oneTimeCode"
        
        #if canImport(UIKit)
        public var uiTextContentType: UITextContentType? {
            if self == .none { return nil }
            return UITextContentType(rawValue: self.rawValue)
        }
        #endif
    }
}

#else
// Fallback for platforms without UIKit
@available(iOS 26.0, macOS 10.15, *)
public struct DesignSystemBridge: Sendable {
    /// Shared instance of the design system bridge
    @MainActor
    public static let shared = DesignSystemBridge()
    
    private init() {}
    
    // MARK: - Dark Mode Configuration
    
    public static func configureDarkModeAsDefault() {
        // No-op for non-UIKit platforms
    }
    
    public static func forceDarkMode() {
        // No-op for non-UIKit platforms
    }
    
    public static func forceLightMode() {
        // No-op for non-UIKit platforms
    }
    
    public static func followSystemAppearance() {
        // No-op for non-UIKit platforms
    }
    
    public static var isDarkMode: Bool {
        return false
    }
    
    public static var currentColorScheme: ColorScheme? {
        return nil
    }
    
    // MARK: - Accessibility
    
    public static var isDarkerSystemColorsEnabled: Bool {
        return false
    }
    
    public static var isReduceMotionEnabled: Bool {
        return false
    }
    
    public static var isVoiceOverRunning: Bool {
        return false
    }
    
    public static var isSwitchControlRunning: Bool {
        return false
    }
    
    public static var isBoldTextEnabled: Bool {
        return false
    }
    
    // MARK: - System Colors
    
    public static var secondarySystemBackground: Color {
        return Color.gray.opacity(0.1)
    }
    
    public static var tertiarySystemBackground: Color {
        return Color.gray.opacity(0.05)
    }
    
    public static var systemGroupedBackground: Color {
        return Color.gray.opacity(0.1)
    }
    
    public static var systemGreen: Color {
        return Color.green
    }
    
    public static var systemOrange: Color {
        return Color.orange
    }
    
    public static var systemRed: Color {
        return Color.red
    }
    
    // MARK: - Haptic Feedback
    
    public static func lightImpact() {
        // No-op for non-UIKit platforms
    }
    
    public static func mediumImpact() {
        // No-op for non-UIKit platforms
    }
    
    public static func heavyImpact() {
        // No-op for non-UIKit platforms
    }
    
    // MARK: - Pasteboard
    
    public static func copyURL(_ url: URL) {
        // No-op for non-UIKit platforms
    }
    
    public static func copyText(_ text: String) {
        // No-op for non-UIKit platforms
    }
    
    // MARK: - Text Input Types
    
    public enum KeyboardType: Int, CaseIterable {
        case `default` = 0
        case asciiCapable = 1
        case numbersAndPunctuation = 2
        case URL = 3
        case numberPad = 4
        case phonePad = 5
        case namePhonePad = 6
        case emailAddress = 7
        case decimalPad = 8
        case twitter = 9
        case webSearch = 10
        case asciiCapableNumberPad = 11
    }
    
    public enum TextContentType: String, CaseIterable {
        case none = ""
        case name = "name"
        case givenName = "givenName"
        case familyName = "familyName"
        case middleName = "middleName"
        case namePrefix = "namePrefix"
        case nameSuffix = "nameSuffix"
        case nickname = "nickname"
        case jobTitle = "jobTitle"
        case organizationName = "organizationName"
        case location = "location"
        case fullStreetAddress = "fullStreetAddress"
        case streetAddressLine1 = "streetAddressLine1"
        case streetAddressLine2 = "streetAddressLine2"
        case addressCity = "addressCity"
        case addressState = "addressState"
        case addressCityAndState = "addressCityAndState"
        case postalCode = "postalCode"
        case countryName = "countryName"
        case telephoneNumber = "telephoneNumber"
        case emailAddress = "emailAddress"
        case URL = "URL"
        case creditCardNumber = "creditCardNumber"
        case username = "username"
        case password = "password"
        case newPassword = "newPassword"
        case oneTimeCode = "oneTimeCode"
    }
}

#endif
