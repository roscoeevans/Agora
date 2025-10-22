import Foundation

#if os(iOS)
import UIKit
#endif

/// UIKitBridge provides iOS-specific UI utilities and bridges between UIKit and platform-agnostic types
public enum UIKitBridge {
    // This file serves as the main entry point for the UIKitBridge package
    // All UIKit-specific functionality is organized in separate files
}

// Re-export all bridge types for easy importing
// Note: The actual bridge types are defined in their respective files
// This module provides a single import point for all UIKit bridges