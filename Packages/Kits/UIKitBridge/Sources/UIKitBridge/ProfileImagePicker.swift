//
//  ProfileImagePicker.swift
//  UIKitBridge
//
//  Created by Agora Team on 2024.
//

import SwiftUI

#if canImport(PhotosUI) && canImport(UIKit)
import PhotosUI
import UIKit

/// SwiftUI wrapper for profile image selection with validation and cropping
@available(iOS 26.0, *)
public struct ProfileImagePicker: View {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    @State private var showImagePicker = false
    @State private var showCropper = false
    @State private var tempImage: UIImage?
    @State private var validationError: String?
    @State private var isProcessing = false
    
    public init(selectedImage: Binding<UIImage?>) {
        self._selectedImage = selectedImage
    }
    
    public var body: some View {
        VStack {
            if let validationError = validationError {
                errorView(validationError)
            }
            
            if isProcessing {
                processingView
            }
        }
        .sheet(isPresented: $showImagePicker) {
            SimpleProfileImagePicker(selectedImage: Binding<UIImage?>(
                get: { tempImage },
                set: { newImage in
                    if let image = newImage {
                        handleImageSelection(image)
                    }
                }
            ))
        }
        .fullScreenCover(isPresented: $showCropper) {
            if let image = tempImage {
                ImageCropperView(
                    image: image,
                    onCrop: { croppedImage in
                        selectedImage = croppedImage
                        dismiss()
                    },
                    onCancel: {
                        tempImage = nil
                        showCropper = false
                    }
                )
            }
        }
        .onAppear {
            showImagePicker = true
        }
    }
    
    
    private func errorView(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.red)
            
            Spacer()
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal)
    }
    
    private var processingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Processing image...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
        .padding()
    }
    
    private func handleImageSelection(_ image: UIImage) {
        // Validate image
        let validationResult = ImageProcessingBridge.validateProfileImage(image)
        
        switch validationResult {
        case .valid:
            tempImage = image
            showImagePicker = false
            showCropper = true
            validationError = nil
        default:
            validationError = ImageProcessingBridge.errorMessage(for: validationResult)
            showImagePicker = false
        }
    }
}

/// Simplified profile image picker for direct use
@available(iOS 26.0, *)
public struct SimpleProfileImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    public init(selectedImage: Binding<UIImage?>) {
        self._selectedImage = selectedImage
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
        let parent: SimpleProfileImagePicker
        
        init(_ parent: SimpleProfileImagePicker) {
            self.parent = parent
        }
        
        public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { object, _ in
                    guard let uiImage = object as? UIImage else { return }
                    Task { @MainActor in
                        self.parent.selectedImage = uiImage
                    }
                }
            }
        }
    }
}

#endif
