import Foundation
import CoreGraphics
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Quality Assurance Manager

/// Manages quality assurance checks and warnings for avatar cropping
@MainActor
public final class CropQualityAssuranceManager: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current quality warnings
    @Published public var activeWarnings: Set<QualityWarning> = []
    
    /// Whether quality-limited zoom warning has been shown
    @Published public var qualityLimitWarningShown: Bool = false
    
    /// Current quality metrics
    @Published public var qualityMetrics: QualityMetrics?
    
    /// Whether to show quality indicators in UI
    @Published public var showQualityIndicators: Bool = true
    
    // MARK: - Configuration
    
    /// Quality assurance configuration
    public let config: QualityAssuranceConfig
    
    // MARK: - Initialization
    
    public init(config: QualityAssuranceConfig = .default) {
        self.config = config
    }
    
    // MARK: - Quality Validation
    
    /// Validate crop quality and generate warnings
    /// - Parameters:
    ///   - sourceSize: Source image size in pixels
    ///   - cropRect: Crop rectangle in pixels
    ///   - scale: Current zoom scale
    ///   - maskDiameter: Mask diameter in points
    ///   - screenScale: Screen scale factor
    ///   - outputSize: Target output size
    /// - Returns: Quality validation result
    public func validateCropQuality(
        sourceSize: CGSize,
        cropRect: CGRect,
        scale: CGFloat,
        maskDiameter: CGFloat,
        screenScale: CGFloat,
        outputSize: Int
    ) -> QualityValidationResult {
        
        var warnings: Set<QualityWarning> = []
        var metrics = QualityMetrics()
        
        // Calculate quality metrics
        let cropSize = cropRect.size
        let pixelDensity = calculatePixelDensity(
            cropSize: cropSize,
            outputSize: outputSize
        )
        let zoomQuality = calculateZoomQuality(
            scale: scale,
            sourceSize: sourceSize,
            maskDiameter: maskDiameter,
            screenScale: screenScale,
            outputSize: outputSize
        )
        
        metrics.pixelDensity = pixelDensity
        metrics.zoomQuality = zoomQuality
        metrics.cropAreaRatio = (cropSize.width * cropSize.height) / (sourceSize.width * sourceSize.height)
        metrics.aspectRatioDeviation = abs(cropSize.width - cropSize.height) / max(cropSize.width, cropSize.height)
        
        // Pixel density validation
        if pixelDensity < config.minimumPixelDensity {
            warnings.insert(.lowPixelDensity(
                current: pixelDensity,
                minimum: config.minimumPixelDensity
            ))
        }
        
        // Zoom quality validation
        if zoomQuality < config.minimumZoomQuality {
            warnings.insert(.qualityLimitedZoom(
                current: zoomQuality,
                minimum: config.minimumZoomQuality
            ))
        }
        
        // Crop area validation
        let minCropArea = CGSize(
            width: CGFloat(outputSize) * config.qualityMultiplier,
            height: CGFloat(outputSize) * config.qualityMultiplier
        )
        
        if cropSize.width < minCropArea.width || cropSize.height < minCropArea.height {
            warnings.insert(.cropAreaTooSmall(
                current: cropSize,
                minimum: minCropArea
            ))
        }
        
        // Source image quality validation
        let minSourceDimension = min(sourceSize.width, sourceSize.height)
        if minSourceDimension < config.minimumSourceDimension {
            warnings.insert(.sourceImageTooSmall(
                current: minSourceDimension,
                minimum: config.minimumSourceDimension
            ))
        }
        
        // Update state
        activeWarnings = warnings
        qualityMetrics = metrics
        
        return QualityValidationResult(
            isValid: warnings.isEmpty,
            warnings: warnings,
            metrics: metrics,
            recommendedActions: generateRecommendedActions(for: warnings)
        )
    }
    
    /// Show quality-limited zoom warning (one-time)
    public func showQualityLimitWarning() {
        guard !qualityLimitWarningShown else { return }
        qualityLimitWarningShown = true
        
        // Add temporary warning that auto-dismisses
        activeWarnings.insert(.qualityLimitedZoom(current: 0, minimum: 1))
        
        Task {
            try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            activeWarnings.remove(.qualityLimitedZoom(current: 0, minimum: 1))
        }
    }
    
    /// Clear all warnings
    public func clearWarnings() {
        activeWarnings.removeAll()
    }
    
    /// Reset quality assurance state
    public func reset() {
        activeWarnings.removeAll()
        qualityLimitWarningShown = false
        qualityMetrics = nil
    }
    
    // MARK: - Private Methods
    
    private func calculatePixelDensity(cropSize: CGSize, outputSize: Int) -> CGFloat {
        let cropPixels = cropSize.width * cropSize.height
        let outputPixels = CGFloat(outputSize * outputSize)
        return cropPixels / outputPixels
    }
    
    private func calculateZoomQuality(
        scale: CGFloat,
        sourceSize: CGSize,
        maskDiameter: CGFloat,
        screenScale: CGFloat,
        outputSize: Int
    ) -> CGFloat {
        // Calculate visible area in source pixels
        let visibleSidePx = (maskDiameter * screenScale) / scale
        let visibleAreaPx = visibleSidePx * visibleSidePx
        
        // Calculate output area
        let outputAreaPx = CGFloat(outputSize * outputSize)
        
        // Quality ratio (higher is better)
        return visibleAreaPx / outputAreaPx
    }
    
    private func generateRecommendedActions(for warnings: Set<QualityWarning>) -> [QualityAction] {
        var actions: [QualityAction] = []
        
        for warning in warnings {
            switch warning {
            case .lowPixelDensity:
                actions.append(.zoomOut)
                actions.append(.useHigherResolutionImage)
                
            case .qualityLimitedZoom:
                actions.append(.zoomOut)
                actions.append(.acceptLowerQuality)
                
            case .cropAreaTooSmall:
                actions.append(.zoomOut)
                actions.append(.adjustCropArea)
                
            case .sourceImageTooSmall:
                actions.append(.useHigherResolutionImage)
                actions.append(.takeBetterPhoto)
            }
        }
        
        return Array(Set(actions)) // Remove duplicates
    }
}

