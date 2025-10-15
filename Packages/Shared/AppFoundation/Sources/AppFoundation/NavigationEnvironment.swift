//
//  NavigationEnvironment.swift
//  AppFoundation
//
//  Environment keys for navigation actions
//

import SwiftUI

// MARK: - Navigation Actions

public struct NavigateToPost: @unchecked Sendable {
    public let action: @Sendable (UUID) -> Void
    
    public init(action: @escaping @Sendable (UUID) -> Void) {
        self.action = action
    }
}

public struct NavigateToProfile: @unchecked Sendable {
    public let action: @Sendable (UUID) -> Void
    
    public init(action: @escaping @Sendable (UUID) -> Void) {
        self.action = action
    }
}

public struct NavigateToSearchResult: @unchecked Sendable {
    public let action: @Sendable (UUID) -> Void
    
    public init(action: @escaping @Sendable (UUID) -> Void) {
        self.action = action
    }
}

// MARK: - Environment Keys

private struct NavigateToPostKey: EnvironmentKey {
    static let defaultValue: NavigateToPost? = nil
}

private struct NavigateToProfileKey: EnvironmentKey {
    static let defaultValue: NavigateToProfile? = nil
}

private struct NavigateToSearchResultKey: EnvironmentKey {
    static let defaultValue: NavigateToSearchResult? = nil
}

// MARK: - Environment Values Extension

public extension EnvironmentValues {
    var navigateToPost: NavigateToPost? {
        get { self[NavigateToPostKey.self] }
        set { self[NavigateToPostKey.self] = newValue }
    }
    
    var navigateToProfile: NavigateToProfile? {
        get { self[NavigateToProfileKey.self] }
        set { self[NavigateToProfileKey.self] = newValue }
    }
    
    var navigateToSearchResult: NavigateToSearchResult? {
        get { self[NavigateToSearchResultKey.self] }
        set { self[NavigateToSearchResultKey.self] = newValue }
    }
}


