// MARK: - Public API Re-exports

// All public types are already defined in their respective files
// This file provides convenience extensions and setup helpers

import SwiftUI

// MARK: - Accessibility Exports

@available(iOS 26.0, *)
public typealias ToastAccessibilityHelper = ToastAccessibility

// MARK: - Service Factory Re-export

public typealias ToastFactory = ToastServiceFactory

// MARK: - Convenience Extensions

public extension View {
    /// Configure the view hierarchy with toast services (legacy method)
    func toastServices(
        manager: ToastManager,
        sceneManager: ToastSceneManager = ToastSceneManager(),
        policy: ToastPolicy = .default,
        performanceManager: ToastPerformanceManager = .shared
    ) -> some View {
        self
            .toastProvider(manager)
            .toastSceneManager(sceneManager)
            .toastPolicy(policy)
            .environment(\.toastPerformanceManager, performanceManager)
            .onAppear {
                manager.setSceneManager(sceneManager)
            }
    }
}

// MARK: - Usage Examples

/*
 
 ## Basic Usage
 
 ```swift
 // In your app's root view:
 ContentView()
     .configureToastSystem() // Uses environment-appropriate defaults
 
 // Or with custom policy:
 ContentView()
     .configureToastSystem(policy: .conservative)
 ```
 
 ## Showing Toasts
 
 ```swift
 struct MyView: View {
     @Environment(\.toasts) private var toasts
     
     var body: some View {
         Button("Show Success") {
             Task {
                 await toasts.success("Operation completed!")
             }
         }
         
         Button("Show Error") {
             Task {
                 await toasts.error("Something went wrong", action: .retry {
                     // Handle retry
                 })
             }
         }
     }
 }
 ```
 
 ## Dependency Injection
 
 ```swift
 // Create toast system
 let toastSystem = ToastServiceFactory.createToastSystem()
 
 // Configure your app
 MyApp()
     .configureToastSystem(
         manager: toastSystem.manager,
         sceneManager: toastSystem.sceneManager,
         policy: toastSystem.policy
     )
 ```
 
 */