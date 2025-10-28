#!/usr/bin/env swift

import Foundation
import CoreGraphics

// MARK: - Performance Benchmark Script for Avatar Cropping System

print("🚀 Avatar Cropping Performance Benchmark")
print("=========================================")

// MARK: - Crop Geometry Performance Test

func benchmarkCropGeometry() {
    print("\n📐 Testing Crop Geometry Performance...")
    
    let sourceSize = CGSize(width: 2048, height: 2048)
    let maskDiameter: CGFloat = 300
    let screenScale: CGFloat = 3.0
    let outputSize = 512
    let qualityMultiplier: CGFloat = 1.25
    let maxZoomMultiplier: CGFloat = 4.0
    
    // Simulate 60fps for 1 second
    let iterations = 60
    let startTime = Date()
    
    for i in 0..<iterations {
        let scale = 1.0 + CGFloat(i) * 0.01
        let translation = CGSize(width: CGFloat(i) * 0.5, height: CGFloat(i) * 0.3)
        
        // Core calculations that happen during gestures
        let _ = calculateZoomRange(
            maskDiameter: maskDiameter,
            screenScale: screenScale,
            sourceSize: sourceSize,
            outputSize: outputSize,
            qualityMultiplier: qualityMultiplier,
            maxZoomMultiplier: maxZoomMultiplier
        )
        
        let _ = clampTranslation(
            scale: scale,
            maskDiameter: maskDiameter,
            screenScale: screenScale,
            sourceSize: sourceSize,
            proposed: translation
        )
        
        let _ = calculateCropRect(
            scale: scale,
            translation: translation,
            maskDiameter: maskDiameter,
            screenScale: screenScale,
            sourceSize: sourceSize
        )
    }
    
    let totalTime = Date().timeIntervalSince(startTime)
    let averageTime = totalTime / Double(iterations)
    let targetTime = 1.0 / 60.0 // 16.67ms per frame
    
    let status = averageTime < targetTime / 2 ? "✅ PASS" : "❌ FAIL"
    print("   Average calculation time: \(String(format: "%.2f", averageTime * 1000))ms")
    print("   Target for 60fps: <\(String(format: "%.2f", targetTime * 500))ms")
    print("   Status: \(status)")
}

// MARK: - Memory Usage Simulation

func benchmarkMemoryUsage() {
    print("\n💾 Testing Memory Usage Patterns...")
    
    let imageSizes = [
        (1024, 1024, "1MP"),
        (2048, 2048, "4MP"),
        (3024, 4032, "12MP iPhone"),
        (4032, 3024, "12MP Landscape"),
        (4096, 4096, "16MP")
    ]
    
    for (width, height, description) in imageSizes {
        let estimatedMemory = estimateMemoryUsage(width: width, height: height)
        let shouldUseFallback = estimatedMemory > 100 * 1024 * 1024 // 100MB threshold
        
        print("   \(description) (\(width)x\(height)): \(estimatedMemory / 1024 / 1024)MB - \(shouldUseFallback ? "Fallback" : "Normal")")
    }
}

// MARK: - Telemetry Performance Test

func benchmarkTelemetryOverhead() {
    print("\n📊 Testing Telemetry Performance Overhead...")
    
    let iterations = 1000
    
    // Baseline test (no telemetry)
    let baselineStart = Date()
    for i in 0..<iterations {
        let _ = CGRect(x: i, y: i, width: 100, height: 100)
    }
    let baselineTime = Date().timeIntervalSince(baselineStart)
    
    // With telemetry simulation
    let telemetryStart = Date()
    for i in 0..<iterations {
        let rect = CGRect(x: i, y: i, width: 100, height: 100)
        
        // Simulate telemetry logging
        simulateTelemetryLogging(
            sourceSize: CGSize(width: 1000, height: 1000),
            cropRect: rect,
            outputSize: 512,
            processingTime: 0.1
        )
    }
    let telemetryTime = Date().timeIntervalSince(telemetryStart)
    
    let overhead = telemetryTime - baselineTime
    let overheadPercentage = (overhead / baselineTime) * 100
    
    let status = overheadPercentage < 50 ? "✅ PASS" : "❌ FAIL"
    print("   Baseline time: \(String(format: "%.2f", baselineTime * 1000))ms")
    print("   With telemetry: \(String(format: "%.2f", telemetryTime * 1000))ms")
    print("   Overhead: \(String(format: "%.1f", overheadPercentage))%")
    print("   Status: \(status)")
}

// MARK: - Image Processing Performance

