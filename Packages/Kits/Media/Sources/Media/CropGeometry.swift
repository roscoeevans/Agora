import CoreGraphics
import Foundation

/// Mathematical engine for avatar cropping constraints and calculations.
/// Implements the authoritative zoom & pan math from the requirements document.
public struct CropGeometry {
    
    // MARK: - Zoom Range Calculation
    
    /// Calculates the valid zoom range for cropping based on image dimensions and quality constraints.
    /// 
    /// - Parameters:
    ///   - maskDiameterPoints: Diameter of the circular mask in points (Dpt)
    ///   - screenScale: Screen scale factor (σ, e.g., 3.0 for @3x displays)
    ///   - sourceSize: Source image dimensions in pixels (W, H)
    ///   - outputSize: Target output size in pixels (e.g., 512)
    ///   - qualityMultiplier: Quality factor (q, default 1.25)
    ///   - maxZoomMultiplier: Maximum zoom multiplier beyond cover scale
    /// - Returns: Tuple containing (min: cover scale, max: quality-limited max scale, qualityLimited: whether quality limited zoom)
    public static func zoomRange(
        maskDiameterPoints Dpt: CGFloat,
        screenScale sigma: CGFloat,
        sourceSize: CGSize,
        outputSize: Int,
        qualityMultiplier q: CGFloat,
        maxZoomMultiplier: CGFloat
    ) -> (min: CGFloat, max: CGFloat, qualityLimited: Bool) {
        
        // Cover scale (no blank space) - minimum zoom to fill the circular mask
        // s_min = max( Dpt / (W / σ),  Dpt / (H / σ) )
        let sCover = max(
            Dpt / (sourceSize.width / sigma),
            Dpt / (sourceSize.height / sigma)
        )
        
        // Quality-based maximum (visible crop must be ≥ outputSize × q per side)
        // Visible side at scale s in image pixels: visibleSidePx(s) = (Dpt × σ) / s
        // Require visibleSidePx(s) ≥ outputSize × q
        // s_quality = (Dpt × σ) / (outputSize × q)
        let sQuality = (Dpt * sigma) / (CGFloat(outputSize) * q)
        
        // Final zoom range calculation
        // s_max = min( s_min × maxZoomMultiplier,  s_quality )
        var sMax = min(sCover * maxZoomMultiplier, sQuality)
        let qualityLimited = sQuality <= sCover * maxZoomMultiplier
        
        // Ensure sMax >= sCover (if s_max < s_min → set s_max = s_min)
        if sMax < sCover {
            sMax = sCover
        }
        
        return (min: sCover, max: sMax, qualityLimited: qualityLimited)
    }
    
    // MARK: - Pan Translation Clamping
    
    /// Clamps translation to keep the image within valid pan bounds.
    /// Ensures the circular mask always displays image content (no blank background).
    ///
    /// - Parameters:
    ///   - scale: Current zoom scale (s)
    ///   - maskDiameterPoints: Diameter of circular mask in points (Dpt)
    ///   - screenScale: Screen scale factor (σ)
    ///   - sourceSize: Source image dimensions in pixels (W, H)
    ///   - proposedTranslation: Proposed translation in points
    /// - Returns: Clamped translation that keeps image within bounds
    public static func clampedTranslation(
        scale s: CGFloat,
        maskDiameterPoints Dpt: CGFloat,
        screenScale sigma: CGFloat,
        sourceSize: CGSize,
        proposedTranslation proposed: CGSize
    ) -> CGSize {
        
        // Displayed image size in points at current scale
        // dispW = (W / σ) × s
        // dispH = (H / σ) × s
        let dispW = (sourceSize.width / sigma) * s
        let dispH = (sourceSize.height / sigma) * s
        
        // Allowed translations (editor centered)
        // tx ∈ [-(dispW - Dpt)/2, +(dispW - Dpt)/2]
        // ty ∈ [-(dispH - Dpt)/2, +(dispH - Dpt)/2]
        let maxX = max(0, (dispW - Dpt) / 2)
        let maxY = max(0, (dispH - Dpt) / 2)
        
        return CGSize(
            width: min(max(proposed.width, -maxX), +maxX),
            height: min(max(proposed.height, -maxY), +maxY)
        )
    }
    
