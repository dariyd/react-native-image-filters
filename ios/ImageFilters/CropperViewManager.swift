import Foundation
import UIKit
import React

@objc(CropperViewManager)
class CropperViewManager: RCTViewManager {
    
    override func view() -> UIView! {
        return CropperView()
    }
    
    override static func requiresMainQueueSetup() -> Bool {
        return true
    }
    
    @objc func getCropRect(_ node: NSNumber) {
        DispatchQueue.main.async {
            if let view = self.bridge.uiManager.view(forReactTag: node) as? CropperView {
                let rect = view.getCurrentCropRect()
                // Return via callback or promise if needed
            }
        }
    }
    
    @objc func resetCropRect(_ node: NSNumber) {
        DispatchQueue.main.async {
            if let view = self.bridge.uiManager.view(forReactTag: node) as? CropperView {
                view.resetCropRect()
            }
        }
    }
    
    @objc func setCropRect(_ node: NSNumber, cropRect: NSDictionary) {
        DispatchQueue.main.async {
            if let view = self.bridge.uiManager.view(forReactTag: node) as? CropperView {
                view.setCropRect(cropRect)
            }
        }
    }
}

// MARK: - CropperView

class CropperView: UIView {
    
    private var imageView: UIImageView!
    private var scrollView: UIScrollView!
    private var cropOverlay: CropOverlayView!
    private let imageLoader = ImageLoader.shared
    
    private var currentImage: UIImage?
    private var imageSize: CGSize = .zero
    
    // Events
    @objc var onCropRectChange: RCTDirectEventBlock?
    @objc var onGestureEnd: RCTDirectEventBlock?
    
    // Props
    @objc var sourceUri: String? {
        didSet {
            if sourceUri != oldValue {
                loadImage()
            }
        }
    }
    
    @objc var initialCropRect: NSDictionary? {
        didSet {
            if let rect = initialCropRect {
                applyCropRect(rect)
            }
        }
    }
    
    @objc var aspectRatio: NSNumber? {
        didSet {
            cropOverlay?.aspectRatio = aspectRatio?.doubleValue
        }
    }
    
    @objc var minCropSize: NSDictionary? {
        didSet {
            if let size = minCropSize,
               let width = size["width"] as? CGFloat,
               let height = size["height"] as? CGFloat {
                cropOverlay?.minCropSize = CGSize(width: width, height: height)
            }
        }
    }
    
    @objc var showGrid: Bool = true {
        didSet {
            cropOverlay?.showGrid = showGrid
        }
    }
    
    @objc var gridColor: NSString? {
        didSet {
            if let colorString = gridColor as String? {
                cropOverlay?.gridColor = UIColor(hexString: colorString) ?? .white
            }
        }
    }
    
    @objc var overlayColor: NSString? {
        didSet {
            if let colorString = overlayColor as String? {
                cropOverlay?.overlayColor = UIColor(hexString: colorString) ?? UIColor.black.withAlphaComponent(0.5)
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = .black
        
        // Setup scroll view for pan and zoom
        scrollView = UIScrollView(frame: bounds)
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 3.0
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        addSubview(scrollView)
        
        // Setup image view
        imageView = UIImageView(frame: bounds)
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        scrollView.addSubview(imageView)
        
        // Setup crop overlay
        cropOverlay = CropOverlayView(frame: bounds)
        cropOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        cropOverlay.delegate = self
        addSubview(cropOverlay)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        scrollView.frame = bounds
        updateImageLayout()
        cropOverlay.frame = bounds
    }
    
    private func loadImage() {
        guard let uri = sourceUri else { return }
        
        Task {
            do {
                let image = try await imageLoader.loadImage(from: uri)
                await MainActor.run {
                    self.currentImage = image
                    self.imageSize = image.size
                    self.imageView.image = image
                    self.updateImageLayout()
                    self.cropOverlay.resetToFullImage()
                }
            } catch {
                print("Failed to load image: \(error)")
            }
        }
    }
    
    private func updateImageLayout() {
        guard let image = currentImage else { return }
        
        let imageSize = image.size
        let viewSize = bounds.size
        
        let widthRatio = viewSize.width / imageSize.width
        let heightRatio = viewSize.height / imageSize.height
        let scale = min(widthRatio, heightRatio)
        
        let scaledWidth = imageSize.width * scale
        let scaledHeight = imageSize.height * scale
        
        imageView.frame = CGRect(
            x: (viewSize.width - scaledWidth) / 2,
            y: (viewSize.height - scaledHeight) / 2,
            width: scaledWidth,
            height: scaledHeight
        )
        
        scrollView.contentSize = imageView.frame.size
    }
    
    func getCurrentCropRect() -> [String: Any] {
        return cropOverlay.getCropRect()
    }
    
    func resetCropRect() {
        cropOverlay.resetToFullImage()
    }
    
    func setCropRect(_ rect: NSDictionary) {
        applyCropRect(rect)
    }
    
    private func applyCropRect(_ rect: NSDictionary) {
        guard let x = rect["x"] as? CGFloat,
              let y = rect["y"] as? CGFloat,
              let width = rect["width"] as? CGFloat,
              let height = rect["height"] as? CGFloat else {
            return
        }
        
        cropOverlay.setCropRect(CGRect(x: x, y: y, width: width, height: height))
    }
}

// MARK: - UIScrollViewDelegate

extension CropperView: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        notifyGestureEnd()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            notifyGestureEnd()
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        notifyGestureEnd()
    }
}