func benchmarkImageProcessing() {
    print("\n🖼️ Testing Image Processing Performance...")
    
    let testSizes = [
        (512, 512, "Small"),
        (1024, 1024, "Medium"),
        (2048, 2048, "Large"),
        (4096, 4096, "XLarge")
    ]
    
    for (width, height, description) in testSizes {
        let startTime = Date()
        
        // Simulate image processing steps
        let _ = createTestImage(width: width, height: height)
        let processingTime = Date().timeIntervalSince(startTime)
        
        let status = processingTime < 0.3 ? "✅ PASS" : "❌ FAIL"
        print("   \(description) (\(width)x\(height)): \(String(format: "%.1f", processingTime * 1000))ms \(status)")
    }
}

// MARK: - Helper Functions

func calculateZoomRange(
    maskDiameter: CGFloat,
    screenScale: CGFloat,
    sourceSize: CGSize,
    outputSize: Int,
    qualityMultiplier: CGFloat,
    maxZoomMultiplier: CGFloat
) -> (min: CGFloat, max: CGFloat, qualityLimited: Bool) {
    // Cover scale (no blank space)
    let sCover = max(
        maskDiameter / (sourceSize.width / screenScale),
        maskDiameter / (sourceSize.height / screenScale)
    )
    
    // Quality scale (maintain resolution)
    let sQuality = (maskDiameter * screenScale) / (CGFloat(outputSize) * qualityMultiplier)
    
    // Check if quality limits zoom before maxZoomMultiplier
    var sMax = min(sCover * maxZoomMultiplier, sQuality)
    let qualityLimited = sQuality <= sCover * maxZoomMultiplier
    
    // Ensure sMax >= sCover
    if sMax < sCover { sMax = sCover }
    
    return (sCover, sMax, qualityLimited)
}

func clampTranslation(
    scale: CGFloat,
    maskDiameter: CGFloat,
    screenScale: CGFloat,
    sourceSize: CGSize,
    proposed: CGSize
) -> CGSize {
    let dispW = (sourceSize.width / screenScale) * scale
    let dispH = (sourceSize.height / screenScale) * scale
    let maxX = max(0, (dispW - maskDiameter) / 2)
    let maxY = max(0, (dispH - maskDiameter) / 2)
    
    return CGSize(
        width: min(max(proposed.width, -maxX), +maxX),
        height: min(max(proposed.height, -maxY), +maxY)
    )
}

func calculateCropRect(
    scale: CGFloat,
    translation: CGSize,
    maskDiameter: CGFloat,
    screenScale: CGFloat,
    sourceSize: CGSize
) -> CGRect {
    let maskDiameterPixels = maskDiameter * screenScale
    
    let cx0 = sourceSize.width / 2
    let cy0 = sourceSize.height / 2
    
    let pxPerPoint = screenScale / scale
    let cx = cx0 - translation.width * pxPerPoint
    let cy = cy0 - translation.height * pxPerPoint
    
    let sidePx = maskDiameterPixels / scale
    var rect = CGRect(
        x: cx - sidePx / 2,
        y: cy - sidePx / 2,
        width: sidePx,
        height: sidePx
    )
    
    // Clamp to source bounds
    rect.origin.x = max(0, min(rect.origin.x, sourceSize.width - rect.width))
    rect.origin.y = max(0, min(rect.origin.y, sourceSize.height - rect.height))
    
    return rect
}

func estimateMemoryUsage(width: Int, height: Int) -> Int {
    // Estimate memory usage: 4 bytes per pixel (RGBA) for both original and thumbnail
    let originalMemory = width * height * 4
    let thumbnailMemory = 2560 * 2560 * 4 // Max thumbnail size
    return originalMemory + thumbnailMemory
}

func simulateTelemetryLogging(
    sourceSize: CGSize,
    cropRect: CGRect,
    outputSize: Int,
    processingTime: TimeInterval
) {
    // Simulate telemetry data collection
    let aspectRatio = sourceSize.width / sourceSize.height
    let cropEfficiency = (cropRect.width * cropRect.height) / (sourceSize.width * sourceSize.height)
    
    let _: [String: Any] = [
        "source_width": Int(sourceSize.width),
        "source_height": Int(sourceSize.height),
        "aspect_ratio": Double(aspectRatio),
        "crop_efficiency": Double(cropEfficiency),
        "output_size": outputSize,
        "processing_time_ms": Int(processingTime * 1000)
    ]
}

func createTestImage(width: Int, height: Int) -> CGImage? {
    let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
    guard let context = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { return nil }
    
    // Fill with test pattern
    context.setFillColor(CGColor(red: 0.5, green: 0.7, blue: 0.9, alpha: 1.0))
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    
    return context.makeImage()
}

// MARK: - Run Benchmarks

benchmarkCropGeometry()
benchmarkMemoryUsage()
benchmarkTelemetryOverhead()
benchmarkImageProcessing()

print("\n🏁 Benchmark Complete!")
print("=====================================")
print("Key Performance Requirements:")
print("• Gesture calculations: <8.33ms (60fps)")
print("• Crop processing: 100-300ms")
print("• Memory usage: <200MB for large images")
print("• Telemetry overhead: <50%")