// MARK: - Quality Warning

/// Types of quality warnings that can be generated
public enum QualityWarning: Hashable, Sendable {
    case lowPixelDensity(current: CGFloat, minimum: CGFloat)
    case qualityLimitedZoom(current: CGFloat, minimum: CGFloat)
    case cropAreaTooSmall(current: CGSize, minimum: CGSize)
    case sourceImageTooSmall(current: CGFloat, minimum: CGFloat)
    
    /// User-friendly warning message
    public var message: String {
        switch self {
        case .lowPixelDensity:
            return "Image may appear blurry at this zoom level"
        case .qualityLimitedZoom:
            return "Zoom limited by photo quality"
        case .cropAreaTooSmall:
            return "Crop area too small for optimal quality"
        case .sourceImageTooSmall:
            return "Photo resolution is too low"
        }
    }
    
    /// Detailed explanation
    public var explanation: String {
        switch self {
        case .lowPixelDensity(let current, let minimum):
            return "Current pixel density: \(String(format: "%.1f", current)), minimum recommended: \(String(format: "%.1f", minimum))"
        case .qualityLimitedZoom(let current, let minimum):
            return "Zoom quality: \(String(format: "%.1f", current)), minimum recommended: \(String(format: "%.1f", minimum))"
        case .cropAreaTooSmall(let current, let minimum):
            return "Current crop: \(Int(current.width))×\(Int(current.height))px, recommended: \(Int(minimum.width))×\(Int(minimum.height))px"
        case .sourceImageTooSmall(let current, let minimum):
            return "Current size: \(Int(current))px, minimum recommended: \(Int(minimum))px"
        }
    }
    
    /// Warning severity level
    public var severity: WarningSeverity {
        switch self {
        case .lowPixelDensity, .qualityLimitedZoom:
            return .medium
        case .cropAreaTooSmall:
            return .high
        case .sourceImageTooSmall:
            return .critical
        }
    }
    
    /// Icon for the warning
    public var icon: String {
        switch self {
        case .lowPixelDensity, .qualityLimitedZoom:
            return "eye.trianglebadge.exclamationmark"
        case .cropAreaTooSmall:
            return "crop"
        case .sourceImageTooSmall:
            return "photo.badge.exclamationmark"
        }
    }
}

/// Warning severity levels
public enum WarningSeverity: Int, Sendable, CaseIterable {
    case low = 1
    case medium = 2
    case high = 3
    case critical = 4
    
