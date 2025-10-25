//
//  Routes.swift
//  Agora
//
//  iOS 26 Navigation - Tab-scoped route definitions
//

import Foundation

// Named AppTab to avoid conflict with SwiftUI.Tab
public enum AppTab: String, Hashable, Codable {
    case home, search, compose, messages, notifications, profile
}

public enum HomeRoute: Hashable, Codable {
    case post(id: UUID)
    case profile(id: UUID)
    case compose(quotePostId: String? = nil)
    case editHistory(postId: String, currentText: String)
    case fullscreenVideo(bundleId: String, videoUrl: String)
    case imageGallery(urls: [String], initialIndex: Int)
}

public enum SearchRoute: Hashable, Codable {
    case result(id: UUID)
}

public enum MessagesRoute: Hashable, Codable {
    case thread(id: UUID)
}

public enum NotificationsRoute: Hashable, Codable {
    case detail(id: UUID)
}

public enum ProfileRoute: Hashable, Codable {
    case settings
    case editProfile
    case followers
    case post(id: UUID)
    case profile(id: UUID)
}

public enum DMsRoute: Hashable, Codable {
    case list
    case conversation(id: UUID)
}

