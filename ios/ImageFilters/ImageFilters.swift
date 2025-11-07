import Foundation
import UIKit
import React

@available(iOS 18.0, *)
@objc(ImageFilters)
class ImageFilters: NSObject {
    
    private let filterEngine = MetalFilterEngine.shared
    private let imageLoader = ImageLoader.shared
    private let filterRegistry = FilterRegistry.shared
    
    // MARK: - Apply Single Filter
    
    @objc
    func applyFilter(
        _ options: NSDictionary,
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        Task {
            do {
                let result = try await processFilter(options: options)
                resolve(result)
            } catch {
                reject("FILTER_ERROR", error.localizedDescription, error)
            }
        }
    }
    
    // MARK: - Apply Multiple Filters
    
    @objc
    func applyFilters(
        _ optionsArray: NSArray,
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        Task {
            do {
                var results: [[String: Any]] = []
                
                for options in optionsArray {
                    if let optionsDict = options as? NSDictionary {
                        let result = try await processFilter(options: optionsDict)
                        results.append(result)
                    }
                }
                
                resolve(results)
            } catch {
                reject("FILTER_ERROR", error.localizedDescription, error)
            }
        }
    }
    
    // MARK: - Get Available Filters
    
    @objc
    func getAvailableFilters(
        _ type: String?,
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        let filters = filterRegistry.getFilters(type: type)
        resolve(filters)
    }
    
    // MARK: - Preload Image
    
    @objc
    func preloadImage(
        _ uri: String,
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        Task {
            do {
                try await imageLoader.preloadImage(from: uri)
                resolve(nil)
            } catch {
                reject("PRELOAD_ERROR", error.localizedDescription, error)
            }
        }
    }
    
    // MARK: - Clear Cache
    
    @objc
    func clearCache(
        _ resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        imageLoader.clearCache()
        filterEngine.clearCache()
        resolve(nil)
    }
    
    // MARK: - Helper Methods
    
    private func processFilter(options: NSDictionary) async throws -> [String: Any] {
        guard let sourceUri = options["sourceUri"] as? String else {
            throw NSError(domain: "ImageFilters", code: 1, userInfo: [NSLocalizedDescriptionKey: "sourceUri is required"])
        }
        
        guard let filterName = options["filter"] as? String else {
            throw NSError(domain: "ImageFilters", code: 2, userInfo: [NSLocalizedDescriptionKey: "filter is required"])
        }
        
        let intensity = options["intensity"] as? Float ?? 1.0
        let customParams = options["customParams"] as? [String: Any] ?? [:]
        let returnFormat = options["returnFormat"] as? String ?? "uri"
        let quality = options["quality"] as? Float ?? 0.9
        
        // Load image
        let image = try await imageLoader.loadImage(from: sourceUri)
        
        // Create filter parameters
        var parameters = FilterParameters()
        parameters.intensity = intensity
        parameters.customParams = customParams
        
        // Apply filter
        let filteredImage = try await filterEngine.applyFilter(
            to: image,
            filterName: filterName,
            parameters: parameters
        )
        
        // Prepare result
        var result: [String: Any] = [
            "width": Int(filteredImage.size.width),
            "height": Int(filteredImage.size.height)
        ]
        
        // Save to file if URI format requested
        if returnFormat == "uri" || returnFormat == "both" {
            let fileURL = try saveImageToTemp(filteredImage, quality: quality)
            result["uri"] = fileURL.absoluteString
        }
        
        // Convert to base64 if requested
        if returnFormat == "base64" || returnFormat == "both" {
            if let base64 = imageToBase64(filteredImage, quality: quality) {
                result["base64"] = base64
            }
        }
        
        return result
    }
    
    private func saveImageToTemp(_ image: UIImage, quality: Float) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "filtered_\(UUID().uuidString).jpg"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        guard let data = image.jpegData(compressionQuality: CGFloat(quality)),
              FileManager.default.createFile(atPath: fileURL.path, contents: data, attributes: nil) else {
            throw NSError(domain: "ImageFilters", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to save image"])
        }
        
        return fileURL
    }
    
    private func imageToBase64(_ image: UIImage, quality: Float) -> String? {
        guard let data = image.jpegData(compressionQuality: CGFloat(quality)) else {
            return nil
        }
        return data.base64EncodedString()
    }
    
    // MARK: - React Native Module Configuration
    
    @objc
    static func requiresMainQueueSetup() -> Bool {
        return false
    }
}

