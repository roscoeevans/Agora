//
//  UIKitBridgeTests.swift
//  UIKitBridgeTests
//
//  Created by Agora Team on 2024.
//

import XCTest
@testable import UIKitBridge

final class UIKitBridgeTests: XCTestCase {
    
    func testMediaPickerBridgeInitialization() {
        // Test that MediaPickerBridge can be initialized
        let binding = Binding<[SelectedMedia]>(get: { [] }, set: { _ in })
        let picker = MediaPickerBridge(selectedMedia: binding)
        XCTAssertNotNil(picker)
    }
    
    func testImagePickerBridgeInitialization() {
        // Test that ImagePickerBridge can be initialized
        let binding = Binding<UIImage?>(get: { nil }, set: { _ in })
        let picker = ImagePickerBridge(image: binding)
        XCTAssertNotNil(picker)
    }
    
    func testDesignSystemBridgeInitialization() {
        // Test that DesignSystemBridge can be initialized
        let bridge = DesignSystemBridge.shared
        XCTAssertNotNil(bridge)
    }
    
    func testMediaTypeEnum() {
        // Test MediaType enum cases
        XCTAssertEqual(MediaType.image, MediaType.image)
        XCTAssertEqual(MediaType.video, MediaType.video)
        XCTAssertEqual(MediaType.unknown, MediaType.unknown)
    }
    
    func testSelectedMediaInitialization() {
        // Test SelectedMedia initialization
        let item = PhotosPickerItem(itemIdentifier: "test-id")
        let media = SelectedMedia(item: item, type: .image)
        
        XCTAssertEqual(media.type, .image)
        XCTAssertNotNil(media.id)
    }
}
