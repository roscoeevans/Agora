import SwiftUI

/// Protocol for providing toast notification services
public protocol ToastsProviding: AnyObject {
    /// Show a toast notification
    func show(_ item: ToastItem) async
    
    /// Show a toast with basic parameters
    func show(
        _ message: LocalizedStringKey,
        kind: ToastKind,
        options: ToastOptions,
        action: ToastAction?
    ) async
    
    /// Dismiss a specific toast by ID
    func dismiss(id: ToastID) async
    
    /// Dismiss all currently queued and visible toasts
    func dismissAll() async
}

// MARK: - Convenience Methods

public extension ToastsProviding {
    /// Show a success toast
    func success(
        _ message: LocalizedStringKey,
        options: ToastOptions = .default(for: .success),
        action: ToastAction? = nil
    ) async {
        await show(ToastItem.success(message, options: options, action: action))
    }
    
    /// Show an error toast
    func error(
        _ message: LocalizedStringKey,
        options: ToastOptions = .default(for: .error),
        action: ToastAction? = nil
    ) async {
        await show(ToastItem.error(message, options: options, action: action))
    }
    
    /// Show an info toast
    func info(
        _ message: LocalizedStringKey,
        options: ToastOptions = .default(for: .info),
        action: ToastAction? = nil
    ) async {
        await show(ToastItem.info(message, options: options, action: action))
    }
    
    /// Show a warning toast
    func warning(
        _ message: LocalizedStringKey,
        options: ToastOptions = .default(for: .warning),
        action: ToastAction? = nil
    ) async {
        await show(ToastItem.warning(message, options: options, action: action))
    }
    
    // MARK: - Haptic Control Convenience Methods
    
    /// Show a success toast without haptics
    func successSilent(
        _ message: LocalizedStringKey,
        options: ToastOptions = .default(for: .success).withoutHaptics(),
        action: ToastAction? = nil
    ) async {
        await show(ToastItem.success(message, options: options, action: action))
    }
    
    /// Show an error toast without haptics
    func errorSilent(
        _ message: LocalizedStringKey,
        options: ToastOptions = .default(for: .error).withoutHaptics(),
        action: ToastAction? = nil
    ) async {
        await show(ToastItem.error(message, options: options, action: action))
    }
    
    /// Show an info toast without haptics
    func infoSilent(
        _ message: LocalizedStringKey,
        options: ToastOptions = .default(for: .info).withoutHaptics(),
        action: ToastAction? = nil
    ) async {
        await show(ToastItem.info(message, options: options, action: action))
    }
    
    /// Show a warning toast without haptics
    func warningSilent(
        _ message: LocalizedStringKey,
        options: ToastOptions = .default(for: .warning).withoutHaptics(),
        action: ToastAction? = nil
    ) async {
        await show(ToastItem.warning(message, options: options, action: action))
    }
    
    /// Show a toast with custom haptics
    func showWithCustomHaptics(
        _ message: LocalizedStringKey,
        kind: ToastKind = .info,
        haptics: ToastHaptic,
        options: ToastOptions = ToastOptions(),
        action: ToastAction? = nil
    ) async {
        let customOptions = options.withHaptics(haptics)
        await show(message, kind: kind, options: customOptions, action: action)
    }
}