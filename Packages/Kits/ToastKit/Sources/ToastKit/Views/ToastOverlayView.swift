import SwiftUI
import DesignSystem
#if canImport(UIKit)
import UIKit
#endif

/// Overlay view that hosts ToastView with presentation animations and gesture handling
@available(iOS 26.0, *)
public struct ToastOverlayView: View {
    let item: ToastItem?
    let isPresented: Bool
    let onDismiss: () -> Void
    let onAction: (() -> Void)?
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false
    @State private var animationState = ToastAnimationState()
    @State private var dragProgress: Double = 0.0
    
    public init(
        item: ToastItem?,
        isPresented: Bool,
        onDismiss: @escaping () -> Void,
        onAction: (() -> Void)? = nil
    ) {
        self.item = item
        self.isPresented = isPresented
        self.onDismiss = onDismiss
        self.onAction = onAction
    }
    
    public var body: some View {
        Group {
            if let item = item {
                toastContent(for: item)
                    .opacity(presentationOpacity)
                    .scaleEffect(presentationScale)
                    .offset(y: presentationOffset)
                    .offset(dragOffset)
                    .animation(presentationAnimation, value: isPresented)
                    .animation(dragAnimation, value: dragOffset)
                    .gesture(dismissGesture)
                    .onAppear {
                        startAppearanceAnimation()
                    }
                    .onChange(of: isPresented) { _, newValue in
                        if !newValue {
                            startDismissalAnimation()
                        }
                    }
            }
        }
    }
}

// MARK: - Content

@available(iOS 26.0, *)
private extension ToastOverlayView {
    func toastContent(for item: ToastItem) -> some View {
        ToastView(
            item: item,
            onDismiss: onDismiss,
            onAction: onAction
        )
    }
}

// MARK: - Animation Properties

@available(iOS 26.0, *)
private extension ToastOverlayView {
    var presentationOpacity: Double {
        let baseOpacity = isPresented ? ToastAnimations.OpacityValues.visible : ToastAnimations.OpacityValues.hidden
        
        // Apply drag progress for interactive dismissal
        if isDragging && dragProgress > 0 {
            return baseOpacity * (1.0 - dragProgress * 0.5) // Fade out during drag
        }
        
        return baseOpacity
    }
    
    var presentationScale: Double {
        if reduceMotion {
            return ToastAnimations.ScaleValues.reduced
        }
        
        let baseScale = isPresented ? ToastAnimations.ScaleValues.final : ToastAnimations.ScaleValues.initial
        
        // Apply subtle scale during drag for visual feedback
        if isDragging && dragProgress > 0 {
            return baseScale * (1.0 - dragProgress * 0.02) // Slight scale down during drag
        }
        
        return baseScale
    }
    
    var presentationOffset: CGFloat {
        if reduceMotion {
            return ToastAnimations.TranslationValues.none
        }
        
        guard let item = item else { return 0 }
        
        switch item.options.presentationEdge {
        case .top:
            return isPresented ? ToastAnimations.TranslationValues.none : ToastAnimations.TranslationValues.topDismissal
        case .bottom:
            return isPresented ? ToastAnimations.TranslationValues.none : ToastAnimations.TranslationValues.bottomDismissal
        default:
            return ToastAnimations.TranslationValues.none
        }
    }
    
    var presentationAnimation: Animation {
        ToastAnimations.accessibleAppearance(reduceMotion: reduceMotion)
    }
    
    var dragAnimation: Animation {
        ToastAnimations.accessibleInteractive(reduceMotion: reduceMotion, isDragging: isDragging)
    }
}

// MARK: - Interactive Dismissal

@available(iOS 26.0, *)
private extension ToastOverlayView {
    var dismissGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard item?.options.allowsUserDismiss == true else { return }
                
                if !isDragging {
                    isDragging = true
                    startInteractiveAnimation()
                }
                
                // Calculate constrained drag offset with resistance
                let constrainedOffset = calculateConstrainedDragOffset(translation: value.translation)
                dragOffset = constrainedOffset
                