// MARK: - CropOverlayDelegate

extension CropperView: CropOverlayDelegate {
    func cropOverlayDidChange(_ overlay: CropOverlayView, cropRect: CGRect) {
        onCropRectChange?([
            "cropRect": [
                "x": cropRect.origin.x,
                "y": cropRect.origin.y,
                "width": cropRect.size.width,
                "height": cropRect.size.height
            ]
        ])
    }
    
    func notifyGestureEnd() {
        let rect = cropOverlay.getCropRect()
        onGestureEnd?(["cropRect": rect])
    }
}

// MARK: - CropOverlayView

protocol CropOverlayDelegate: AnyObject {
    func cropOverlayDidChange(_ overlay: CropOverlayView, cropRect: CGRect)
}

class CropOverlayView: UIView {
    
    weak var delegate: CropOverlayDelegate?
    
    var aspectRatio: Double?
    var minCropSize: CGSize = CGSize(width: 50, height: 50)
    var showGrid: Bool = true {
        didSet {
            setNeedsDisplay()
        }
    }
    var gridColor: UIColor = .white {
        didSet {
            setNeedsDisplay()
        }
    }
    var overlayColor: UIColor = UIColor.black.withAlphaComponent(0.5) {
        didSet {
            setNeedsDisplay()
        }
    }
    
    private var cropRect: CGRect = .zero
    private var isDragging = false
    private var dragStartPoint: CGPoint = .zero
    private var dragStartRect: CGRect = .zero
    private var activeHandle: CropHandle = .none
    
    private enum CropHandle {
        case none
        case topLeft, topRight, bottomLeft, bottomRight
        case top, bottom, left, right
        case center
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        backgroundColor = .clear
        isUserInteractionEnabled = true
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(panGesture)
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        // Draw overlay
        context.setFillColor(overlayColor.cgColor)
        context.fill(rect)
        
        // Clear crop area
        context.setBlendMode(.clear)
        context.fill(cropRect)
        context.setBlendMode(.normal)
        
        // Draw crop rect border
        context.setStrokeColor(UIColor.white.cgColor)
        context.setLineWidth(2.0)
        context.stroke(cropRect)
        
        // Draw grid
        if showGrid {
            context.setStrokeColor(gridColor.withAlphaComponent(0.5).cgColor)
            context.setLineWidth(1.0)
            
            // Vertical lines
            let thirdWidth = cropRect.width / 3
            for i in 1..<3 {
                let x = cropRect.minX + (thirdWidth * CGFloat(i))
                context.move(to: CGPoint(x: x, y: cropRect.minY))
                context.addLine(to: CGPoint(x: x, y: cropRect.maxY))
            }
            
            // Horizontal lines
            let thirdHeight = cropRect.height / 3
            for i in 1..<3 {
                let y = cropRect.minY + (thirdHeight * CGFloat(i))
                context.move(to: CGPoint(x: cropRect.minX, y: y))
                context.addLine(to: CGPoint(x: cropRect.maxX, y: y))
            }
            
            context.strokePath()
        }
        
        // Draw corner handles
        let handleSize: CGFloat = 30
        let handleOffset: CGFloat = 15
        context.setFillColor(UIColor.white.cgColor)
        
        let corners: [(CGPoint, CGFloat, CGFloat)] = [
            (CGPoint(x: cropRect.minX, y: cropRect.minY), 0, 0), // Top left
            (CGPoint(x: cropRect.maxX, y: cropRect.minY), -handleSize, 0), // Top right
            (CGPoint(x: cropRect.minX, y: cropRect.maxY), 0, -handleSize), // Bottom left
            (CGPoint(x: cropRect.maxX, y: cropRect.maxY), -handleSize, -handleSize), // Bottom right
        ]
        
        for (point, xOffset, yOffset) in corners {
            let handleRect = CGRect(
                x: point.x + xOffset,
                y: point.y + yOffset,
                width: handleSize,
                height: handleSize
            )
            context.fill(handleRect)
        }
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: self)
        
