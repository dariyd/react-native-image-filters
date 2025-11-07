import UIKit
import Foundation

/// Image loader that supports local and remote URIs with caching
@available(iOS 18.0, *)
class ImageLoader {
    
    // MARK: - Properties
    
    static let shared = ImageLoader()
    
    /// In-memory cache for loaded images
    private let cache = NSCache<NSString, UIImage>()
    
    /// URL session for remote image loading
    private let urlSession: URLSession
    
    /// Cache size limit (50MB)
    private let maxCacheSize = 50 * 1024 * 1024
    
    // MARK: - Initialization
    
    private init() {
        cache.totalCostLimit = maxCacheSize
        cache.countLimit = 100
        
        // Configure URL session with caching
        let config = URLSessionConfiguration.default
        config.urlCache = URLCache(
            memoryCapacity: maxCacheSize,
            diskCapacity: 200 * 1024 * 1024, // 200MB disk cache
            diskPath: "com.imagefilters.cache"
        )
        config.requestCachePolicy = .returnCacheDataElseLoad
        urlSession = URLSession(configuration: config)
    }
    
    // MARK: - Public Methods
    
    /// Load image from URI
    /// - Parameter uri: Image URI (file://, https://, or asset://)
    /// - Returns: Loaded UIImage
    func loadImage(from uri: String) async throws -> UIImage {
        let cacheKey = NSString(string: uri)
        
        // Check cache first
        if let cachedImage = cache.object(forKey: cacheKey) {
            return cachedImage
        }
        
        let image: UIImage
        
        if uri.hasPrefix("http://") || uri.hasPrefix("https://") {
            // Remote image
            image = try await loadRemoteImage(from: uri)
        } else if uri.hasPrefix("file://") {
            // Local file
            image = try loadLocalImage(from: uri)
        } else if uri.hasPrefix("data:") {
            // Data URI
            image = try loadDataURI(from: uri)
        } else {
            // Assume local file without file:// prefix
            let fileURL = URL(fileURLWithPath: uri)
            guard let loadedImage = UIImage(contentsOfFile: fileURL.path) else {
                throw ImageLoaderError.loadFailed("Failed to load image from: \(uri)")
            }
            image = loadedImage
        }
        
        // Cache the loaded image
        cache.setObject(image, forKey: cacheKey, cost: imageCost(image))
        
        return image
    }
    
    /// Preload image into cache
    /// - Parameter uri: Image URI to preload
    func preloadImage(from uri: String) async throws {
        _ = try await loadImage(from: uri)
    }
    
    /// Clear the image cache
    func clearCache() {
        cache.removeAllObjects()
        urlSession.configuration.urlCache?.removeAllCachedResponses()
    }
    
    /// Remove specific image from cache
    /// - Parameter uri: Image URI to remove
    func removeFromCache(uri: String) {
        let cacheKey = NSString(string: uri)
        cache.removeObject(forKey: cacheKey)
    }
    
    // MARK: - Private Methods
    
    private func loadRemoteImage(from uri: String) async throws -> UIImage {
        guard let url = URL(string: uri) else {
            throw ImageLoaderError.invalidURL(uri)
        }
        
        let (data, response) = try await urlSession.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw ImageLoaderError.networkError("Invalid response")
        }
        
        guard let image = UIImage(data: data) else {
            throw ImageLoaderError.loadFailed("Failed to decode image from: \(uri)")
        }
        
        return image
    }
    
    private func loadLocalImage(from uri: String) throws -> UIImage {
        let fileURL: URL
        if let url = URL(string: uri), url.scheme == "file" {
            fileURL = url
        } else {
            fileURL = URL(fileURLWithPath: uri)
        }
        
        guard let image = UIImage(contentsOfFile: fileURL.path) else {
            throw ImageLoaderError.loadFailed("Failed to load local image from: \(uri)")
        }
        
        return image
    }
    
    private func loadDataURI(from uri: String) throws -> UIImage {
        // Parse data URI (e.g., data:image/png;base64,...)
        guard let commaRange = uri.range(of: ","),
              let dataString = String(uri[commaRange.upperBound...]).removingPercentEncoding,
              let data = Data(base64Encoded: dataString),
              let image = UIImage(data: data) else {
            throw ImageLoaderError.loadFailed("Failed to decode data URI")
        }
        
        return image
    }
    
    private func imageCost(_ image: UIImage) -> Int {
        guard let cgImage = image.cgImage else { return 0 }
        return cgImage.bytesPerRow * cgImage.height
    }
}

// MARK: - Error Types

enum ImageLoaderError: LocalizedError {
    case invalidURL(String)
    case networkError(String)
    case loadFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL(let uri):
            return "Invalid URL: \(uri)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .loadFailed(let message):
            return "Load failed: \(message)"
        }
    }
}

