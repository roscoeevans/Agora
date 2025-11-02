import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Coordinates toast presentation overlays within a specific scene for memory efficiency and gesture isolation
#if canImport(UIKit) && !os(macOS)
@MainActor
internal final class SceneOverlayCoordinator {
    
    // MARK: - Properties
    
    private weak var scene: UIScene?
    private var overlayWindow: UIWindow?
    private var hostingController: UIHostingController<ToastOverlayView>?
    private var currentToastItem: ToastItem?
    private weak var currentPresenter: ToastPresenter?
    private let performanceManager: ToastPerformanceManager
    
    // MARK: - Initialization
    
    init(scene: UIScene, performanceManager: ToastPerformanceManager = .shared) {
        self.scene = scene
        self.performanceManager = performanceManager
        setupOverlayWindow()
    }
    
    deinit {
        cleanup()
    }
    
    // MARK: - Public Methods
    
    /// Present a toast in the overlay
    func presentToast(_ item: ToastItem, presenter: ToastPresenter) {
        currentToastItem = item
        currentPresenter = presenter
        
        // Create or update the overlay view
        let overlayView = ToastOverlayView(
            item: item,
            isPresented: presenter.isPresented,
            onDismiss: { [weak presenter] in
                presenter?.handleUserTap()
            },
            onSwipe: { [weak presenter] direction in
                presenter?.handleUserSwipe(direction: direction)
            },
            onActionTap: { [weak presenter] in
                presenter?.handleActionTap()
            },
            safeAreaInsets: presenter.calculateSafeAreaInsets(),
            sceneBounds: presenter.getSceneBounds()
        )
        
        if let existingController = hostingController {
            // Update existing controller
            existingController.rootView = overlayView
        } else {
            // Create new hosting controller
            hostingController = UIHostingController(rootView: overlayView)
            hostingController?.view.backgroundColor = .clear
            
            // Configure for gesture isolation
            configureGestureIsolation()
            
            // Add to overlay window
            if let overlayWindow = overlayWindow,
               let hostingController = hostingController {
                overlayWindow.rootViewController = hostingController
                overlayWindow.isHidden = false
            }
        }
    }
    
    /// Update the current toast (for coalescing)
    func updateToast(_ item: ToastItem) {
        guard let presenter = currentPresenter else { return }
        
        currentToastItem = item
        
        let overlayView = ToastOverlayView(
            item: item,
            isPresented: presenter.isPresented,
            onDismiss: { [weak presenter] in
                presenter?.handleUserTap()
            },
            onSwipe: { [weak presenter] direction in
                presenter?.handleUserSwipe(direction: direction)
            },
            onActionTap: { [weak presenter] in
                presenter?.handleActionTap()
            },
            safeAreaInsets: presenter.calculateSafeAreaInsets(),
            sceneBounds: presenter.getSceneBounds()
        )
        
        hostingController?.rootView = overlayView
    }
    
    /// Dismiss the current toast
    func dismissCurrentToast() {
        overlayWindow?.isHidden = true
        currentToastItem = nil
        currentPresenter = nil
    }
    
    /// Adjust layout for keyboard
    func adjustForKeyboard(_ keyboardFrame: CGRect) {
        guard let presenter = currentPresenter,
              let item = currentToastItem else { return }
        
        let overlayView = ToastOverlayView(
            item: item,
            isPresented: presenter.isPresented,
            onDismiss: { [weak presenter] in
                presenter?.handleUserTap()
            },
            onSwipe: { [weak presenter] direction in
                presenter?.handleUserSwipe(direction: direction)
            },
            onActionTap: { [weak presenter] in
                presenter?.handleActionTap()
            },
            safeAreaInsets: presenter.calculateSafeAreaInsets(),
            sceneBounds: presenter.getSceneBounds(),
            keyboardFrame: keyboardFrame
        )
        
        hostingController?.rootView = overlayView
    }
    
    /// Clean up resources
    func cleanup() {
        overlayWindow?.isHidden = true
        overlayWindow?.rootViewController = nil
        overlayWindow = nil
        hostingController = nil
        currentToastItem = nil
        currentPresenter = nil
        
        // Trigger performance cleanup
        performanceManager.performMemoryCleanup()
    }
    
    // MARK: - Private Methods
    
    private func setupOverlayWindow() {
        guard let windowScene = scene as? UIWindowScene else { return }
        
        // Create overlay window at high level to ensure it appears above app content
        overlayWindow = UIWindow(windowScene: windowScene)
        overlayWindow?.windowLevel = UIWindow.Level.alert - 1 // Below system alerts but above app
        overlayWindow?.backgroundColor = .clear
        overlayWindow?.isHidden = true
        
        // Configure for touch passthrough where there's no toast
        overlayWindow?.isUserInteractionEnabled = true
    }
    
    private func configureGestureIsolation() {
        guard let hostingController = hostingController else { return }
        
        // Configure the hosting controller's view for proper gesture handling
        hostingController.view.isUserInteractionEnabled = true
        
        // Add a custom hit test to only capture touches on the toast itself
        let originalHitTest = hostingController.view.hitTest
        hostingController.view.hitTest = { [weak self] point, event in
            // Only handle touches if we have a toast presented
            guard self?.currentToastItem != nil else {
                return nil // Pass through to underlying views
            }
            
            // Use the original hit test logic
            return originalHitTest(point, event)
        }
    }
}

