//
//  AppearancePreference.swift
//  AppFoundation
//
//  Created by Agora on 10/15/25.
//

import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - AppearanceMode

public enum AppearanceMode: String, Sendable, Codable {
    case light
    case dark
    case system
}

// MARK: - AppearancePreference Protocol

/// Protocol for managing app-wide appearance mode preference
///
/// This service follows DI guidelines:
/// - Protocol defined in AppFoundation for app-wide use
/// - Live implementation persists to UserDefaults
/// - MainActor-bound for UI updates
/// - Provides async stream for observing changes
public protocol AppearancePreference: Sendable {
    var currentMode: AppearanceMode { get }
    var effectiveMode: AppearanceMode { get }
    func setMode(_ mode: AppearanceMode) async
    func observeChanges() -> AsyncStream<AppearanceMode>
}

// MARK: - Live Implementation

public final class AppearancePreferenceLive: AppearancePreference, @unchecked Sendable {
    private let userDefaults: UserDefaults
    private let key = "agora.appearance.mode"
    
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    public var currentMode: AppearanceMode {
        guard let rawValue = userDefaults.string(forKey: key),
              let mode = AppearanceMode(rawValue: rawValue) else {
            return .system // Default to system appearance
        }
        return mode
    }
    
    public var effectiveMode: AppearanceMode {
        let mode = currentMode
        if mode == .system {
            return systemAppearanceMode
        }
        return mode
    }
    
    private var systemAppearanceMode: AppearanceMode {
        #if canImport(UIKit)
        if #available(iOS 13.0, *) {
            switch UITraitCollection.current.userInterfaceStyle {
            case .dark:
                return .dark
            case .light:
                return .light
            case .unspecified:
                return .light
            @unknown default:
                return .light
            }
        } else {
            return .light
        }
        #else
        return .light
        #endif
    }
    
    public func setMode(_ mode: AppearanceMode) async {
        userDefaults.set(mode.rawValue, forKey: key)
        await applyToWindows(mode)
    }
    
    public func observeChanges() -> AsyncStream<AppearanceMode> {
        let currentMode = self.currentMode
        return AsyncStream { continuation in
            continuation.yield(currentMode)
        }
    }
    
    @MainActor
    private func applyToWindows(_ mode: AppearanceMode) {
        #if canImport(UIKit)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        for window in windowScene.windows {
            switch mode {
            case .light:
                window.overrideUserInterfaceStyle = .light
            case .dark:
                window.overrideUserInterfaceStyle = .dark
            case .system:
                window.overrideUserInterfaceStyle = .unspecified
            }
        }
        #endif
    }
}

