import UIKit
import React

@available(iOS 18.0, *)
@objc(FilteredImageViewManager)
class FilteredImageViewManager: RCTViewManager {
    
    override func view() -> UIView! {
        return FilteredImageView()
    }
    
    override static func requiresMainQueueSetup() -> Bool {
        return true
    }
}

// MARK: - FilteredImageView

@available(iOS 18.0, *)
class FilteredImageView: UIView {
    
    // Use UIImageView as fallback for simpler rendering
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    // MARK: - Properties
    
    private let filterEngine = MetalFilterEngine.shared
    private let imageLoader = ImageLoader.shared
    
    private var currentImage: UIImage?
    
    @objc var sourceUri: String? {
        didSet {
            if sourceUri != oldValue {
                // Clear current image to show loading state
                currentImage = nil
                imageView.image = nil
                loadAndRenderImage()
            }
        }
    }
    
    @objc var filter: String? {
        didSet {
            if filter != oldValue {
                applyFilterAndRender()
            }
        }
    }
    
    @objc var intensity: CGFloat = 1.0 {
        didSet {
            if intensity != oldValue {
                applyFilterAndRender()
            }
        }
    }
    
    @objc var customParams: NSDictionary? {
        didSet {
            // Only trigger re-render if customParams actually changed
            let oldDict = oldValue as? [String: Any] ?? [:]
            let newDict = customParams as? [String: Any] ?? [:]
            if !NSDictionary(dictionary: oldDict).isEqual(to: newDict) {
                applyFilterAndRender()
            }
        }
    }
    
    @objc var resizeMode: String = "cover" {
        didSet {
            updateResizeMode()
        }
    }
    
    @objc var onFilterApplied: RCTDirectEventBlock?
    @objc var onError: RCTDirectEventBlock?
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    private func updateResizeMode() {
        switch resizeMode {
        case "cover":
            imageView.contentMode = .scaleAspectFill
        case "contain":
            imageView.contentMode = .scaleAspectFit
        case "stretch":
            imageView.contentMode = .scaleToFill
        case "center":
            imageView.contentMode = .center
        default:
            imageView.contentMode = .scaleAspectFit
        }
    }
    
    // MARK: - Image Loading and Rendering
    
    private func loadAndRenderImage() {
        guard let uri = sourceUri, !uri.isEmpty else { return }
        
        Task { @MainActor in
            do {
                // For development: remove from cache to ensure fresh load
                // Uncomment this line if you're using random images:
                // imageLoader.removeFromCache(uri: uri)
                
                let image = try await imageLoader.loadImage(from: uri)
                self.currentImage = image
                
                // If no filter, show original image
                if let filterName = self.filter, !filterName.isEmpty {
                    self.applyFilterAndRender()
                } else {
                    self.imageView.image = image
                }
            } catch {
                self.onError?(["error": error.localizedDescription])
            }
        }
    }
    
    private func applyFilterAndRender() {
        guard let image = currentImage,
              let filterName = filter,
              !filterName.isEmpty else {
            // Show original image if no filter
            if let img = currentImage {
                imageView.image = img
            }
            return
        }
        
        Task { @MainActor in
            do {
                var parameters = FilterParameters()
                parameters.intensity = Float(intensity)
                
                // Only set customParams if it's not nil and not empty
                if let params = customParams as? [String: Any], !params.isEmpty {
                    parameters.customParams = params
                } else {
                    parameters.customParams = [:]
                }
                
                let filteredImage = try await filterEngine.applyFilter(
                    to: image,
                    filterName: filterName,
                    parameters: parameters
                )
                
                // Display the filtered image
                self.imageView.image = filteredImage
                self.onFilterApplied?([:])
            } catch {
                self.onError?(["error": error.localizedDescription])
            }
        }
    }
}

