//
//  AppearancePreference.swift
//  AppFoundation
//
//  Created by Agora on 10/15/25.
//

import Foundation
import SwiftUI

// MARK: - AppearanceMode

public enum AppearanceMode: String, Sendable, Codable {
    case light
    case dark
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
            return .light // Default to light
        }
        return mode
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
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        for window in windowScene.windows {
            window.overrideUserInterfaceStyle = mode == .dark ? .dark : .light
        }
    }
}