    // MARK: - Crop Rectangle Calculation
    
    /// Calculates the crop rectangle in image pixel coordinates based on current transform.
    /// Provides coordinate system precision for final image processing.
    ///
    /// - Parameters:
    ///   - scale: Current zoom scale (s)
    ///   - translation: Current translation in points, relative to center
    ///   - maskDiameterPoints: Diameter of circular mask in points (Dpt)
    ///   - screenScale: Screen scale factor (σ)
    ///   - sourceSize: Source image dimensions in pixels (W, H)
    /// - Returns: Crop rectangle in image pixel coordinates
    public static func cropRectInImagePixels(
        scale s: CGFloat,
        translation: CGSize,
        maskDiameterPoints Dpt: CGFloat,
        screenScale sigma: CGFloat,
        sourceSize: CGSize
    ) -> CGRect {
        
        let Dpx = Dpt * sigma
        
        // Image center in image pixel coords before translation
        let cx0 = sourceSize.width / 2
        let cy0 = sourceSize.height / 2
        
        // Translation is applied in points; convert to image pixels at current zoom.
        // Positive translation means image moved right/down => visible center moves left/up.
        let pxPerPoint = sigma / s
        let cx = cx0 - translation.width * pxPerPoint
        let cy = cy0 - translation.height * pxPerPoint
        
        let sidePx = Dpx / s
        var rect = CGRect(
            x: cx - sidePx / 2,
            y: cy - sidePx / 2,
            width: sidePx,
            height: sidePx
        ).integral
        
        // Clamp inside source (avoid nil cropping() and edge artifacts)
        rect.origin.x = max(0, min(rect.origin.x, sourceSize.width - rect.width))
        rect.origin.y = max(0, min(rect.origin.y, sourceSize.height - rect.height))
        
        return rect
    }
    
    // MARK: - Quality Validation
    
    /// Validates minimum pixel density to avoid softness on high-DPI displays.
    /// Ensures crispness at minimum zoom level.
    ///
    /// - Parameters:
    ///   - minScale: Minimum (cover) scale
    ///   - screenScale: Screen scale factor (σ)
    /// - Returns: True if pixel density meets minimum requirements (≥ 1.0 px/pt)
    public static func validateMinimumPixelDensity(
        minScale: CGFloat,
        screenScale sigma: CGFloat
    ) -> Bool {
        // Inside the circle at s_min, per-point pixels = σ / s_min
        // Require: σ / s_min ≥ 1.0
        let pixelsPerPoint = sigma / minScale
        return pixelsPerPoint >= 1.0
    }
    
    // MARK: - Utility Functions
    
    /// Calculates the visible crop area size in image pixels at a given scale.
    ///
    /// - Parameters:
    ///   - scale: Current zoom scale
    ///   - maskDiameterPoints: Diameter of circular mask in points
    ///   - screenScale: Screen scale factor
    /// - Returns: Side length of visible crop area in image pixels
    public static func visibleCropSideInPixels(
        scale: CGFloat,
        maskDiameterPoints: CGFloat,
        screenScale: CGFloat
    ) -> CGFloat {
        return (maskDiameterPoints * screenScale) / scale
    }
    
    /// Validates that a crop area meets quality requirements.
    ///
    /// - Parameters:
    ///   - cropSidePixels: Side length of crop area in pixels
    ///   - outputSize: Target output size
    ///   - qualityMultiplier: Quality factor
    /// - Returns: True if crop meets quality requirements
    public static func validateCropQuality(
        cropSidePixels: CGFloat,
        outputSize: Int,
        qualityMultiplier: CGFloat
    ) -> Bool {
        let requiredPixels = CGFloat(outputSize) * qualityMultiplier
        return cropSidePixels >= requiredPixels
    }
    
