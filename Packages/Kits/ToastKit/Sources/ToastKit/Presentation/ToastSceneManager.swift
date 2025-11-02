import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Manages toast presenters across multiple scenes for multi-window support
#if canImport(UIKit) && !os(macOS)
@MainActor
public final class ToastSceneManager: ObservableObject {
    
    // MARK: - Properties
    
    private var presenters: [ObjectIdentifier: ToastPresenter] = [:]
    private var sceneObservers: [ObjectIdentifier: NSObjectProtocol] = [:]
    
    // MARK: - Initialization
    
    public init() {
        setupSceneObservation()
    }
    
    deinit {
        cleanup()
    }
    
    // MARK: - Public API
    
    /// Get or create a presenter for the given scene
    public func presenter(for scene: UIScene) -> ToastPresenter {
        let sceneID = ObjectIdentifier(scene)
        
        if let existingPresenter = presenters[sceneID] {
            return existingPresenter
        }
        
        let newPresenter = ToastPresenter(scene: scene, performanceManager: .shared)
        presenters[sceneID] = newPresenter
        
        // Observe scene lifecycle
        observeScene(scene)
        
        return newPresenter
    }
    
    /// Get the presenter for the currently active scene
    public func activePresenter() -> ToastPresenter? {
        // Find the active window scene
        guard let activeScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) else {
            
            // Fallback to any foreground scene
            guard let fallbackScene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundInactive }) else {
                return nil
            }
            
            return presenter(for: fallbackScene)
        }
        
        return presenter(for: activeScene)
    }
    
    /// Present a toast in the most appropriate scene
    public func presentInActiveScene(
        _ item: ToastItem,
        onDismiss: @escaping (DismissalMethod) -> Void
    ) {
        guard let presenter = activePresenter() else {
            // No active scene available
            onDismiss(.sceneInactive)
            return
        }
        
        presenter.present(item, onDismiss: onDismiss)
    }
    
    /// Dismiss toasts in all scenes
    public func dismissAllScenes() {
        for presenter in presenters.values {
            presenter.dismiss(animated: true)
        }
    }
    
    /// Get all active presenters
    public func allPresenters() -> [ToastPresenter] {
        return Array(presenters.values)
    }
    
    // MARK: - Private Methods
    
    private func setupSceneObservation() {
        // Observe scene connection/disconnection
        NotificationCenter.default.addObserver(
            forName: UIScene.didConnectNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let scene = notification.object as? UIScene {
                self?.handleSceneConnected(scene)
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIScene.didDisconnectNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let scene = notification.object as? UIScene {
                self?.handleSceneDisconnected(scene)
            }
        }
    }
    
    private func observeScene(_ scene: UIScene) {
        let sceneID = ObjectIdentifier(scene)
        
        // Avoid duplicate observers
        guard sceneObservers[sceneID] == nil else { return }
        
        let observer = NotificationCenter.default.addObserver(
            forName: UIScene.willDeactivateNotification,
            object: scene,
            queue: .main
        ) { [weak self] _ in
            self?.handleSceneWillDeactivate(scene)
        }
        
        sceneObservers[sceneID] = observer
    }
    
    private func handleSceneConnected(_ scene: UIScene) {
        // Scene connected - presenter will be created on demand
    }
    
    private func handleSceneDisconnected(_ scene: UIScene) {
        let sceneID = ObjectIdentifier(scene)
        
        // Remove presenter
        presenters.removeValue(forKey: sceneID)
        
        // Remove observer
        if let observer = sceneObservers.removeValue(forKey: sceneID) {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    private func handleSceneWillDeactivate(_ scene: UIScene) {
        let sceneID = ObjectIdentifier(scene)
        
        // Optionally dismiss toasts in deactivating scene
        if let presenter = presenters[sceneID] {
            presenter.dismiss(animated: false)
        }
    }
    
    private func cleanup() {
        // Remove all observers
        for observer in sceneObservers.values {
            NotificationCenter.default.removeObserver(observer)
        }
        sceneObservers.removeAll()
        
        // Clear presenters
        presenters.removeAll()
    }
}

// MARK: - Environment Integration

/// Environment key for scene manager
public struct ToastSceneManagerKey: EnvironmentKey {
    public static var defaultValue: ToastSceneManager {
        MainActor.assumeIsolated {
            ToastSceneManager()
        }
    }
}

public extension EnvironmentValues {
    /// Access to toast scene manager
    var toastSceneManager: ToastSceneManager {
        get { self[ToastSceneManagerKey.self] }
        set { self[ToastSceneManagerKey.self] = newValue }
    }
}

// MARK: - View Extensions

public extension View {
    /// Provide toast scene manager to the view hierarchy
    func toastSceneManager(_ manager: ToastSceneManager) -> some View {
        environment(\.toastSceneManager, manager)
    }
}
#else
// Placeholder for non-UIKit platforms
@MainActor
public final class ToastSceneManager: ObservableObject {
    public init() {}
    public func presenter(for scene: Any) -> ToastPresenter { ToastPresenter(scene: scene) }
    public func activePresenter() -> ToastPresenter? { nil }
    public func presentInActiveScene(_ item: ToastItem, onDismiss: @escaping (DismissalMethod) -> Void) { onDismiss(.sceneInactive) }
    public func dismissAllScenes() {}
    public func allPresenters() -> [ToastPresenter] { [] }
}

public struct ToastSceneManagerKey: EnvironmentKey {
    public static var defaultValue: ToastSceneManager {
        MainActor.assumeIsolated {
            ToastSceneManager()
        }
    }
}

public extension EnvironmentValues {
    var toastSceneManager: ToastSceneManager {
        get { self[ToastSceneManagerKey.self] }
        set { self[ToastSceneManagerKey.self] = newValue }
    }
}

public extension View {
    func toastSceneManager(_ manager: ToastSceneManager) -> some View {
        environment(\.toastSceneManager, manager)
    }
}
#endif