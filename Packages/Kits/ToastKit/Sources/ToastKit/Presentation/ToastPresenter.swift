import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
import Combine

/// Scene-aware toast presenter that manages toast overlays within specific UI scenes
#if canImport(UIKit) && !os(macOS)
@MainActor
public final class ToastPresenter: ObservableObject {
    
    // MARK: - Published State
    
    @Published private(set) var currentToast: ToastItem?
    @Published private(set) var isPresented = false
    
    // MARK: - Private Properties
    
    private let scene: UIScene
    private var dismissalTimer: Timer?
    private var keyboardFrame: CGRect = .zero
    private var overlayCoordinator: SceneOverlayCoordinator?
    private var cancellables = Set<AnyCancellable>()
    private var onDismissCallback: ((DismissalMethod) -> Void)?
    private let performanceManager: ToastPerformanceManager
    
    // MARK: - Initialization
    
    public init(scene: UIScene, performanceManager: ToastPerformanceManager = .shared) {
        self.scene = scene
        self.performanceManager = performanceManager
        
        // Register scene with performance manager
        performanceManager.registerScene(scene)
        
        setupKeyboardObservation()
        setupSceneObservation()
    }
    
    deinit {
        dismissalTimer?.invalidate()
        
        // Unregister scene
        performanceManager.unregisterScene(scene)
        
        overlayCoordinator?.cleanup()
    }
    
    // MARK: - Public API
    
    /// Present a toast in this scene
    public func present(_ item: ToastItem, onDismiss: @escaping (DismissalMethod) -> Void) {
        // Store dismissal callback
        self.onDismissCallback = onDismiss
        
        // Cancel any existing timer
        dismissalTimer?.invalidate()
        
        // Update state
        currentToast = item
        
        // Ensure overlay coordinator exists
        if overlayCoordinator == nil {
            overlayCoordinator = SceneOverlayCoordinator(scene: scene)
        }
        
        // Present the toast
        overlayCoordinator?.presentToast(item, presenter: self)
        
        // Update presentation state with proper animation timing
        withAnimation(ToastAnimations.appearanceSpring) {
            isPresented = true
        }
        
        // Post comprehensive accessibility announcement
        ToastAccessibility.announceToast(item)
        
        // Schedule automatic dismissal if duration is set
        if item.options.duration > .zero {
            scheduleAutomaticDismissal(after: item.options.duration)
        }
    }
    
    /// Dismiss the current toast
    public func dismiss(animated: Bool = true, completion: @escaping () -> Void = {}) {
        guard isPresented else {
            completion()
            return
        }
        
        dismissalTimer?.invalidate()
        
        let dismissalMethod: DismissalMethod = .programmatic
        
        if animated {
            withAnimation(ToastAnimations.dismissalSpring) {
                isPresented = false
            }
            
            // Wait for animation to complete (240ms standard duration)
            DispatchQueue.main.asyncAfter(deadline: .now() + ToastAnimations.standardDuration) { [weak self] in
                self?.completeToastDismissal(method: dismissalMethod)
                completion()
            }
        } else {
            isPresented = false
            completeToastDismissal(method: dismissalMethod)
            completion()
        }
    }
    
    /// Update the current toast (for coalescing)
    public func updateCurrentToast(_ item: ToastItem) {
        guard currentToast?.id == item.id else { return }
        
        currentToast = item
        overlayCoordinator?.updateToast(item)
    }
    
    // MARK: - Internal Methods
    
    /// Handle user tap dismissal
    internal func handleUserTap() {
        guard let toast = currentToast, toast.options.allowsUserDismiss else { return }
        
        dismiss(animated: true) { [weak self] in
            // Completion handled in dismiss method
        }
        
        onDismissCallback?(.userTap)
    }
    
    /// Handle user swipe dismissal
    internal func handleUserSwipe(direction: SwipeDirection) {
        guard let toast = currentToast, toast.options.allowsUserDismiss else { return }
        
        // Use directional animation for swipe dismissal
        withAnimation(ToastAnimations.dismissalSpring) {
            isPresented = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + ToastAnimations.standardDuration) { [weak self] in
            self?.completeToastDismissal(method: .userSwipe)
        }
    }
    
    /// Handle action button tap
    internal func handleActionTap() {
        guard let toast = currentToast, let action = toast.action else { return }
        
        // Execute action
        action.handler()
        
        // Dismiss toast
        dismiss(animated: true) { [weak self] in
            // Completion handled in dismiss method
        }
        
        onDismissCallback?(.actionTap)
    }
    
