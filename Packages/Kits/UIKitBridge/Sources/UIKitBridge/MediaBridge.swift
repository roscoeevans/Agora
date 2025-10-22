import Foundation

#if os(iOS)
import UIKit

/// Bridge between UIKit UIImage and the Media package's platform-agnostic API
public struct MediaBridge {
    
    // MARK: - Image Data Conversion
    
    /// Convert UIImage to JPEG data with compression
    /// - Parameters:
    ///   - image: The UIImage to convert
    ///   - compressionQuality: JPEG compression quality (0.0 to 1.0)
    /// - Returns: JPEG data
    public static func jpegData(from image: UIImage, compressionQuality: CGFloat = 0.85) -> Data? {
        return image.jpegData(compressionQuality: compressionQuality)
    }
    
    /// Convert UIImage to Data
    /// - Parameters:
    ///   - image: The UIImage to convert
    ///   - compressionQuality: JPEG compression quality (0.0 to 1.0)
    /// - Returns: Image data
    public static func data(from image: UIImage, compressionQuality: CGFloat = 0.85) -> Data? {
        return image.jpegData(compressionQuality: compressionQuality)
    }
    
    /// Convert Data to UIImage
    /// - Parameter data: Image data
    /// - Returns: UIImage if data is valid image data
    public static func uiImage(from data: Data) -> UIImage? {
        return UIImage(data: data)
    }
    
    /// Convert CGImage to UIImage
    /// - Parameter cgImage: The CGImage to convert
    /// - Returns: UIImage representation
    public static func uiImage(from cgImage: CGImage) -> UIImage {
        return UIImage(cgImage: cgImage)
    }
    
    /// Convert UIImage to CGImage
    /// - Parameter image: The UIImage to convert
    /// - Returns: CGImage representation
    public static func cgImage(from image: UIImage) -> CGImage? {
        return image.cgImage
    }
    
    // MARK: - Image Processing
    
    /// Resize UIImage to fit within specified dimensions
    /// - Parameters:
    ///   - image: The UIImage to resize
    ///   - maxSize: Maximum dimensions
    /// - Returns: Resized UIImage
    public static func resizeImage(_ image: UIImage, maxSize: CGSize) -> UIImage? {
        return image.resized(to: maxSize)
    }
    
    /// Get image dimensions from UIImage
    /// - Parameter image: The UIImage
    /// - Returns: Image dimensions
    public static func imageDimensions(from image: UIImage) -> CGSize {
        return image.size
    }
    
    // MARK: - Array Conversions
    
    /// Convert array of UIImages to array of Data
    /// - Parameters:
    ///   - images: Array of UIImages
    ///   - compressionQuality: JPEG compression quality (0.0 to 1.0)
    /// - Returns: Array of image data
    public static func dataArray(from images: [UIImage], compressionQuality: CGFloat = 0.85) -> [Data] {
        return images.compactMap { image in
            image.jpegData(compressionQuality: compressionQuality)
        }
    }
    
    /// Convert array of Data to array of UIImages
    /// - Parameter dataArray: Array of image data
    /// - Returns: Array of UIImages
    public static func uiImageArray(from dataArray: [Data]) -> [UIImage] {
        return dataArray.compactMap { data in
            UIImage(data: data)
        }
    }
}
#endif
