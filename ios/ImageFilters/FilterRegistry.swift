import Foundation
import Metal
import CoreImage

/// Registry for managing available filters
@available(iOS 18.0, *)
class FilterRegistry {
    
    // MARK: - Singleton
    
    static let shared = FilterRegistry()
    
    // MARK: - Properties
    
    private var documentFilters: Set<String> = [
        "scan", "blackWhite", "enhance", "perspective", "grayscale", "colorPop"
    ]
    
    private var photoFilters: Set<String> = [
        "sepia", "noir", "fade", "chrome", "transfer", "instant",
        "vivid", "dramatic", "warm", "cool", "vintage",
        "clarendon", "gingham", "juno", "lark", "luna", "reyes", "valencia",
        "brooklyn", "earlybird", "hudson", "inkwell", "lofi", "mayfair",
        "nashville", "perpetua", "toaster", "walden", "xpro2"
    ]
    
    private var customFilters: Set<String> = ["custom"]
    
    // MARK: - Public Methods
    
    /// Get all available filters
    func getAllFilters() -> [String] {
        return Array(documentFilters.union(photoFilters).union(customFilters)).sorted()
    }
    
    /// Get filters by type
    func getFilters(type: String?) -> [String] {
        switch type?.lowercased() {
        case "document":
            return Array(documentFilters).sorted()
        case "photo":
            return Array(photoFilters).sorted()
        case "custom":
            return Array(customFilters).sorted()
        default:
            return getAllFilters()
        }
    }
    
    /// Check if filter is valid
    func isValid(filter: String) -> Bool {
        return documentFilters.contains(filter) ||
               photoFilters.contains(filter) ||
               customFilters.contains(filter)
    }
    
    /// Get filter category
    func getCategory(for filter: String) -> FilterCategory {
        if documentFilters.contains(filter) {
            return .document
        } else if photoFilters.contains(filter) {
            return .photo
        } else if customFilters.contains(filter) {
            return .custom
        }
        return .unknown
    }
    
    /// Register custom filter
    func registerCustomFilter(name: String) {
        customFilters.insert(name)
    }
    
    /// Unregister custom filter
    func unregisterCustomFilter(name: String) {
        customFilters.remove(name)
    }
}

// MARK: - Filter Category

enum FilterCategory {
    case document
    case photo
    case custom
    case unknown
}

// MARK: - Filter Parameters

struct FilterParameters {
    var intensity: Float = 1.0
    var customParams: [String: Any] = [:]
    
    func getFloat(_ key: String, defaultValue: Float = 1.0) -> Float {
        if let value = customParams[key] as? Float {
            return value
        } else if let value = customParams[key] as? Double {
            return Float(value)
        } else if let value = customParams[key] as? Int {
            return Float(value)
        }
        return defaultValue
    }
    
    func getInt(_ key: String, defaultValue: Int = 0) -> Int {
        if let value = customParams[key] as? Int {
            return value
        } else if let value = customParams[key] as? Double {
            return Int(value)
        } else if let value = customParams[key] as? Float {
            return Int(value)
        }
        return defaultValue
    }
    
    func getBool(_ key: String, defaultValue: Bool = false) -> Bool {
        return customParams[key] as? Bool ?? defaultValue
    }
}