    public var color: Color {
        switch self {
        case .low:
            return .blue
        case .medium:
            return .orange
        case .high:
            return .red
        case .critical:
            return .purple
        }
    }
}

// MARK: - Quality Metrics

/// Comprehensive quality metrics for crop operation
public struct QualityMetrics: Sendable {
    /// Pixel density ratio (crop pixels / output pixels)
    public var pixelDensity: CGFloat = 0
    
    /// Zoom quality ratio (visible area / output area)
    public var zoomQuality: CGFloat = 0
    
    /// Crop area as ratio of source image (0-1)
    public var cropAreaRatio: CGFloat = 0
    
    /// Aspect ratio deviation from square (0 = perfect square)
    public var aspectRatioDeviation: CGFloat = 0
    
    /// Overall quality score (0-1, higher is better)
    public var overallScore: CGFloat {
        let pixelScore = min(pixelDensity / 2.0, 1.0) // Normalize to 0-1
        let zoomScore = min(zoomQuality / 2.0, 1.0)
        let areaScore = min(cropAreaRatio * 4.0, 1.0) // Prefer larger crop areas
        let aspectScore = 1.0 - aspectRatioDeviation // Prefer square crops
        
        return (pixelScore + zoomScore + areaScore + aspectScore) / 4.0
    }
    
    /// Quality grade (A-F)
    public var grade: QualityGrade {
        let score = overallScore
        if score >= 0.9 { return .A }
        if score >= 0.8 { return .B }
        if score >= 0.7 { return .C }
        if score >= 0.6 { return .D }
        return .F
    }
}

/// Quality grade enumeration
public enum QualityGrade: String, Sendable, CaseIterable {
    case A, B, C, D, F
    
    public var color: Color {
        switch self {
        case .A: return .green
        case .B: return .blue
        case .C: return .orange
        case .D: return .red
        case .F: return .purple
        }
    }
    
    public var description: String {
        switch self {
        case .A: return "Excellent"
        case .B: return "Good"
        case .C: return "Fair"
        case .D: return "Poor"
        case .F: return "Unacceptable"
        }
    }
}

// MARK: - Quality Validation Result

/// Result of quality validation check
public struct QualityValidationResult: Sendable {
    /// Whether the crop meets quality standards
    public let isValid: Bool
    
    /// Active quality warnings
    public let warnings: Set<QualityWarning>
    
    /// Quality metrics
    public let metrics: QualityMetrics
    
    /// Recommended actions to improve quality
    public let recommendedActions: [QualityAction]
    
    /// Whether crop should be blocked due to quality issues
    public var shouldBlockCrop: Bool {
        warnings.contains { $0.severity == .critical }
    }
}

// MARK: - Quality Action

/// Recommended actions to improve crop quality
public enum QualityAction: String, Sendable, CaseIterable {
    case zoomOut = "zoom_out"
    case useHigherResolutionImage = "use_higher_resolution"
    case adjustCropArea = "adjust_crop_area"
    case takeBetterPhoto = "take_better_photo"
    case acceptLowerQuality = "accept_lower_quality"
    
    public var title: String {
        switch self {
        case .zoomOut:
            return "Zoom Out"
        case .useHigherResolutionImage:
            return "Use Higher Resolution Image"
        case .adjustCropArea:
            return "Adjust Crop Area"
        case .takeBetterPhoto:
            return "Take Better Photo"
        case .acceptLowerQuality:
            return "Accept Lower Quality"
        }
    }
    
    public var description: String {
        switch self {
        case .zoomOut:
            return "Zoom out to include more of the original image"
        case .useHigherResolutionImage:
            return "Select a higher resolution photo from your library"
        case .adjustCropArea:
            return "Reposition the crop area for better coverage"
        case .takeBetterPhoto:
            return "Take a new photo with your camera"
        case .acceptLowerQuality:
            return "Continue with current quality settings"
        }
    }
    
    public var icon: String {
        switch self {
        case .zoomOut:
            return "minus.magnifyingglass"
        case .useHigherResolutionImage:
            return "photo.stack"
        case .adjustCropArea:
            return "crop.rotate"
        case .takeBetterPhoto:
            return "camera"
        case .acceptLowerQuality:
            return "checkmark.circle"
        }
    }
}

// MARK: - Quality Assurance Configuration

/// Configuration for quality assurance checks
public struct QualityAssuranceConfig: Sendable {
    /// Minimum pixel density (crop pixels / output pixels)
    public let minimumPixelDensity: CGFloat
    
