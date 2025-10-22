//
//  ImageDataPickerBridge.swift
//  UIKitBridge
//
//  Created by Agora Team on 2024.
//

import SwiftUI

#if canImport(PhotosUI) && canImport(UIKit)
import PhotosUI
import UIKit

/// SwiftUI wrapper for image picker that works with Data
/// This follows SwiftUI-first architecture by keeping UIKit isolated
@available(iOS 26.0, *)
public struct ImageDataPickerBridge: UIViewControllerRepresentable {
    @Binding var imageData: Data?
    @Environment(\.dismiss) private var dismiss
    
    public init(imageData: Binding<Data?>) {
        self._imageData = imageData
    }
    
    public func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    public func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        // No updates needed - state is managed by binding
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImageDataPickerBridge
        
        init(_ parent: ImageDataPickerBridge) {
            self.parent = parent
        }
        
        public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let result = results.first else {
                parent.imageData = nil
                return
            }
            
            // Load the selected image as Data
            result.itemProvider.loadDataRepresentation(forTypeIdentifier: "public.image") { data, error in
                DispatchQueue.main.async {
                    if let data = data {
                        self.parent.imageData = data
                    } else {
                        self.parent.imageData = nil
                    }
                }
            }
        }
    }
}

#else
// Fallback for platforms without PhotosUI/UIKit
@available(iOS 26.0, macOS 26.0, *)
public struct ImageDataPickerBridge: View {
    @Binding var imageData: Data?
    
    public init(imageData: Binding<Data?>) {
        self._imageData = imageData
    }
    
    public var body: some View {
        Text("Image picker not available on this platform")
            .foregroundColor(.secondary)
    }
}
#endif