// MARK: - Toast Overlay View

/// SwiftUI view that renders the toast overlay with proper gesture handling
internal struct ToastOverlayView: View {
    let item: ToastItem
    let isPresented: Bool
    let onDismiss: () -> Void
    let onSwipe: (SwipeDirection) -> Void
    let onActionTap: () -> Void
    let safeAreaInsets: EdgeInsets
    let sceneBounds: CGRect
    var keyboardFrame: CGRect = .zero
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        GeometryReader { geometry in
            if isPresented {
                ToastView(
                    item: item,
                    onDismiss: onDismiss,
                    onActionTap: onActionTap
                )
                .frame(maxWidth: item.options.maxWidth ?? 600)
                .padding(.horizontal, 16)
                .position(
                    x: geometry.size.width / 2,
                    y: toastYPosition(in: geometry)
                )
                .gesture(
                    DragGesture()
                        .onEnded { value in
                            handleSwipeGesture(value)
                        }
                )
                .onTapGesture {
                    if item.options.allowsUserDismiss {
                        onDismiss()
                    }
                }
                .transition(toastTransition)
                .zIndex(1000) // Ensure toast appears above other content
            }
        }
        .allowsHitTesting(isPresented)
        .ignoresSafeArea(.all) // We handle safe areas manually
    }
    
    // MARK: - Private Methods
    
    private func toastYPosition(in geometry: GeometryProxy) -> CGFloat {
        let toastHeight: CGFloat = 60 // Estimated toast height
        
        switch item.options.presentationEdge {
        case .top:
            let topOffset = safeAreaInsets.top + 16
            return topOffset + (toastHeight / 2)
            
        case .bottom:
            var bottomOffset = safeAreaInsets.bottom + 16
            
            // Adjust for keyboard if present
            if !keyboardFrame.isEmpty {
                let keyboardHeight = sceneBounds.height - keyboardFrame.minY
                bottomOffset = max(bottomOffset, keyboardHeight + 16)
            }
            
            return geometry.size.height - bottomOffset - (toastHeight / 2)
            
        default:
            // Default to top
            let topOffset = safeAreaInsets.top + 16
            return topOffset + (toastHeight / 2)
        }
    }
    
    private var toastTransition: AnyTransition {
        if reduceMotion {
            return .opacity
        } else {
            let edge = item.options.presentationEdge
            return .asymmetric(
                insertion: .scale(scale: 0.96).combined(with: .opacity),
                removal: .move(edge: edge).combined(with: .opacity)
            )
        }
    }
    
    private func handleSwipeGesture(_ value: DragGesture.Value) {
        let threshold: CGFloat = 50
        let velocity: CGFloat = 200
        
        let horizontalDistance = abs(value.translation.x)
        let verticalDistance = abs(value.translation.y)
        
        // Determine if this is a valid swipe
        if horizontalDistance > threshold || abs(value.velocity.x) > velocity {
            if value.translation.x > 0 {
                onSwipe(.right)
            } else {
                onSwipe(.left)
            }
        } else if verticalDistance > threshold || abs(value.velocity.y) > velocity {
            if value.translation.y > 0 {
                onSwipe(.down)
            } else {
                onSwipe(.up)
            }
        }
    }
}

// MARK: - Toast View Placeholder

/// Placeholder for the actual ToastView implementation (will be implemented in task 4)
internal struct ToastView: View {
    let item: ToastItem
    let onDismiss: () -> Void
    let onActionTap: () -> Void
    
    var body: some View {
        // Temporary implementation - will be replaced with Liquid Glass design in task 4
        HStack {
            if let icon = item.kind.icon {
                icon
                    .foregroundColor(item.kind.accentColor)
            }
            
            Text(item.message)
                .font(.body)
                .foregroundColor(.primary)
            
            if let action = item.action {
                Button(action.title) {
                    onActionTap()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 8)
    }
}

// MARK: - ToastKind Extensions

private extension ToastKind {
    var icon: Image? {
        switch self {
        case .success:
            return Image(systemName: "checkmark.circle.fill")
        case .error:
            return Image(systemName: "xmark.circle.fill")
        case .info:
            return Image(systemName: "info.circle.fill")
        case .warning:
            return Image(systemName: "exclamationmark.triangle.fill")
        case .custom(let icon, _):
            return icon
        }
    }
    
    var accentColor: Color {
        switch self {
        case .success:
            return .green
        case .error:
            return .red
        case .info:
            return .blue
        case .warning:
            return .orange
        case .custom(_, let accent):
            return accent ?? .blue
        }
    }
}
#else
// Placeholder for non-UIKit platforms
@MainActor
internal final class SceneOverlayCoordinator {
    init(scene: Any) {}
    func presentToast(_ item: ToastItem, presenter: Any) {}
    func updateToast(_ item: ToastItem) {}
    func dismissCurrentToast() {}
    func adjustForKeyboard(_ keyboardFrame: CGRect) {}
    func cleanup() {}
}

// ToastView and ToastOverlayView are now implemented in the Views directory

private extension ToastKind {
    var icon: Image? { nil }
    var accentColor: Color { .blue }
}
#endif