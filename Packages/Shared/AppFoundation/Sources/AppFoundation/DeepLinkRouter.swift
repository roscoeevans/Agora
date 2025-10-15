//
//  DeepLinkRouter.swift
//  Agora
//
//  Deep link URL parsing for navigation
//

import Foundation

public enum DeepLinkRouter {
    // Example: agora://home/post/<uuid>
    public static func decode(_ url: URL) -> (AppTab, [any Codable])? {
        guard url.scheme == "agora" else { return nil }
        
        switch url.host {
        case "home":
            if url.pathComponents.contains("post"),
               let idString = url.pathComponents.last,
               let id = UUID(uuidString: idString) {
                return (.home, [HomeRoute.post(id: id)])
            }
            if url.pathComponents.contains("profile"),
               let idString = url.pathComponents.last,
               let id = UUID(uuidString: idString) {
                return (.home, [HomeRoute.profile(id: id)])
            }
            return (.home, [])
            
        case "search":
            if url.pathComponents.contains("result"),
               let idString = url.pathComponents.last,
               let id = UUID(uuidString: idString) {
                return (.search, [SearchRoute.result(id: id)])
            }
            return (.search, [])
            
        case "messages":
            if url.pathComponents.contains("thread"),
               let idString = url.pathComponents.last,
               let id = UUID(uuidString: idString) {
                return (.messages, [MessagesRoute.thread(id: id)])
            }
            return (.messages, [])
            
        case "notifications":
            if url.pathComponents.contains("detail"),
               let idString = url.pathComponents.last,
               let id = UUID(uuidString: idString) {
                return (.notifications, [NotificationsRoute.detail(id: id)])
            }
            return (.notifications, [])
            
        case "profile":
            if url.pathComponents.contains("settings") {
                return (.profile, [ProfileRoute.settings])
            }
            if url.pathComponents.contains("followers") {
                return (.profile, [ProfileRoute.followers])
            }
            return (.profile, [])
            
        default:
            return nil
        }
    }
}

