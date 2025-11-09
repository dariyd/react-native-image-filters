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
    
    // MARK: - Crop Image
    
    @objc
    func cropImage(
        _ options: NSDictionary,
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        Task {
            do {
                let result = try await processCrop(options: options)
                resolve(result)
            } catch {
                reject("CROP_ERROR", error.localizedDescription, error)
            }
        }
    }
    
    // MARK: - Resize Image
    
    @objc
    func resizeImage(
        _ options: NSDictionary,
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        Task {
            do {
                let result = try await processResize(options: options)
                resolve(result)
            } catch {
                reject("RESIZE_ERROR", error.localizedDescription, error)
            }
        }
    }
    
    // MARK: - Rotate Image
    
    @objc
    func rotateImage(
        _ options: NSDictionary,
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        Task {
            do {
                let result = try await processRotate(options: options)
                resolve(result)
            } catch {
                reject("ROTATE_ERROR", error.localizedDescription, error)
            }
        }
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
    
    private func processCrop(options: NSDictionary) async throws -> [String: Any] {
        guard let sourceUri = options["sourceUri"] as? String else {
            throw NSError(domain: "ImageFilters", code: 1, userInfo: [NSLocalizedDescriptionKey: "sourceUri is required"])
        }
        
        guard let cropRectDict = options["cropRect"] as? NSDictionary,
              let x = cropRectDict["x"] as? CGFloat,
              let y = cropRectDict["y"] as? CGFloat,
              let width = cropRectDict["width"] as? CGFloat,
              let height = cropRectDict["height"] as? CGFloat else {
            throw NSError(domain: "ImageFilters", code: 2, userInfo: [NSLocalizedDescriptionKey: "cropRect is required"])
        }
        
        let returnFormat = options["returnFormat"] as? String ?? "uri"
        let quality = options["quality"] as? Float ?? 0.9
        
        // Load image
        let image = try await imageLoader.loadImage(from: sourceUri)
        guard let ciImage = CIImage(image: image) else {
            throw NSError(domain: "ImageFilters", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to create CIImage"])
        }
        
        // Apply crop using CICrop
        let cropRect = CGRect(x: x, y: y, width: width, height: height)
        guard let cropFilter = CIFilter(name: "CICrop") else {
            throw NSError(domain: "ImageFilters", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to create crop filter"])
        }
        
        cropFilter.setValue(ciImage, forKey: kCIInputImageKey)
        cropFilter.setValue(CIVector(cgRect: cropRect), forKey: "inputRectangle")
        
        guard let outputImage = cropFilter.outputImage else {
            throw NSError(domain: "ImageFilters", code: 5, userInfo: [NSLocalizedDescriptionKey: "Failed to crop image"])
        }
        
        // Convert to UIImage
        let context = CIContext()
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            throw NSError(domain: "ImageFilters", code: 6, userInfo: [NSLocalizedDescriptionKey: "Failed to convert to CGImage"])
        }
        let croppedImage = UIImage(cgImage: cgImage)
        
        // Prepare result
        var result: [String: Any] = [
            "width": Int(croppedImage.size.width),
            "height": Int(croppedImage.size.height)
        ]
        
        // Save to file if URI format requested
        if returnFormat == "uri" || returnFormat == "both" {
            let fileURL = try saveImageToTemp(croppedImage, quality: quality)
            result["uri"] = fileURL.absoluteString
        }
        
        // Convert to base64 if requested
        if returnFormat == "base64" || returnFormat == "both" {
            if let base64 = imageToBase64(croppedImage, quality: quality) {
                result["base64"] = base64
            }
        }
        
        return result
    }
    
    private func processResize(options: NSDictionary) async throws -> [String: Any] {
        guard let sourceUri = options["sourceUri"] as? String else {
            throw NSError(domain: "ImageFilters", code: 1, userInfo: [NSLocalizedDescriptionKey: "sourceUri is required"])
        }
        
        let returnFormat = options["returnFormat"] as? String ?? "uri"
        let quality = options["quality"] as? Float ?? 0.9
        let mode = options["mode"] as? String ?? "contain"
        
        // Load image
        let image = try await imageLoader.loadImage(from: sourceUri)
        guard let ciImage = CIImage(image: image) else {
            throw NSError(domain: "ImageFilters", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to create CIImage"])
        }
        
        // Calculate target size
        let currentSize = ciImage.extent.size
        var targetWidth: CGFloat
        var targetHeight: CGFloat
        
        if let width = options["width"] as? CGFloat {
            targetWidth = width
            if let height = options["height"] as? CGFloat {
                targetHeight = height
            } else {
                // Maintain aspect ratio
                targetHeight = currentSize.height * (width / currentSize.width)
            }
        } else if let height = options["height"] as? CGFloat {
            targetHeight = height
            targetWidth = currentSize.width * (height / currentSize.height)
        } else {
            throw NSError(domain: "ImageFilters", code: 3, userInfo: [NSLocalizedDescriptionKey: "width or height is required"])
        }
        
        // Apply resize mode
        let scale: CGFloat
        switch mode {
        case "cover":
            scale = max(targetWidth / currentSize.width, targetHeight / currentSize.height)
        case "stretch":
            // Use different scales for width and height (handled separately)
            scale = 1.0 // Will be overridden
        default: // "contain"
            scale = min(targetWidth / currentSize.width, targetHeight / currentSize.height)
        }
        
        // Use CILanczosScaleTransform for high quality
        guard let scaleFilter = CIFilter(name: "CILanczosScaleTransform") else {
            throw NSError(domain: "ImageFilters", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to create scale filter"])
        }
        
        scaleFilter.setValue(ciImage, forKey: kCIInputImageKey)
        
        if mode == "stretch" {
            // For stretch mode, scale non-uniformly
            let scaleX = targetWidth / currentSize.width
            let scaleY = targetHeight / currentSize.height
            scaleFilter.setValue(scaleX, forKey: kCIInputScaleKey)
            scaleFilter.setValue(1.0, forKey: kCIInputAspectRatioKey)
            
            // Apply first scale
            guard let intermediateImage = scaleFilter.outputImage else {
                throw NSError(domain: "ImageFilters", code: 5, userInfo: [NSLocalizedDescriptionKey: "Failed to resize image"])
            }
            
            // Apply second scale for height
            guard let scaleFilter2 = CIFilter(name: "CILanczosScaleTransform") else {
                throw NSError(domain: "ImageFilters", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to create scale filter"])
            }
            scaleFilter2.setValue(intermediateImage, forKey: kCIInputImageKey)
            scaleFilter2.setValue(scaleY, forKey: kCIInputScaleKey)
            scaleFilter2.setValue(1.0, forKey: kCIInputAspectRatioKey)
            
            guard let outputImage = scaleFilter2.outputImage else {
                throw NSError(domain: "ImageFilters", code: 5, userInfo: [NSLocalizedDescriptionKey: "Failed to resize image"])
            }
            
            // Convert to UIImage
            let context = CIContext()
            guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
                throw NSError(domain: "ImageFilters", code: 6, userInfo: [NSLocalizedDescriptionKey: "Failed to convert to CGImage"])
            }
            let resizedImage = UIImage(cgImage: cgImage)
            
            return try prepareImageResult(resizedImage, returnFormat: returnFormat, quality: quality)
        } else {
            scaleFilter.setValue(scale, forKey: kCIInputScaleKey)
            scaleFilter.setValue(1.0, forKey: kCIInputAspectRatioKey)
            
            guard let outputImage = scaleFilter.outputImage else {
                throw NSError(domain: "ImageFilters", code: 5, userInfo: [NSLocalizedDescriptionKey: "Failed to resize image"])
            }
            
            // Convert to UIImage
            let context = CIContext()
            guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
                throw NSError(domain: "ImageFilters", code: 6, userInfo: [NSLocalizedDescriptionKey: "Failed to convert to CGImage"])
            }
            let resizedImage = UIImage(cgImage: cgImage)
            
            return try prepareImageResult(resizedImage, returnFormat: returnFormat, quality: quality)
        }
    }
    
    private func processRotate(options: NSDictionary) async throws -> [String: Any] {
        guard let sourceUri = options["sourceUri"] as? String else {
            throw NSError(domain: "ImageFilters", code: 1, userInfo: [NSLocalizedDescriptionKey: "sourceUri is required"])
        }
        
        guard let degrees = options["degrees"] as? CGFloat else {
            throw NSError(domain: "ImageFilters", code: 2, userInfo: [NSLocalizedDescriptionKey: "degrees is required"])
        }
        
        let returnFormat = options["returnFormat"] as? String ?? "uri"
        let quality = options["quality"] as? Float ?? 0.9
        let expand = options["expand"] as? Bool ?? true
        
        // Load image
        let image = try await imageLoader.loadImage(from: sourceUri)
        guard let ciImage = CIImage(image: image) else {
            throw NSError(domain: "ImageFilters", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to create CIImage"])
        }
        
        // Convert degrees to radians
        let radians = degrees * .pi / 180.0
        
        // Create affine transform for rotation
        let transform = CGAffineTransform(rotationAngle: radians)
        
        // Apply transform
        var rotatedImage = ciImage.transformed(by: transform)
        
        // If expand is true, adjust the origin to prevent clipping
        if expand {
            let originalExtent = ciImage.extent
            let rotatedExtent = rotatedImage.extent
            
            // Center the rotated image
            let translateX = (rotatedExtent.width - originalExtent.width) / 2 + rotatedExtent.origin.x
            let translateY = (rotatedExtent.height - originalExtent.height) / 2 + rotatedExtent.origin.y
            
            rotatedImage = rotatedImage.transformed(by: CGAffineTransform(translationX: -translateX, y: -translateY))
        }
        
        // Convert to UIImage
        let context = CIContext()
        guard let cgImage = context.createCGImage(rotatedImage, from: rotatedImage.extent) else {
            throw NSError(domain: "ImageFilters", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to convert to CGImage"])
        }
        let finalImage = UIImage(cgImage: cgImage)
        
        return try prepareImageResult(finalImage, returnFormat: returnFormat, quality: quality)
    }
    
    private func prepareImageResult(_ image: UIImage, returnFormat: String, quality: Float) throws -> [String: Any] {
        var result: [String: Any] = [
            "width": Int(image.size.width),
            "height": Int(image.size.height)
        ]
        
        // Save to file if URI format requested
        if returnFormat == "uri" || returnFormat == "both" {
            let fileURL = try saveImageToTemp(image, quality: quality)
            result["uri"] = fileURL.absoluteString
        }
        
        // Convert to base64 if requested
        if returnFormat == "base64" || returnFormat == "both" {
            if let base64 = imageToBase64(image, quality: quality) {
                result["base64"] = base64
            }
        }
        
        return result
    }
    
    // MARK: - React Native Module Configuration
    
    @objc
    static func requiresMainQueueSetup() -> Bool {
        return false
    }
}

