//
//  MessageComposer.swift
//  UIKitBridge
//
//  SwiftUI wrapper for MFMessageComposeViewController (iMessage)
//

import SwiftUI

#if canImport(UIKit) && canImport(MessageUI)
import UIKit
import MessageUI

/// Delegate for handling message composition results
@available(iOS 26.0, *)
public final class MessageDelegate: NSObject, MFMessageComposeViewControllerDelegate, Sendable {
    public let onFinish: (@Sendable (MessageComposeResult) -> Void)?
    
    public init(onFinish: (@Sendable (MessageComposeResult) -> Void)? = nil) {
        self.onFinish = onFinish
        super.init()
    }
    
    public func messageComposeViewController(
        _ controller: MFMessageComposeViewController,
        didFinishWith result: MessageComposeResult
    ) {
        controller.dismiss(animated: true) { [weak self] in
            self?.onFinish?(result)
        }
    }
}

/// SwiftUI wrapper for MFMessageComposeViewController
/// Presents native iMessage composer with pre-filled content
@available(iOS 26.0, *)
public struct MessageComposer: UIViewControllerRepresentable {
    public let body: String
    public let recipients: [String]?
    public let onFinish: (@Sendable (MessageComposeResult) -> Void)?
    
    public init(
        body: String,
        recipients: [String]? = nil,
        onFinish: (@Sendable (MessageComposeResult) -> Void)? = nil
    ) {
        self.body = body
        self.recipients = recipients
        self.onFinish = onFinish
    }
    
    public func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let controller = MFMessageComposeViewController()
        controller.body = body
        if let recipients {
            controller.recipients = recipients
        }
        let delegate = MessageDelegate(onFinish: onFinish)
        controller.messageComposeDelegate = delegate
        // Store delegate in context to keep it alive
        context.coordinator.delegate = delegate
        return controller
    }
    
    public func updateUIViewController(
        _ uiViewController: MFMessageComposeViewController,
        context: Context
    ) {
        // No updates needed
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    public class Coordinator {
        var delegate: MessageDelegate?
    }
}
#endif

