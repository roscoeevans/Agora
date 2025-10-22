import Foundation
import SwiftUI

#if os(iOS)
import UIKit
#endif

/// ScreenSizeBridge provides cross-platform screen size utilities
@available(iOS 26.0, macOS 26.0, *)
public struct ScreenSizeBridge {
    
    /// Gets the main screen bounds height
    /// On non-iOS platforms, returns a reasonable default
    public static var mainScreenHeight: CGFloat {
        #if os(iOS)
        return UIScreen.main.bounds.height
        #else
        return 800 // Reasonable default for non-iOS platforms
        #endif
    }
    
    /// Gets the main screen bounds width
    /// On non-iOS platforms, returns a reasonable default
    public static var mainScreenWidth: CGFloat {
        #if os(iOS)
        return UIScreen.main.bounds.width
        #else
        return 1200 // Reasonable default for non-iOS platforms
        #endif
    }
    
    /// Gets a percentage of the main screen height
    /// On non-iOS platforms, returns a reasonable default
    public static func heightPercentage(_ percentage: CGFloat) -> CGFloat {
        return mainScreenHeight * percentage
    }
    
    /// Gets a percentage of the main screen width
    /// On non-iOS platforms, returns a reasonable default
    public static func widthPercentage(_ percentage: CGFloat) -> CGFloat {
        return mainScreenWidth * percentage
    }
}
