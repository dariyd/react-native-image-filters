import UIKit
import Metal
import MetalKit
import CoreImage
import Accelerate

/// Metal-based filter engine for GPU-accelerated image processing
@available(iOS 18.0, *)
class MetalFilterEngine {
    
    // MARK: - Properties
    
    static let shared = MetalFilterEngine()
    
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let textureLoader: MTKTextureLoader
    private let ciContext: CIContext
    
    /// Compiled shader library
    private var library: MTLLibrary?
    
    /// Cache for compute pipeline states
    private var pipelineCache: [String: MTLComputePipelineState] = [:]
    
    /// Texture cache for performance
    private var textureCache: [String: MTLTexture] = [:]
    private let cacheQueue = DispatchQueue(label: "com.imagefilters.texturecache")
    
    // MARK: - Initialization
    
    private init() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported on this device")
        }
        
        self.device = device
        
        guard let commandQueue = device.makeCommandQueue() else {
            fatalError("Failed to create Metal command queue")
        }
        
        self.commandQueue = commandQueue
        self.textureLoader = MTKTextureLoader(device: device)
        self.ciContext = CIContext(mtlDevice: device)
        
        // Load default shader library
        self.library = device.makeDefaultLibrary()
    }
    
    // MARK: - Public Methods
    
    /// Apply filter to image
    func applyFilter(
        to image: UIImage,
        filterName: String,
        parameters: FilterParameters
    ) async throws -> UIImage {
        
        let category = FilterRegistry.shared.getCategory(for: filterName)
        
        switch category {
        case .document:
            return try await applyDocumentFilter(to: image, filterName: filterName, parameters: parameters)
        case .photo:
            return try await applyPhotoFilter(to: image, filterName: filterName, parameters: parameters)
        case .custom:
            return try await applyCustomFilter(to: image, parameters: parameters)
        case .unknown:
            throw FilterError.invalidFilter(filterName)
        }
    }
    
    /// Clear texture cache
    func clearCache() {
        cacheQueue.sync {
            textureCache.removeAll()
        }
    }
    
    // MARK: - Document Filters
    
    private func applyDocumentFilter(
        to image: UIImage,
        filterName: String,
        parameters: FilterParameters
    ) async throws -> UIImage {
        
        switch filterName {
        case "scan":
            return try await applyScanFilter(to: image, parameters: parameters)
        case "blackWhite":
            return try await applyBlackWhiteFilter(to: image, parameters: parameters)
        case "enhance":
            return try await applyEnhanceFilter(to: image, parameters: parameters)
        case "perspective":
            return try await applyPerspectiveFilter(to: image, parameters: parameters)
        case "grayscale":
            return try await applyGrayscaleFilter(to: image, parameters: parameters)
        case "colorPop":
            return try await applyColorPopFilter(to: image, parameters: parameters)
        default:
            throw FilterError.invalidFilter(filterName)
        }
    }
    
    private func applyScanFilter(to image: UIImage, parameters: FilterParameters) async throws -> UIImage {
        // Use Core Image for scan filter (fallback from Metal shaders)
        guard let inputImage = CIImage(image: image) else {
            throw FilterError.imageConversionFailed
        }
        
        let threshold = parameters.getFloat("threshold", defaultValue: 0.5)
        let contrast = parameters.getFloat("contrast", defaultValue: 1.2)
        let sharpness = parameters.getFloat("sharpness", defaultValue: 1.1)
        let intensity = parameters.intensity
        
        var outputImage = inputImage
        
        // Convert to grayscale first
        if let grayscaleFilter = CIFilter(name: "CIColorControls") {
            grayscaleFilter.setValue(outputImage, forKey: kCIInputImageKey)
            grayscaleFilter.setValue(0.0, forKey: kCIInputSaturationKey)
            if let result = grayscaleFilter.outputImage {
                outputImage = result
            }
        }
        
        // Apply contrast
        if let contrastFilter = CIFilter(name: "CIColorControls") {
            contrastFilter.setValue(outputImage, forKey: kCIInputImageKey)
            contrastFilter.setValue(contrast, forKey: kCIInputContrastKey)
            if let result = contrastFilter.outputImage {
                outputImage = result
            }
        }
        
        // Apply sharpening
        if sharpness > 1.0, let sharpenFilter = CIFilter(name: "CISharpenLuminance") {
            sharpenFilter.setValue(outputImage, forKey: kCIInputImageKey)
            sharpenFilter.setValue((sharpness - 1.0) * 2.0, forKey: kCIInputSharpnessKey)
            if let result = sharpenFilter.outputImage {
                outputImage = result
            }
        }
        
        // Mix with original based on intensity
        if intensity < 1.0 {
            outputImage = inputImage.applyingFilter("CIBlendWithAlphaMask", parameters: [
                kCIInputBackgroundImageKey: outputImage,
                "inputMaskImage": CIImage(color: CIColor(red: CGFloat(intensity), green: CGFloat(intensity), blue: CGFloat(intensity))).cropped(to: inputImage.extent)
            ])
        }
        
        return try renderCIImage(outputImage, size: image.size)
    }
    
    private func applyBlackWhiteFilter(to image: UIImage, parameters: FilterParameters) async throws -> UIImage {
        // Use Core Image for black & white conversion with custom threshold
        guard let inputImage = CIImage(image: image) else {
            throw FilterError.imageConversionFailed
        }
        
        let threshold = parameters.getFloat("threshold", defaultValue: 0.6)
        let noiseReduction = parameters.getFloat("noiseReduction", defaultValue: 0.3)
        
        // Apply noir effect with threshold
        var outputImage = inputImage
        
        // Desaturate
        if let monoFilter = CIFilter(name: "CIPhotoEffectMono") {
            monoFilter.setValue(outputImage, forKey: kCIInputImageKey)
            if let result = monoFilter.outputImage {
                outputImage = result
            }
        }
        
        // Apply contrast
        if let contrastFilter = CIFilter(name: "CIColorControls") {
            contrastFilter.setValue(outputImage, forKey: kCIInputImageKey)
            contrastFilter.setValue(1.0 + (threshold * 0.8), forKey: kCIInputContrastKey)
            if let result = contrastFilter.outputImage {
                outputImage = result
            }
        }
        
        // Noise reduction
        if noiseReduction > 0, let noiseFilter = CIFilter(name: "CINoiseReduction") {
            noiseFilter.setValue(outputImage, forKey: kCIInputImageKey)
            noiseFilter.setValue(noiseReduction, forKey: "inputNoiseLevel")
            if let result = noiseFilter.outputImage {
                outputImage = result
            }
        }
        
        // Mix with original based on intensity
        let intensity = parameters.intensity
        if intensity < 1.0 {
            outputImage = inputImage.applyingFilter("CIBlendWithAlphaMask", parameters: [
                kCIInputBackgroundImageKey: outputImage,
                "inputMaskImage": CIImage(color: CIColor(red: CGFloat(intensity), green: CGFloat(intensity), blue: CGFloat(intensity))).cropped(to: inputImage.extent)
            ])
        }
        
        return try renderCIImage(outputImage, size: image.size)
    }
    
    private func applyEnhanceFilter(to image: UIImage, parameters: FilterParameters) async throws -> UIImage {
        guard let inputImage = CIImage(image: image) else {
            throw FilterError.imageConversionFailed
        }
        
        let brightness = parameters.getFloat("brightness", defaultValue: 1.1)
        let contrast = parameters.getFloat("contrast", defaultValue: 1.15)
        let saturation = parameters.getFloat("saturation", defaultValue: 1.05)
        let sharpness = parameters.getFloat("sharpness", defaultValue: 1.1)
        
        var outputImage = inputImage
        
        // Apply color controls
        // Note: CIColorControls brightness is in range -1 to 1, where 0 is no change
        if let colorFilter = CIFilter(name: "CIColorControls") {
            colorFilter.setValue(outputImage, forKey: kCIInputImageKey)
            colorFilter.setValue((brightness - 1.0) * 0.5, forKey: kCIInputBrightnessKey) // Convert 1.1 -> 0.05
            colorFilter.setValue(contrast, forKey: kCIInputContrastKey)
            colorFilter.setValue(saturation, forKey: kCIInputSaturationKey)
            if let result = colorFilter.outputImage {
                outputImage = result
            }
        }
        
        // Apply sharpening
        if sharpness > 1.0, let sharpenFilter = CIFilter(name: "CISharpenLuminance") {
            sharpenFilter.setValue(outputImage, forKey: kCIInputImageKey)
            sharpenFilter.setValue((sharpness - 1.0) * 2.0, forKey: kCIInputSharpnessKey)
            if let result = sharpenFilter.outputImage {
                outputImage = result
            }
        }
        
        return try renderCIImage(outputImage, size: image.size)
    }
    
    private func applyPerspectiveFilter(to image: UIImage, parameters: FilterParameters) async throws -> UIImage {
        guard let inputImage = CIImage(image: image) else {
            throw FilterError.imageConversionFailed
        }
        
        // Auto-detect corners or use provided coordinates
        // For now, apply simple perspective correction
        guard let perspectiveFilter = CIFilter(name: "CIPerspectiveCorrection") else {
            return image
        }
        
        let size = image.size
        perspectiveFilter.setValue(inputImage, forKey: kCIInputImageKey)
        perspectiveFilter.setValue(CIVector(x: 0, y: 0), forKey: "inputTopLeft")
        perspectiveFilter.setValue(CIVector(x: size.width, y: 0), forKey: "inputTopRight")
        perspectiveFilter.setValue(CIVector(x: size.width, y: size.height), forKey: "inputBottomRight")
        perspectiveFilter.setValue(CIVector(x: 0, y: size.height), forKey: "inputBottomLeft")
        
        guard let outputImage = perspectiveFilter.outputImage else {
            return image
        }
        
        return try renderCIImage(outputImage, size: size)
    }
    
    private func applyGrayscaleFilter(to image: UIImage, parameters: FilterParameters) async throws -> UIImage {
        guard let inputImage = CIImage(image: image) else {
            throw FilterError.imageConversionFailed
        }
        
        guard let filter = CIFilter(name: "CIColorControls") else {
            throw FilterError.filterCreationFailed
        }
        
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        filter.setValue(0.0, forKey: kCIInputSaturationKey)
        
        guard let outputImage = filter.outputImage else {
            throw FilterError.filterApplicationFailed
        }
        
        return try renderCIImage(outputImage, size: image.size)
    }
    
    private func applyColorPopFilter(to image: UIImage, parameters: FilterParameters) async throws -> UIImage {
        guard let inputImage = CIImage(image: image) else {
            throw FilterError.imageConversionFailed
        }
        
        let saturation = parameters.getFloat("saturation", defaultValue: 1.4)
        let vibrance = parameters.getFloat("vibrance", defaultValue: 1.3)
        
        var outputImage = inputImage
        
        // Increase saturation
        if let satFilter = CIFilter(name: "CIColorControls") {
            satFilter.setValue(outputImage, forKey: kCIInputImageKey)
            satFilter.setValue(saturation, forKey: kCIInputSaturationKey)
            satFilter.setValue(1.1, forKey: kCIInputContrastKey)
            if let result = satFilter.outputImage {
                outputImage = result
            }
        }
        
        // Add vibrance
        if let vibranceFilter = CIFilter(name: "CIVibrance") {
            vibranceFilter.setValue(outputImage, forKey: kCIInputImageKey)
            vibranceFilter.setValue(vibrance, forKey: "inputAmount")
            if let result = vibranceFilter.outputImage {
                outputImage = result
            }
        }
        
        return try renderCIImage(outputImage, size: image.size)
    }
    
    // MARK: - Photo Filters
    
    private func applyPhotoFilter(
        to image: UIImage,
        filterName: String,
        parameters: FilterParameters
    ) async throws -> UIImage {
        
        guard let inputImage = CIImage(image: image) else {
            throw FilterError.imageConversionFailed
        }
        
        var outputImage = inputImage
        let intensity = parameters.intensity
        
        // Apply Core Image photo effects
        let ciFilterName = mapToCIFilterName(filterName)
        if let filter = CIFilter(name: ciFilterName) {
            filter.setValue(inputImage, forKey: kCIInputImageKey)
            if let result = filter.outputImage {
                outputImage = result
            }
        }
        
        // Blend with original based on intensity
        if intensity < 1.0 {
            outputImage = CIFilter(name: "CIBlendWithMask", parameters: [
                kCIInputImageKey: outputImage,
                kCIInputBackgroundImageKey: inputImage,
                "inputMaskImage": CIImage(color: CIColor(red: CGFloat(intensity), green: CGFloat(intensity), blue: CGFloat(intensity)))
            ])?.outputImage ?? outputImage
        }
        
        return try renderCIImage(outputImage, size: image.size)
    }
    
    private func mapToCIFilterName(_ filterName: String) -> String {
        switch filterName {
        case "sepia": return "CISepiaTone"
        case "noir": return "CIPhotoEffectNoir"
        case "fade": return "CIPhotoEffectFade"
        case "chrome": return "CIPhotoEffectChrome"
        case "transfer": return "CIPhotoEffectTransfer"
        case "instant": return "CIPhotoEffectInstant"
        case "vintage": return "CIPhotoEffectProcess"
        case "inkwell": return "CIPhotoEffectMono"
        default: return "CIPhotoEffectProcess"
        }
    }
    
    // MARK: - Custom Filter
    
    private func applyCustomFilter(to image: UIImage, parameters: FilterParameters) async throws -> UIImage {
        guard let inputImage = CIImage(image: image) else {
            throw FilterError.imageConversionFailed
        }
        
        var outputImage = inputImage
        
        // Apply custom parameters
        let brightness = parameters.getFloat("brightness", defaultValue: 1.0)
        let contrast = parameters.getFloat("contrast", defaultValue: 1.0)
        let saturation = parameters.getFloat("saturation", defaultValue: 1.0)
        let exposure = parameters.getFloat("exposure", defaultValue: 1.0)
        
        if let colorFilter = CIFilter(name: "CIColorControls") {
            colorFilter.setValue(outputImage, forKey: kCIInputImageKey)
            colorFilter.setValue(brightness - 1.0, forKey: kCIInputBrightnessKey)
            colorFilter.setValue(contrast, forKey: kCIInputContrastKey)
            colorFilter.setValue(saturation, forKey: kCIInputSaturationKey)
            if let result = colorFilter.outputImage {
                outputImage = result
            }
        }
        
        if exposure != 1.0, let exposureFilter = CIFilter(name: "CIExposureAdjust") {
            exposureFilter.setValue(outputImage, forKey: kCIInputImageKey)
            exposureFilter.setValue((exposure - 1.0) * 2.0, forKey: kCIInputEVKey)
            if let result = exposureFilter.outputImage {
                outputImage = result
            }
        }
        
        return try renderCIImage(outputImage, size: image.size)
    }
    
    // MARK: - Helper Methods
    
    private func createTexture(from image: UIImage) throws -> MTLTexture {
        guard let cgImage = image.cgImage else {
            throw FilterError.imageConversionFailed
        }
        
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm,
            width: cgImage.width,
            height: cgImage.height,
            mipmapped: false
        )
        textureDescriptor.usage = [.shaderRead, .shaderWrite]
        
        guard let texture = device.makeTexture(descriptor: textureDescriptor) else {
            throw FilterError.textureCreationFailed
        }
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: nil,
            width: cgImage.width,
            height: cgImage.height,
            bitsPerComponent: 8,
            bytesPerRow: 4 * cgImage.width,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
        
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
        
        if let data = context?.data {
            texture.replace(
                region: MTLRegionMake2D(0, 0, cgImage.width, cgImage.height),
                mipmapLevel: 0,
                withBytes: data,
                bytesPerRow: 4 * cgImage.width
            )
        }
        
        return texture
    }
    
    private func createOutputTexture(like inputTexture: MTLTexture) throws -> MTLTexture {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: inputTexture.pixelFormat,
            width: inputTexture.width,
            height: inputTexture.height,
            mipmapped: false
        )
        descriptor.usage = [.shaderRead, .shaderWrite]
        
        guard let texture = device.makeTexture(descriptor: descriptor) else {
            throw FilterError.textureCreationFailed
        }
        
        return texture
    }
    
    private func createImage(from texture: MTLTexture) throws -> UIImage {
        let width = texture.width
        let height = texture.height
        let bytesPerRow = 4 * width
        let imageByteCount = bytesPerRow * height
        let imageBytes = UnsafeMutableRawPointer.allocate(byteCount: imageByteCount, alignment: MemoryLayout<UInt8>.alignment)
        defer { imageBytes.deallocate() }
        
        texture.getBytes(
            imageBytes,
            bytesPerRow: bytesPerRow,
            from: MTLRegionMake2D(0, 0, width, height),
            mipmapLevel: 0
        )
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        guard let context = CGContext(
            data: imageBytes,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ),
        let cgImage = context.makeImage() else {
            throw FilterError.imageConversionFailed
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    private func renderCIImage(_ ciImage: CIImage, size: CGSize) throws -> UIImage {
        let extent = ciImage.extent
        guard let cgImage = ciContext.createCGImage(ciImage, from: extent) else {
            throw FilterError.imageConversionFailed
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    private func getOrCreatePipeline(functionName: String) throws -> MTLComputePipelineState {
        if let cached = pipelineCache[functionName] {
            return cached
        }
        
        guard let library = library,
              let function = library.makeFunction(name: functionName) else {
            throw FilterError.functionNotFound(functionName)
        }
        
        let pipeline = try device.makeComputePipelineState(function: function)
        pipelineCache[functionName] = pipeline
        
        return pipeline
    }
}

// MARK: - Error Types

enum FilterError: LocalizedError {
    case invalidFilter(String)
    case textureCreationFailed
    case imageConversionFailed
    case pipelineCreationFailed
    case filterCreationFailed
    case filterApplicationFailed
    case functionNotFound(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidFilter(let name):
            return "Invalid filter: \(name)"
        case .textureCreationFailed:
            return "Failed to create Metal texture"
        case .imageConversionFailed:
            return "Failed to convert image"
        case .pipelineCreationFailed:
            return "Failed to create compute pipeline"
        case .filterCreationFailed:
            return "Failed to create filter"
        case .filterApplicationFailed:
            return "Failed to apply filter"
        case .functionNotFound(let name):
            return "Metal function not found: \(name)"
        }
    }
}

