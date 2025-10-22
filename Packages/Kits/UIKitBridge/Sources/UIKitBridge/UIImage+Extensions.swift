import Foundation

#if os(iOS)
import UIKit

public extension UIImage {
    /// Resize image to fit within the specified size while maintaining aspect ratio
    func resized(to targetSize: CGSize) -> UIImage? {
        let size = self.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // Use the smaller ratio to ensure the image fits within bounds
        let scaleFactor = min(widthRatio, heightRatio)
        
        let scaledSize = CGSize(
            width: size.width * scaleFactor,
            height: size.height * scaleFactor
        )
        
        let renderer = UIGraphicsImageRenderer(size: scaledSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: scaledSize))
        }
    }
    
    /// Convert UIImage to JPEG data with specified compression quality
    func jpegData(compressionQuality: CGFloat) -> Data? {
        return self.jpegData(compressionQuality: compressionQuality)
    }
    
    /// Get the size of the image
    var imageSize: CGSize {
        return self.size
    }
}
#endif
