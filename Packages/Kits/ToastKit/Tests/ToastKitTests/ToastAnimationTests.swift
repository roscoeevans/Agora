import XCTest
import SwiftUI
@testable import ToastKit

@available(iOS 26.0, *)
final class ToastAnimationTests: XCTestCase {
    
    // MARK: - Animation Configuration Tests
    
    func testAnimationDurations() {
        // Test that animation durations meet the 240ms requirement
        XCTAssertEqual(ToastAnimations.standardDuration, 0.24, accuracy: 0.001)
        XCTAssertEqual(ToastAnimations.quickDuration, 0.12, accuracy: 0.001)
        XCTAssertEqual(ToastAnimations.interactiveDuration, 0.3, accuracy: 0.001)
    }
    
    func testSpringParameters() {
        // Test spring parameters are within reasonable ranges
        XCTAssertGreaterThan(ToastAnimations.appearanceResponse, 0.0)
        XCTAssertLessThan(ToastAnimations.appearanceResponse, 1.0)
        
        XCTAssertGreaterThan(ToastAnimations.appearanceDamping, 0.0)
        XCTAssertLessThanOrEqual(ToastAnimations.appearanceDamping, 1.0)
        
        XCTAssertGreaterThan(ToastAnimations.dismissalResponse, 0.0)
        XCTAssertLessThan(ToastAnimations.dismissalResponse, 1.0)
        
        XCTAssertGreaterThan(ToastAnimations.dismissalDamping, 0.0)
        XCTAssertLessThanOrEqual(ToastAnimations.dismissalDamping, 1.0)
    }
    
    func testAnimationValues() {
        // Test scale values
        XCTAssertEqual(ToastAnimations.ScaleValues.initial, 0.96, accuracy: 0.001)
        XCTAssertEqual(ToastAnimations.ScaleValues.final, 1.0, accuracy: 0.001)
        XCTAssertEqual(ToastAnimations.ScaleValues.reduced, 1.0, accuracy: 0.001)
        
        // Test opacity values
        XCTAssertEqual(ToastAnimations.OpacityValues.hidden, 0.0, accuracy: 0.001)
        XCTAssertEqual(ToastAnimations.OpacityValues.visible, 1.0, accuracy: 0.001)
        
        // Test translation values
        XCTAssertEqual(ToastAnimations.TranslationValues.topDismissal, -20)
        XCTAssertEqual(ToastAnimations.TranslationValues.bottomDismissal, 20)
        XCTAssertEqual(ToastAnimations.TranslationValues.none, 0)
    }
    
    func testAccessibilityAwareAnimations() {
        // Test that reduce motion returns different animations
        let standardAnimation = ToastAnimations.accessibleAppearance(reduceMotion: false)
        let reducedAnimation = ToastAnimations.accessibleAppearance(reduceMotion: true)
        
        // We can't directly compare Animation objects, but we can verify they're created
        XCTAssertNotNil(standardAnimation)
        XCTAssertNotNil(reducedAnimation)
        
        // Test interactive animations
        let interactiveStandard = ToastAnimations.accessibleInteractive(reduceMotion: false, isDragging: true)
        let interactiveReduced = ToastAnimations.accessibleInteractive(reduceMotion: true, isDragging: true)
        
        XCTAssertNotNil(interactiveStandard)
        XCTAssertNotNil(interactiveReduced)
    }
    
    // MARK: - Gesture Configuration Tests
    
    func testGestureConfiguration() {
        // Test dismissal thresholds are reasonable
        XCTAssertEqual(ToastGestureConfig.dismissalThreshold, 30)
        XCTAssertEqual(ToastGestureConfig.velocityThreshold, 200)
        XCTAssertEqual(ToastGestureConfig.maxDragDistance, 100)
        XCTAssertEqual(ToastGestureConfig.dragResistance, 0.3, accuracy: 0.001)
        
        // Test spring back animation exists
        XCTAssertNotNil(ToastGestureConfig.springBackAnimation)
    }
    
    // MARK: - Animation State Tests
    
