import Foundation

/// In-memory and disk caching manager
@MainActor
public final class CacheManager {
    public static let shared = CacheManager()
    
    private let memoryCache = NSCache<NSString, AnyObject>()
    private let diskCacheURL: URL
    
    private init() {
        // Set up disk cache directory
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        diskCacheURL = cacheDirectory.appendingPathComponent("AgoraCache")
        
        // Create cache directory if it doesn't exist
        try? FileManager.default.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
        
        // Configure memory cache
        memoryCache.countLimit = 100
        memoryCache.totalCostLimit = 50 * 1024 * 1024 // 50MB
    }
    
    // MARK: - Memory Cache
    
    /// Stores an object in memory cache
    public func setMemoryCache<T: AnyObject>(_ object: T, forKey key: String) {
        memoryCache.setObject(object, forKey: NSString(string: key))
    }
    
    /// Retrieves an object from memory cache
    public func getMemoryCache<T: AnyObject>(forKey key: String, type: T.Type) -> T? {
        return memoryCache.object(forKey: NSString(string: key)) as? T
    }
    
    /// Removes an object from memory cache
    public func removeMemoryCache(forKey key: String) {
        memoryCache.removeObject(forKey: NSString(string: key))
    }
    
    /// Clears all memory cache
    public func clearMemoryCache() {
        memoryCache.removeAllObjects()
    }
    
    // MARK: - Disk Cache
    
    /// Stores data to disk cache
    public func setDiskCache(_ data: Data, forKey key: String) async throws {
        let fileURL = diskCacheURL.appendingPathComponent(key.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? key)
        try data.write(to: fileURL)
    }
    
    /// Retrieves data from disk cache
    public func getDiskCache(forKey key: String) async throws -> Data? {
        let fileURL = diskCacheURL.appendingPathComponent(key.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? key)
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        return try Data(contentsOf: fileURL)
    }
    
    /// Removes data from disk cache
    public func removeDiskCache(forKey key: String) async throws {
        let fileURL = diskCacheURL.appendingPathComponent(key.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? key)
        try FileManager.default.removeItem(at: fileURL)
    }
    
    /// Clears all disk cache
    public func clearDiskCache() async throws {
        let contents = try FileManager.default.contentsOfDirectory(at: diskCacheURL, includingPropertiesForKeys: nil)
        for fileURL in contents {
            try FileManager.default.removeItem(at: fileURL)
        }
    }
    
    /// Gets the size of disk cache in bytes
    public func diskCacheSize() async throws -> Int64 {
        let contents = try FileManager.default.contentsOfDirectory(at: diskCacheURL, includingPropertiesForKeys: [.fileSizeKey])
        
        var totalSize: Int64 = 0
        for fileURL in contents {
            let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey])
            totalSize += Int64(resourceValues.fileSize ?? 0)
        }
        
        return totalSize
    }
}