                // Update drag progress for visual feedback
                updateDragProgress(translation: value.translation)
            }
            .onEnded { value in
                guard isDragging else { return }
                
                isDragging = false
                endInteractiveAnimation()
                
                let translation = value.translation
                let velocity = value.velocity
                
                // Determine if gesture should trigger dismissal
                let shouldDismiss = shouldDismissFromGesture(
                    translation: translation,
                    velocity: velocity
                )
                
                if shouldDismiss {
                    // Animate to dismissal with enhanced translation
                    animateToDismissal(translation: translation, velocity: velocity)
                } else {
                    // Spring back to original position
                    springBackToOriginalPosition()
                }
            }
    }
    
    var dismissalDirection: DismissalDirection {
        guard let item = item else { return .up }
        
        switch item.options.presentationEdge {
        case .top:
            return .up
        case .bottom:
            return .down
        default:
            return .horizontal
        }
    }
    
    func calculateConstrainedDragOffset(translation: CGSize) -> CGSize {
        let allowedDirection = dismissalDirection
        let maxDistance = ToastGestureConfig.maxDragDistance
        let resistance = ToastGestureConfig.dragResistance
        
        switch allowedDirection {
        case .up:
            let constrainedY = min(0, translation.height)
            let resistedY = constrainedY > -maxDistance ? constrainedY : -maxDistance + (constrainedY + maxDistance) * resistance
            return CGSize(width: 0, height: resistedY)
            
        case .down:
            let constrainedY = max(0, translation.height)
            let resistedY = constrainedY < maxDistance ? constrainedY : maxDistance + (constrainedY - maxDistance) * resistance
            return CGSize(width: 0, height: resistedY)
            
        case .horizontal:
            let distance = sqrt(translation.width * translation.width + translation.height * translation.height)
            if distance <= maxDistance {
                return translation
            } else {
                let scale = maxDistance / distance + (distance - maxDistance) / distance * resistance
                return CGSize(width: translation.width * scale, height: translation.height * scale)
            }
        }
    }
    
    func updateDragProgress(translation: CGSize) {
        let threshold = ToastGestureConfig.dismissalThreshold
        
        switch dismissalDirection {
        case .up:
            dragProgress = min(1.0, max(0.0, -translation.height / threshold))
        case .down:
            dragProgress = min(1.0, max(0.0, translation.height / threshold))
        case .horizontal:
            let distance = sqrt(translation.width * translation.width + translation.height * translation.height)
            dragProgress = min(1.0, max(0.0, distance / threshold))
        }
    }
    
    func shouldDismissFromGesture(translation: CGSize, velocity: CGSize) -> Bool {
        let threshold = ToastGestureConfig.dismissalThreshold
        let velocityThreshold = ToastGestureConfig.velocityThreshold
        
        switch dismissalDirection {
        case .up:
            return translation.height < -threshold || velocity.height < -velocityThreshold
        case .down:
            return translation.height > threshold || velocity.height > velocityThreshold
        case .horizontal:
            let distance = sqrt(translation.width * translation.width + translation.height * translation.height)
            let speed = sqrt(velocity.width * velocity.width + velocity.height * velocity.height)
            return distance > threshold || speed > velocityThreshold
        }
    }
    
    func animateToDismissal(translation: CGSize, velocity: CGSize) {
        // Enhance the final translation for smooth dismissal
        let enhancedTranslation = calculateEnhancedDismissalTranslation(translation: translation, velocity: velocity)
        
        withAnimation(ToastAnimations.dismissalSpring) {
            dragOffset = enhancedTranslation
        }
        
        // Trigger dismissal after a brief delay to allow animation to start
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            onDismiss()
        }
    }
    
    func calculateEnhancedDismissalTranslation(translation: CGSize, velocity: CGSize) -> CGSize {
        let enhancementFactor: CGFloat = 2.0
        
        switch dismissalDirection {
        case .up:
            return CGSize(width: 0, height: translation.height * enhancementFactor)
        case .down:
            return CGSize(width: 0, height: translation.height * enhancementFactor)
        case .horizontal:
            return CGSize(
                width: translation.width * enhancementFactor,
                height: translation.height * enhancementFactor
            )
        }
    }
    
    func springBackToOriginalPosition() {
        withAnimation(ToastGestureConfig.springBackAnimation) {
            dragOffset = .zero
            dragProgress = 0.0
        }
    }
}

// MARK: - Animation Lifecycle

@available(iOS 26.0, *)
private extension ToastOverlayView {
    func startAppearanceAnimation() {
        animationState.startAnimation(.appearance)
        
        // Post accessibility announcement for appearance
        #if canImport(UIKit) && !os(macOS)
        if let item = item {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                let notification: UIAccessibility.Notification = item.options.accessibilityPolite ? .announcement : .layoutChanged
                UIAccessibility.post(
                    notification: notification,
                    argument: item.message
                )
            }
        }
        #endif
    }
    
    func startDismissalAnimation() {
        animationState.startAnimation(.dismissal)
    }
    
    func startInteractiveAnimation() {
        animationState.startAnimation(.interactive)
    }
    
    func endInteractiveAnimation() {
        let duration = animationState.duration
        let frameCount = animationState.frameCount
        
        // Report performance metrics if available
        if duration > 0 {
            reportAnimationPerformance(duration: duration, frameCount: frameCount)
        }
        
        animationState.endAnimation()
    }
    
    func reportAnimationPerformance(duration: CFTimeInterval, frameCount: Int) {
        // Calculate approximate frame drops
        let expectedFrames = Int(duration * 60) // Assuming 60 FPS baseline
        let frameDrops = max(0, expectedFrames - frameCount)
        
        // This would typically be reported to telemetry
        // For now, we'll just track it internally
        #if DEBUG
        if frameDrops > 0 {
            print("Toast animation performance: \(frameDrops) frame drops in \(duration)s")
        }
        #endif
    }
}

// MARK: - Supporting Types

@available(iOS 26.0, *)
private enum DismissalDirection {
    case up
    case down
    case horizontal
}

// MARK: - Preview Support

@available(iOS 26.0, *)
struct ToastOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            ColorTokens.background
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // Top-presented success toast
                ToastOverlayView(
                    item: .success("Profile updated successfully"),
                    isPresented: true,
                    onDismiss: {}
                )
                .padding()
                
                Spacer()
                
                // Bottom-presented error toast with action
                ToastOverlayView(
                    item: ToastItem(
                        message: "Failed to upload image",
                        kind: .error,
                        options: ToastOptions(presentationEdge: .bottom),
                        action: ToastAction(title: "Retry", handler: {})
                    ),
                    isPresented: true,
                    onDismiss: {}
                )
                .padding()
                
                Spacer()
            }
        }
        .previewDisplayName("Toast Overlay - Standard")
        
        // Reduce Motion Preview
        ZStack {
            ColorTokens.background
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ToastOverlayView(
                    item: .info("Reduce Motion enabled"),
                    isPresented: true,
                    onDismiss: {}
                )
                
                ToastOverlayView(
                    item: .warning("Cross-fade only animation"),
                    isPresented: true,
                    onDismiss: {}
                )
            }
            .padding()
        }
        .previewDisplayName("Toast Overlay - Reduce Motion")
    }
}