    // MARK: - Private Methods
    
    private func scheduleAutomaticDismissal(after duration: Duration) {
        // Cancel existing timer
        dismissalTimer?.invalidate()
        
        let timeInterval = TimeInterval(duration.components.seconds) + 
                          TimeInterval(duration.components.attoseconds) / 1_000_000_000_000_000_000
        
        dismissalTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { [weak self] _ in
            self?.dismiss(animated: true) { [weak self] in
                // Completion handled in dismiss method
            }
            self?.onDismissCallback?(.automatic)
        }
    }
    
    private func completeToastDismissal(method: DismissalMethod) {
        currentToast = nil
        overlayCoordinator?.dismissCurrentToast()
        onDismissCallback = nil
    }
    
    // MARK: - Keyboard Observation
    
    private func setupKeyboardObservation() {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .compactMap { notification in
                notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
            }
            .sink { [weak self] keyboardFrame in
                self?.keyboardFrame = keyboardFrame
                self?.adjustForKeyboard()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .sink { [weak self] _ in
                self?.keyboardFrame = .zero
                self?.adjustForKeyboard()
            }
            .store(in: &cancellables)
    }
    
    private func adjustForKeyboard() {
        guard let toast = currentToast,
              toast.options.presentationEdge == .bottom,
              !keyboardFrame.isEmpty else { return }
        
        overlayCoordinator?.adjustForKeyboard(keyboardFrame)
    }
    
    // MARK: - Scene Observation
    
    private func setupSceneObservation() {
        NotificationCenter.default.publisher(for: UIScene.willDeactivateNotification)
            .filter { [weak self] notification in
                notification.object as? UIScene === self?.scene
            }
            .sink { [weak self] _ in
                self?.handleSceneWillDeactivate()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIScene.didActivateNotification)
            .filter { [weak self] notification in
                notification.object as? UIScene === self?.scene
            }
            .sink { [weak self] _ in
                self?.handleSceneDidActivate()
            }
            .store(in: &cancellables)
    }
    
    private func handleSceneWillDeactivate() {
        // Clean up and pause dismissal timer
        dismissalTimer?.invalidate()
        dismissalTimer = nil
        
        // Optionally dismiss non-critical toasts
        if let toast = currentToast, toast.options.priority != .critical {
            dismiss(animated: false) { [weak self] in
                // Completion handled in dismiss method
            }
            onDismissCallback?(.sceneInactive)
        }
        
        // Trigger memory cleanup when scene deactivates
        performanceManager.performMemoryCleanup()
    }
    
    private func handleSceneDidActivate() {
        // Scene reactivated - overlay coordinator will handle restoration if needed
    }
    
    // MARK: - Safe Area Calculation
    
    internal func calculateSafeAreaInsets() -> EdgeInsets {
        guard let windowScene = scene as? UIWindowScene,
              let window = windowScene.windows.first else {
            return EdgeInsets()
        }
        
        let safeArea = window.safeAreaInsets
        
        return EdgeInsets(
            top: safeArea.top,
            leading: safeArea.left,
            bottom: safeArea.bottom,
            trailing: safeArea.right
        )
    }
    
    /// Get the current scene bounds for layout calculations
    internal func getSceneBounds() -> CGRect {
        guard let windowScene = scene as? UIWindowScene,
              let window = windowScene.windows.first else {
            return UIScreen.main.bounds
        }
        
        return window.bounds
    }
}

// MARK: - Supporting Types

public enum SwipeDirection {
    case up, down, left, right
}
#else
// Placeholder for non-UIKit platforms
@MainActor
public final class ToastPresenter: ObservableObject {
    @Published private(set) var currentToast: ToastItem?
    @Published private(set) var isPresented = false
    
    public init(scene: Any) {}
    public func present(_ item: ToastItem, onDismiss: @escaping (DismissalMethod) -> Void) {}
    public func dismiss(animated: Bool = true, completion: @escaping () -> Void = {}) { completion() }
    public func updateCurrentToast(_ item: ToastItem) {}
    internal func calculateSafeAreaInsets() -> EdgeInsets { EdgeInsets() }
    internal func getSceneBounds() -> CGRect { .zero }
}

public enum SwipeDirection {
    case up, down, left, right
}
#endif