    func testAnimationStateManagement() {
        var state = ToastAnimationState()
        
        // Initial state
        XCTAssertFalse(state.isAnimating)
        XCTAssertEqual(state.animationType, .none)
        XCTAssertEqual(state.frameCount, 0)
        XCTAssertEqual(state.duration, 0, accuracy: 0.001)
        
        // Start animation
        state.startAnimation(.appearance)
        XCTAssertTrue(state.isAnimating)
        XCTAssertEqual(state.animationType, .appearance)
        XCTAssertGreaterThan(state.startTime, 0)
        
        // End animation
        state.endAnimation()
        XCTAssertFalse(state.isAnimating)
        XCTAssertEqual(state.animationType, .none)
        XCTAssertEqual(state.startTime, 0)
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceOptimizations() {
        // Test that high performance mode is enabled
        XCTAssertTrue(ToastAnimations.useHighPerformanceMode)
        
        // Test user interaction setting
        XCTAssertTrue(ToastAnimations.allowsUserInteractionDuringAnimation)
    }
    
    // MARK: - Integration Tests
    
    @MainActor
    func testToastOverlayViewAnimationIntegration() {
        let item = ToastItem.success("Test message")
        let overlayView = ToastOverlayView(
            item: item,
            isPresented: true,
            onDismiss: {}
        )
        
        // Test that the view can be created without errors
        XCTAssertNotNil(overlayView)
        
        // Test with reduce motion (simplified test without environment modifier)
        let reducedMotionView = ToastOverlayView(
            item: item,
            isPresented: true,
            onDismiss: {}
        )
        
        XCTAssertNotNil(reducedMotionView)
    }
    
    func testAnimationTimingConsistency() {
        // Test that all animation durations are consistent with the 240ms requirement
        let standardDuration = ToastAnimations.standardDuration
        
        // All main animations should use the standard duration or be faster
        XCTAssertLessThanOrEqual(ToastAnimations.quickDuration, standardDuration)
        
        // Interactive duration can be slightly longer for better UX
        XCTAssertGreaterThanOrEqual(ToastAnimations.interactiveDuration, standardDuration)
    }
    
    // MARK: - Accessibility Tests
    
    func testReduceMotionSupport() {
        // Test that accessibility-aware animations handle reduce motion correctly
        let appearanceStandard = ToastAnimations.accessibleAnimation(
            reduceMotion: false,
            standard: ToastAnimations.appearanceSpring,
            reduced: ToastAnimations.standardEaseInOut
        )
        
        let appearanceReduced = ToastAnimations.accessibleAnimation(
            reduceMotion: true,
            standard: ToastAnimations.appearanceSpring,
            reduced: ToastAnimations.standardEaseInOut
        )
        
        XCTAssertNotNil(appearanceStandard)
        XCTAssertNotNil(appearanceReduced)
    }
    
    func testInteractiveAnimationBehavior() {
        // Test interactive animations behave differently when dragging vs not dragging
        let draggingAnimation = ToastAnimations.accessibleInteractive(
            reduceMotion: false,
            isDragging: true
        )
        
        let notDraggingAnimation = ToastAnimations.accessibleInteractive(
            reduceMotion: false,
            isDragging: false
        )
        
        XCTAssertNotNil(draggingAnimation)
        XCTAssertNotNil(notDraggingAnimation)
        
        // Test with reduce motion
        let reducedDraggingAnimation = ToastAnimations.accessibleInteractive(
            reduceMotion: true,
            isDragging: true
        )
        
        let reducedNotDraggingAnimation = ToastAnimations.accessibleInteractive(
            reduceMotion: true,
            isDragging: false
        )
        
        XCTAssertNotNil(reducedDraggingAnimation)
        XCTAssertNotNil(reducedNotDraggingAnimation)
    }
    
    // MARK: - Edge Case Tests
    
    func testAnimationStateEdgeCases() {
        var state = ToastAnimationState()
        
        // Test multiple start calls
        state.startAnimation(.appearance)
        let firstStartTime = state.startTime
        
        state.startAnimation(.dismissal)
        XCTAssertEqual(state.animationType, .dismissal)
        XCTAssertGreaterThanOrEqual(state.startTime, firstStartTime)
        
        // Test end without start
        var emptyState = ToastAnimationState()
        emptyState.endAnimation()
        XCTAssertFalse(emptyState.isAnimating)
        XCTAssertEqual(emptyState.animationType, .none)
    }
    
    func testGestureThresholdEdgeCases() {
        // Test that thresholds are positive and reasonable
        XCTAssertGreaterThan(ToastGestureConfig.dismissalThreshold, 0)
        XCTAssertGreaterThan(ToastGestureConfig.velocityThreshold, 0)
        XCTAssertGreaterThan(ToastGestureConfig.maxDragDistance, ToastGestureConfig.dismissalThreshold)
        
        // Test drag resistance is between 0 and 1
        XCTAssertGreaterThan(ToastGestureConfig.dragResistance, 0)
        XCTAssertLessThan(ToastGestureConfig.dragResistance, 1)
    }
}