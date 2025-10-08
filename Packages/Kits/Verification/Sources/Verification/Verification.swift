import Foundation

/// Main module for device attestation and phone verification functionality
public struct Verification: Sendable {
    public nonisolated static let shared = Verification()
    
    private init() {}
}