import Foundation
import SwiftUI

#if os(iOS)
import UIKit

/// SwiftUI representables for media-related UIKit components
public struct MediaRepresentables {
    
    /// Image picker for selecting photos from the library
    public struct ImagePicker: UIViewControllerRepresentable {
        @Binding var selectedImage: UIImage?
        @Environment(\.dismiss) private var dismiss
        
        public init(selectedImage: Binding<UIImage?>) {
            self._selectedImage = selectedImage
        }
        
        public func makeUIViewController(context: Context) -> UIImagePickerController {
            let picker = UIImagePickerController()
            picker.delegate = context.coordinator
            picker.sourceType = .photoLibrary
            picker.allowsEditing = true
            return picker
        }
        
        public func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
        
        public func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }
        
        public class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
            let parent: ImagePicker
            
            init(_ parent: ImagePicker) {
                self.parent = parent
            }
            
            public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
                if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
                    parent.selectedImage = image
                }
                parent.dismiss()
            }
            
            public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
                parent.dismiss()
            }
        }
    }
    
    /// Camera picker for taking photos
    public struct CameraPicker: UIViewControllerRepresentable {
        @Binding var selectedImage: UIImage?
        @Environment(\.dismiss) private var dismiss
        
        public init(selectedImage: Binding<UIImage?>) {
            self._selectedImage = selectedImage
        }
        
        public func makeUIViewController(context: Context) -> UIImagePickerController {
            let picker = UIImagePickerController()
            picker.delegate = context.coordinator
            picker.sourceType = .camera
            picker.allowsEditing = true
            return picker
        }
        
        public func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
        
        public func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }
        
        public class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
            let parent: CameraPicker
            
            init(_ parent: CameraPicker) {
                self.parent = parent
            }
            
            public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
                if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
                    parent.selectedImage = image
                }
                parent.dismiss()
            }
            
            public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
                parent.dismiss()
            }
        }
    }
}
#endif