    // MARK: - Comprehensive Quality Assessment
    
    /// Performs comprehensive quality assessment for crop configuration.
    ///
    /// - Parameters:
    ///   - sourceSize: Source image dimensions in pixels
    ///   - scale: Current zoom scale
    ///   - maskDiameterPoints: Diameter of circular mask in points
    ///   - screenScale: Screen scale factor
    ///   - outputSize: Target output size
    ///   - qualityMultiplier: Quality factor
    /// - Returns: Quality assessment result with detailed metrics
    public static func assessCropQuality(
        sourceSize: CGSize,
        scale: CGFloat,
        maskDiameterPoints: CGFloat,
        screenScale: CGFloat,
        outputSize: Int,
        qualityMultiplier: CGFloat
    ) -> CropQualityAssessment {
        
        // Calculate visible crop area
        let visibleSide = visibleCropSideInPixels(
            scale: scale,
            maskDiameterPoints: maskDiameterPoints,
            screenScale: screenScale
        )
        
        // Pixel density validation
        let pixelDensity = screenScale / scale
        let meetsPixelDensity = pixelDensity >= 1.0
        
        // Quality validation
        let requiredPixels = CGFloat(outputSize) * qualityMultiplier
        let meetsQuality = visibleSide >= requiredPixels
        
        // Source image validation
        let minSourceDimension = min(sourceSize.width, sourceSize.height)
        let meetsSourceRequirement = minSourceDimension >= 320
        
        // Calculate quality score (0-1)
        let pixelScore = min(pixelDensity, 2.0) / 2.0 // Normalize to 0-1
        let qualityScore = min(visibleSide / requiredPixels, 2.0) / 2.0
        let sourceScore = min(minSourceDimension / 640, 1.0) // Normalize against ideal 640px
        let overallScore = (pixelScore + qualityScore + sourceScore) / 3.0
        
        return CropQualityAssessment(
            pixelDensity: pixelDensity,
            visibleCropSide: visibleSide,
            requiredCropSide: requiredPixels,
            sourceMinDimension: minSourceDimension,
            overallScore: overallScore,
            meetsPixelDensity: meetsPixelDensity,
            meetsQualityRequirement: meetsQuality,
            meetsSourceRequirement: meetsSourceRequirement,
            isAcceptable: meetsPixelDensity && meetsQuality && meetsSourceRequirement
        )
    }
    
    /// Calculates the maximum recommended zoom level for quality preservation.
    ///
    /// - Parameters:
    ///   - sourceSize: Source image dimensions in pixels
    ///   - maskDiameterPoints: Diameter of circular mask in points
    ///   - screenScale: Screen scale factor
    ///   - outputSize: Target output size
    ///   - qualityMultiplier: Quality factor
    /// - Returns: Maximum recommended zoom scale
    public static func maxRecommendedZoom(
        sourceSize: CGSize,
        maskDiameterPoints: CGFloat,
        screenScale: CGFloat,
        outputSize: Int,
        qualityMultiplier: CGFloat
    ) -> CGFloat {
        // Calculate quality-limited zoom
        let sQuality = (maskDiameterPoints * screenScale) / (CGFloat(outputSize) * qualityMultiplier)
        
        // Calculate cover zoom
        let sCover = max(
            maskDiameterPoints / (sourceSize.width / screenScale),
            maskDiameterPoints / (sourceSize.height / screenScale)
        )
        
        // Return the more restrictive limit
        return max(sCover, sQuality)
    }
    
