import Foundation
#if canImport(SwiftData)
import SwiftData
#endif

/// SwiftData-based persistent storage manager
@available(iOS 26.0, macOS 14.0, *)
@MainActor
public final class SwiftDataStore: ObservableObject {
    public static let shared = SwiftDataStore()
    
    #if canImport(SwiftData)
    private var modelContainer: ModelContainer?
    #endif
    
    private init() {
        #if canImport(SwiftData)
        setupModelContainer()
        #endif
    }
    
    /// Sets up the SwiftData model container with core data models
    @available(iOS 26.0, macOS 14.0, *)
    private func setupModelContainer() {
        #if canImport(SwiftData)
        do {
            let schema = Schema([
                // Placeholder for future data models
                // UserModel.self,
                // PostModel.self,
                // DraftModel.self
            ])
            
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            print("Failed to create SwiftData model container: \(error)")
        }
        #endif
    }
    
    /// Returns the main context for SwiftData operations
    @available(iOS 26.0, macOS 14.0, *)
    public var mainContext: ModelContext? {
        #if canImport(SwiftData)
        return modelContainer?.mainContext
        #else
        return nil
        #endif
    }
    
    /// Creates a new background context for SwiftData operations
    @available(iOS 26.0, macOS 14.0, *)
    public func newBackgroundContext() -> ModelContext? {
        #if canImport(SwiftData)
        guard let modelContainer = modelContainer else { return nil }
        return ModelContext(modelContainer)
        #else
        return nil
        #endif
    }
    
    /// Saves changes in the given context
    @available(iOS 26.0, macOS 14.0, *)
    public func save(context: ModelContext) throws {
        #if canImport(SwiftData)
        try context.save()
        #endif
    }
}