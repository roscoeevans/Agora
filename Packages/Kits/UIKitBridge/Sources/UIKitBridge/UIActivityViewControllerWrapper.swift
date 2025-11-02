//
//  UIActivityViewControllerWrapper.swift
//  UIKitBridge
//
//  SwiftUI wrapper for native iOS share sheet
//

import SwiftUI

#if canImport(UIKit)
import UIKit

/// SwiftUI wrapper for UIActivityViewController (native iOS share sheet)
/// Used as fallback when MessageComposer is unavailable
@available(iOS 26.0, *)
public struct UIActivityViewControllerWrapper: UIViewControllerRepresentable {
    public let items: [Any]
    public let applicationActivities: [UIActivity]?
    
    public init(items: [Any], applicationActivities: [UIActivity]? = nil) {
        self.items = items
        self.applicationActivities = applicationActivities
    }
    
    public func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: applicationActivities
        )
        return controller
    }
    
    public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}
#endif

