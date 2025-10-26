//
//  ProfileImagePicker.swift
//  UIKitBridge
//
//  Created by Agora Team on 2024.
//

import SwiftUI
import PhotosUI

#if canImport(UIKit)
import UIKit
#endif

/// SwiftUI wrapper for profile image selection with native cropping
@available(iOS 26.0, *)
public struct ProfileImagePicker: View {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    @State private var pickerItem: PhotosPickerItem?
    @State private var tempImage: UIImage?
    @State private var showCropper = false
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
        .sheet(isPresented: $showCropper) {
            if let image = tempImage {
                SimpleImageCropper(
                    image: image,
                    onCrop: { croppedImage in
                        handleCroppedImage(croppedImage)
                    },
                    onCancel: {
                        showCropper = false
                    }
                )
            }
        }
        .photosPicker(
            isPresented: .constant(true),
            selection: $pickerItem,
            matching: .images
        )
        .onChange(of: pickerItem) { _, newItem in
            Task {
                await handlePhotoSelection(newItem)
            }
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
    
    @MainActor
    private func handlePhotoSelection(_ item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        print("📸 [ProfileImagePicker] Photo selected")
        
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                print("📸 [ProfileImagePicker] Image loaded, size: \(uiImage.size.width)x\(uiImage.size.height)")
                
                // Validate image
                let validationResult = ImageProcessingBridge.validateProfileImage(uiImage)
                print("📸 [ProfileImagePicker] Validation result: \(validationResult)")
                
                switch validationResult {
                case .valid:
                    print("📸 [ProfileImagePicker] Image validation passed, showing cropper")
                    tempImage = uiImage
                    showCropper = true
                    validationError = nil
                default:
                    let errorMessage = ImageProcessingBridge.errorMessage(for: validationResult)
                    print("❌ [ProfileImagePicker] Image validation failed: \(errorMessage)")
                    validationError = errorMessage
                }
            } else {
                throw AvatarError.invalidImageData
            }
        } catch {
            print("❌ [ProfileImagePicker] Photo selection failed: \(error)")
            validationError = "Failed to load image. Please try another photo."
        }
    }
    
    @MainActor
    private func handleCroppedImage(_ croppedImage: UIImage?) {
        guard let croppedImage = croppedImage else {
            print("❌ [ProfileImagePicker] Cropping failed")
            validationError = "Failed to crop image. Please try again."
            return
        }
        
        print("✅ [ProfileImagePicker] Image cropped successfully, size: \(croppedImage.size.width)x\(croppedImage.size.height)")
        
        // Validate cropped image
        let validationResult = ImageProcessingBridge.validateProfileImage(croppedImage)
        print("📸 [ProfileImagePicker] Cropped image validation: \(validationResult)")
        
        switch validationResult {
        case .valid:
            selectedImage = croppedImage
            dismiss()
            validationError = nil
        default:
            let errorMessage = ImageProcessingBridge.errorMessage(for: validationResult)
            print("❌ [ProfileImagePicker] Cropped image validation failed: \(errorMessage)")
            validationError = errorMessage
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