    /// Minimum zoom quality ratio
    public let minimumZoomQuality: CGFloat
    
    /// Quality multiplier for crop area validation
    public let qualityMultiplier: CGFloat
    
    /// Minimum source image dimension
    public let minimumSourceDimension: CGFloat
    
    /// Whether to show quality warnings
    public let showWarnings: Bool
    
    /// Whether to block crops that fail quality checks
    public let blockLowQualityCrops: Bool
    
    public init(
        minimumPixelDensity: CGFloat = 1.25,
        minimumZoomQuality: CGFloat = 1.0,
        qualityMultiplier: CGFloat = 1.25,
        minimumSourceDimension: CGFloat = 320,
        showWarnings: Bool = true,
        blockLowQualityCrops: Bool = false
    ) {
        self.minimumPixelDensity = minimumPixelDensity
        self.minimumZoomQuality = minimumZoomQuality
        self.qualityMultiplier = qualityMultiplier
        self.minimumSourceDimension = minimumSourceDimension
        self.showWarnings = showWarnings
        self.blockLowQualityCrops = blockLowQualityCrops
    }
    
    public static let `default` = QualityAssuranceConfig()
    
    public static let strict = QualityAssuranceConfig(
        minimumPixelDensity: 2.0,
        minimumZoomQuality: 1.5,
        qualityMultiplier: 1.5,
        minimumSourceDimension: 640,
        showWarnings: true,
        blockLowQualityCrops: true
    )
    
    public static let permissive = QualityAssuranceConfig(
        minimumPixelDensity: 1.0,
        minimumZoomQuality: 0.8,
        qualityMultiplier: 1.0,
        minimumSourceDimension: 240,
        showWarnings: false,
        blockLowQualityCrops: false
    )
}

// MARK: - Quality Indicator Views

/// SwiftUI view for displaying quality warnings
public struct QualityWarningView: View {
    let warning: QualityWarning
    let onDismiss: (() -> Void)?
    
    public init(warning: QualityWarning, onDismiss: (() -> Void)? = nil) {
        self.warning = warning
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        HStack {
            Image(systemName: warning.icon)
                .foregroundColor(warning.severity.color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(warning.message)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(warning.explanation)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let onDismiss = onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(warning.severity.color.opacity(0.1))
        .cornerRadius(8)
    }
}

/// SwiftUI view for displaying quality metrics
public struct QualityMetricsView: View {
    let metrics: QualityMetrics
    
    public init(metrics: QualityMetrics) {
        self.metrics = metrics
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Quality Score")
                    .font(.headline)
                
                Spacer()
                
                HStack {
                    Text(metrics.grade.rawValue)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(metrics.grade.color)
                    
                    Text(metrics.grade.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(spacing: 4) {
                QualityMetricRow(
                    title: "Pixel Density",
                    value: metrics.pixelDensity,
                    format: "%.1fx"
                )
                
                QualityMetricRow(
                    title: "Zoom Quality",
                    value: metrics.zoomQuality,
                    format: "%.1fx"
                )
                
                QualityMetricRow(
                    title: "Crop Coverage",
                    value: metrics.cropAreaRatio * 100,
                    format: "%.0f%%"
                )
            }
        }
        .padding()
        .background(Color(white: 0.95))
        .cornerRadius(12)
    }
}

/// Row for displaying a single quality metric
private struct QualityMetricRow: View {
    let title: String
    let value: CGFloat
    let format: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(String(format: format, value))
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Add quality warning overlay
    public func qualityWarnings(
        _ warnings: Set<QualityWarning>,
        onDismiss: @escaping (QualityWarning) -> Void
    ) -> some View {
        self.overlay(alignment: .top) {
            VStack(spacing: 4) {
                ForEach(Array(warnings.sorted { $0.severity.rawValue > $1.severity.rawValue }), id: \.self) { warning in
                    QualityWarningView(warning: warning) {
                        onDismiss(warning)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }
    
    /// Add quality metrics display
    public func qualityMetrics(
        _ metrics: QualityMetrics?,
        isVisible: Bool = true
    ) -> some View {
        self.overlay(alignment: .bottom) {
            if let metrics = metrics, isVisible {
                QualityMetricsView(metrics: metrics)
                    .padding()
            }
        }
    }
}