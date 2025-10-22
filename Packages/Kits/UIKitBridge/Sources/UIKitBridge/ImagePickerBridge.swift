//
//  ImagePickerBridge.swift
//  UIKitBridge
//
//  Created by Agora Team on 2024.
//

import SwiftUI

#if canImport(PhotosUI) && canImport(UIKit)
import PhotosUI
import UIKit

/// SwiftUI wrapper for simple image picker
@available(iOS 26.0, *)
public struct ImagePickerBridge: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    public init(image: Binding<UIImage?>) {
        self._image = image
    }
    
    public func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    public func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePickerBridge
        
        init(_ parent: ImagePickerBridge) {
            self.parent = parent
        }
        
        public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { object, _ in
                    guard let uiImage = object as? UIImage else { return }
                    Task { @MainActor in
                        self.parent.image = uiImage
                    }
                }
            }
        }
    }
}

#endif
