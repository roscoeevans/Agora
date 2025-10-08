import Foundation
import DeviceCheck

/// App Attest manager for device attestation
public final class AppAttestManager: Sendable {
    public static let shared = AppAttestManager()
    
    private init() {}
    
    /// Checks if App Attest is supported on this device
    public var isSupported: Bool {
        if #available(iOS 26.0, *) {
            return DCAppAttestService.shared.isSupported
        }
        return false
    }
    
    /// Generates and stores an attestation key
    public func generateKey() async throws -> String {
        guard isSupported else {
            throw AttestationError.notSupported
        }
        
        if #available(iOS 26.0, *) {
            return try await DCAppAttestService.shared.generateKey()
        } else {
            throw AttestationError.notSupported
        }
    }
    
    /// Attests the key with challenge data
    public func attestKey(_ keyId: String, clientDataHash: Data) async throws -> Data {
        guard isSupported else {
            throw AttestationError.notSupported
        }
        
        if #available(iOS 26.0, *) {
            return try await DCAppAttestService.shared.attestKey(keyId, clientDataHash: clientDataHash)
        } else {
            throw AttestationError.notSupported
        }
    }
    
    /// Generates an assertion for the given request
    public func generateAssertion(_ keyId: String, clientDataHash: Data) async throws -> Data {
        guard isSupported else {
            throw AttestationError.notSupported
        }
        
        if #available(iOS 26.0, *) {
            return try await DCAppAttestService.shared.generateAssertion(keyId, clientDataHash: clientDataHash)
        } else {
            throw AttestationError.notSupported
        }
    }
    
    /// Performs full attestation flow
    public func performAttestation(challenge: String) async throws -> AttestationResult {
        // Generate key
        let keyId = try await generateKey()
        
        // Create client data hash
        let clientData = AttestationClientData(
            challenge: challenge,
            timestamp: Date(),
            bundleId: Bundle.main.bundleIdentifier ?? ""
        )
        
        let clientDataHash = try clientData.hash()
        
        // Attest key
        let attestationObject = try await attestKey(keyId, clientDataHash: clientDataHash)
        
        return AttestationResult(
            keyId: keyId,
            attestationObject: attestationObject,
            clientData: clientData
        )
    }
    
    /// Generates assertion for authenticated requests
    public func generateAuthenticatedAssertion(keyId: String, requestData: Data) async throws -> Data {
        let clientDataHash = SHA256.hash(data: requestData)
        return try await generateAssertion(keyId, clientDataHash: Data(clientDataHash))
    }
}

/// Attestation errors
public enum AttestationError: LocalizedError {
    case notSupported
    case keyGenerationFailed
    case attestationFailed
    case assertionFailed
    case invalidChallenge
    
    public var errorDescription: String? {
        switch self {
        case .notSupported:
            return "App Attest is not supported on this device"
        case .keyGenerationFailed:
            return "Failed to generate attestation key"
        case .attestationFailed:
            return "Failed to attest key"
        case .assertionFailed:
            return "Failed to generate assertion"
        case .invalidChallenge:
            return "Invalid attestation challenge"
        }
    }
}

/// Attestation result
public struct AttestationResult {
    public let keyId: String
    public let attestationObject: Data
    public let clientData: AttestationClientData
    
    public init(keyId: String, attestationObject: Data, clientData: AttestationClientData) {
        self.keyId = keyId
        self.attestationObject = attestationObject
        self.clientData = clientData
    }
}

/// Client data for attestation
public struct AttestationClientData: Codable {
    public let challenge: String
    public let timestamp: Date
    public let bundleId: String
    
    public init(challenge: String, timestamp: Date, bundleId: String) {
        self.challenge = challenge
        self.timestamp = timestamp
        self.bundleId = bundleId
    }
    
    /// Generates SHA256 hash of the client data
    public func hash() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(self)
        return Data(SHA256.hash(data: data))
    }
}

// MARK: - SHA256 Helper

import CryptoKit

private extension SHA256 {
    static func hash(data: Data) -> SHA256Digest {
        return SHA256.hash(data: data)
    }
}