        switch gesture.state {
        case .began:
            isDragging = true
            dragStartPoint = location
            dragStartRect = cropRect
            activeHandle = getHandle(at: location)
            
        case .changed:
            guard isDragging else { return }
            let translation = CGPoint(
                x: location.x - dragStartPoint.x,
                y: location.y - dragStartPoint.y
            )
            updateCropRect(with: translation)
            setNeedsDisplay()
            delegate?.cropOverlayDidChange(self, cropRect: cropRect)
            
        case .ended, .cancelled:
            isDragging = false
            activeHandle = .none
            
        default:
            break
        }
    }
    
    private func getHandle(at point: CGPoint) -> CropHandle {
        let handleSize: CGFloat = 44 // Touch target size
        
        // Check corners first
        if point.distance(to: CGPoint(x: cropRect.minX, y: cropRect.minY)) < handleSize {
            return .topLeft
        }
        if point.distance(to: CGPoint(x: cropRect.maxX, y: cropRect.minY)) < handleSize {
            return .topRight
        }
        if point.distance(to: CGPoint(x: cropRect.minX, y: cropRect.maxY)) < handleSize {
            return .bottomLeft
        }
        if point.distance(to: CGPoint(x: cropRect.maxX, y: cropRect.maxY)) < handleSize {
            return .bottomRight
        }
        
        // Check edges
        if abs(point.x - cropRect.minX) < handleSize && point.y > cropRect.minY && point.y < cropRect.maxY {
            return .left
        }
        if abs(point.x - cropRect.maxX) < handleSize && point.y > cropRect.minY && point.y < cropRect.maxY {
            return .right
        }
        if abs(point.y - cropRect.minY) < handleSize && point.x > cropRect.minX && point.x < cropRect.maxX {
            return .top
        }
        if abs(point.y - cropRect.maxY) < handleSize && point.x > cropRect.minX && point.x < cropRect.maxX {
            return .bottom
        }
        
        // Check center
        if cropRect.contains(point) {
            return .center
        }
        
        return .none
    }
    
    private func updateCropRect(with translation: CGPoint) {
        var newRect = dragStartRect
        
        switch activeHandle {
        case .topLeft:
            newRect.origin.x += translation.x
            newRect.origin.y += translation.y
            newRect.size.width -= translation.x
            newRect.size.height -= translation.y
            
        case .topRight:
            newRect.origin.y += translation.y
            newRect.size.width += translation.x
            newRect.size.height -= translation.y
            
        case .bottomLeft:
            newRect.origin.x += translation.x
            newRect.size.width -= translation.x
            newRect.size.height += translation.y
            
        case .bottomRight:
            newRect.size.width += translation.x
            newRect.size.height += translation.y
            
        case .left:
            newRect.origin.x += translation.x
            newRect.size.width -= translation.x
            
        case .right:
            newRect.size.width += translation.x
            
        case .top:
            newRect.origin.y += translation.y
            newRect.size.height -= translation.y
            
        case .bottom:
            newRect.size.height += translation.y
            
        case .center:
            newRect.origin.x += translation.x
            newRect.origin.y += translation.y
            
        case .none:
            return
        }
        
        // Apply aspect ratio constraint
        if let ratio = aspectRatio {
            newRect = applyAspectRatio(to: newRect, ratio: CGFloat(ratio), handle: activeHandle)
        }
        
        // Apply minimum size constraint
        newRect.size.width = max(newRect.size.width, minCropSize.width)
        newRect.size.height = max(newRect.size.height, minCropSize.height)
        
        // Keep within bounds
        newRect = newRect.intersection(bounds)
        
        cropRect = newRect
    }
    
    private func applyAspectRatio(to rect: CGRect, ratio: CGFloat, handle: CropHandle) -> CGRect {
        var newRect = rect
        
        switch handle {
        case .topLeft, .topRight, .bottomLeft, .bottomRight:
            // Adjust to maintain aspect ratio
            let currentRatio = rect.width / rect.height
            if currentRatio > ratio {
                newRect.size.width = rect.height * ratio
            } else {
                newRect.size.height = rect.width / ratio
            }
            
        case .left, .right:
            newRect.size.height = rect.width / ratio
            
        case .top, .bottom:
            newRect.size.width = rect.height * ratio
            
        default:
            break
        }
        
        return newRect
    }
    
    func resetToFullImage() {
        cropRect = bounds
        setNeedsDisplay()
    }
    
    func getCropRect() -> [String: Any] {
        return [
            "x": cropRect.origin.x,
            "y": cropRect.origin.y,
            "width": cropRect.size.width,
            "height": cropRect.size.height
        ]
    }
    
    func setCropRect(_ rect: CGRect) {
        cropRect = rect
        setNeedsDisplay()
    }
}

// MARK: - Helper Extensions

extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        return sqrt(pow(x - point.x, 2) + pow(y - point.y, 2))
    }
}

extension UIColor {
    convenience init?(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}

