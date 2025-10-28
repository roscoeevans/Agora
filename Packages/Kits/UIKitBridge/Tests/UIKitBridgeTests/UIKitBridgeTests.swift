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
    
    func testAuthBridgeInitialization() {
        // Test that AuthBridge can be initialized
        let bridge = AuthBridge.shared
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
    
    // Note: Testing window retrieval requires a running app with UI scene
    // These are integration-level tests that would run in UITest target
    // func testAuthBridgePresentationAnchor() {
    //     // This test would require a running app with UI scene
    //     // Should be tested in integration tests or UITests
    //     // do {
    //     //     let anchor = try AuthBridge.getPresentationAnchor()
    //     //     XCTAssertNotNil(anchor)
    //     // } catch {
    //     //     XCTFail("Failed to get presentation anchor: \(error)")
    //     // }
    // }
}
