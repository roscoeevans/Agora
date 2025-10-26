//
//  AvatarPickerView.swift
//  UIKitBridge
//
//  Created by Agora Team on 2024.
//

import SwiftUI
import PhotosUI

/// Apple-style avatar picker with native SwiftUI cropping
/// This component handles photo selection and cropping only.
/// Upload logic should be handled by the consumer.
@available(iOS 26.0, *)
public struct AvatarPickerView: View {
    @Binding var croppedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    @State private var pickerItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var showCropper = false
    @State private var errorMessage: String?
    
    public init(croppedImage: Binding<UIImage?>) {
        self._croppedImage = croppedImage
    }
    
    public var body: some View {
        VStack(spacing: 24) {
            // Photo picker button
            PhotosPicker("Choose Photo", selection: $pickerItem, matching: .images)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .onChange(of: pickerItem) { _, newItem in
                    Task {
                        await handlePhotoSelection(newItem)
                    }
                }
            
            // Error message
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .fullScreenCover(isPresented: $showCropper) {
            if let selectedImage = selectedImage {
                SimpleImageCropper(
                    image: selectedImage,
                    onCrop: { cropped in
                        croppedImage = cropped
                        dismiss()
                    },
                    onCancel: {
                        showCropper = false
                        dismiss()
                    }
                )
            }
        }
    }
    
    @MainActor
    private func handlePhotoSelection(_ item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                print("📸 [AvatarPicker] Photo selected, size: \(uiImage.size.width)x\(uiImage.size.height)")
                selectedImage = uiImage
                showCropper = true
                errorMessage = nil
            } else {
                throw AvatarError.invalidImageData
            }
        } catch {
            print("❌ [AvatarPicker] Photo selection failed: \(error)")
            errorMessage = "Failed to load image. Please try another photo."
        }
    }
}

/// Avatar upload errors
public enum AvatarError: Error, LocalizedError {
    case invalidImageData
    
    public var errorDescription: String? {
        switch self {
        case .invalidImageData:
            return "Invalid image data"
        }
    }
}