    /// Validates crop area before final confirmation.
    ///
    /// - Parameters:
    ///   - cropRect: Crop rectangle in image pixels
    ///   - sourceSize: Source image dimensions
    ///   - outputSize: Target output size
    ///   - qualityMultiplier: Quality factor
    /// - Returns: Validation result with specific issues
    public static func validateCropBeforeConfirmation(
        cropRect: CGRect,
        sourceSize: CGSize,
        outputSize: Int,
        qualityMultiplier: CGFloat
    ) -> CropValidationResult {
        
        var issues: [CropValidationIssue] = []
        
        // Check crop rectangle bounds
        let sourceBounds = CGRect(origin: .zero, size: sourceSize)
        if !sourceBounds.contains(cropRect) {
            issues.append(.cropOutOfBounds)
        }
        
        // Check crop size
        let minCropSize = CGFloat(outputSize) * qualityMultiplier
        if cropRect.width < minCropSize || cropRect.height < minCropSize {
            issues.append(.cropTooSmall(
                current: min(cropRect.width, cropRect.height),
                required: minCropSize
            ))
        }
        
        // Check aspect ratio (should be square)
        let aspectRatio = cropRect.width / cropRect.height
        if abs(aspectRatio - 1.0) > 0.01 { // Allow 1% deviation
            issues.append(.nonSquareAspectRatio(aspectRatio))
        }
        
        // Check if crop is too close to edges (may cause artifacts)
        let edgeThreshold: CGFloat = 2.0
        if cropRect.minX < edgeThreshold ||
           cropRect.minY < edgeThreshold ||
           cropRect.maxX > sourceSize.width - edgeThreshold ||
           cropRect.maxY > sourceSize.height - edgeThreshold {
            issues.append(.tooCloseToEdges)
        }
        
        return CropValidationResult(
            isValid: issues.isEmpty,
            issues: issues,
            cropRect: cropRect
        )
    }
}

// MARK: - Quality Assessment Types

/// Comprehensive quality assessment result
public struct CropQualityAssessment: Sendable {
    /// Current pixel density (pixels per point)
    public let pixelDensity: CGFloat
    
    /// Visible crop side length in pixels
    public let visibleCropSide: CGFloat
    
    /// Required crop side length for quality
    public let requiredCropSide: CGFloat
    
    /// Minimum dimension of source image
    public let sourceMinDimension: CGFloat
    
    /// Overall quality score (0-1)
    public let overallScore: CGFloat
    
    /// Whether pixel density requirement is met
    public let meetsPixelDensity: Bool
    
    /// Whether quality requirement is met
    public let meetsQualityRequirement: Bool
    
    /// Whether source image requirement is met
    public let meetsSourceRequirement: Bool
    
    /// Whether crop is acceptable overall
    public let isAcceptable: Bool
    
    /// Quality grade based on overall score
    public var qualityGrade: String {
        if overallScore >= 0.9 { return "A" }
        if overallScore >= 0.8 { return "B" }
        if overallScore >= 0.7 { return "C" }
        if overallScore >= 0.6 { return "D" }
        return "F"
    }
}

/// Crop validation result for final confirmation
public struct CropValidationResult: Sendable {
    /// Whether the crop is valid
    public let isValid: Bool
    
    /// List of validation issues
    public let issues: [CropValidationIssue]
    
    /// The crop rectangle that was validated
    public let cropRect: CGRect
}

/// Specific crop validation issues
public enum CropValidationIssue: Sendable {
    case cropOutOfBounds
    case cropTooSmall(current: CGFloat, required: CGFloat)
    case nonSquareAspectRatio(CGFloat)
    case tooCloseToEdges
    
    /// User-friendly description of the issue
    public var description: String {
        switch self {
        case .cropOutOfBounds:
            return "Crop area extends beyond image boundaries"
        case .cropTooSmall(let current, let required):
            return "Crop area too small: \(Int(current))px, need \(Int(required))px"
        case .nonSquareAspectRatio(let ratio):
            return "Crop is not square: \(String(format: "%.2f", ratio)):1 ratio"
        case .tooCloseToEdges:
            return "Crop area too close to image edges"
        }
    }
}