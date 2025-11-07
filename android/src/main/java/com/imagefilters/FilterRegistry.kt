package com.imagefilters

/**
 * Registry for managing available filters
 */
object FilterRegistry {
    
    private val documentFilters = setOf(
        "scan", "blackWhite", "enhance", "perspective", "grayscale", "colorPop"
    )
    
    private val photoFilters = setOf(
        "sepia", "noir", "fade", "chrome", "transfer", "instant",
        "vivid", "dramatic", "warm", "cool", "vintage",
        "clarendon", "gingham", "juno", "lark", "luna", "reyes", "valencia",
        "brooklyn", "earlybird", "hudson", "inkwell", "lofi", "mayfair",
        "nashville", "perpetua", "toaster", "walden", "xpro2"
    )
    
    private val customFilters = mutableSetOf("custom")
    
    /**
     * Get all available filters
     */
    fun getAllFilters(): List<String> {
        return (documentFilters + photoFilters + customFilters).sorted()
    }
    
    /**
     * Get filters by type
     */
    fun getFilters(type: String?): List<String> {
        return when (type?.lowercase()) {
            "document" -> documentFilters.sorted()
            "photo" -> photoFilters.sorted()
            "custom" -> customFilters.sorted()
            else -> getAllFilters()
        }
    }
    
    /**
     * Check if filter is valid
     */
    fun isValid(filter: String): Boolean {
        return documentFilters.contains(filter) ||
                photoFilters.contains(filter) ||
                customFilters.contains(filter)
    }
    
    /**
     * Get filter category
     */
    fun getCategory(filter: String): FilterCategory {
        return when {
            documentFilters.contains(filter) -> FilterCategory.DOCUMENT
            photoFilters.contains(filter) -> FilterCategory.PHOTO
            customFilters.contains(filter) -> FilterCategory.CUSTOM
            else -> FilterCategory.UNKNOWN
        }
    }
    
    /**
     * Register custom filter
     */
    fun registerCustomFilter(name: String) {
        customFilters.add(name)
    }
    
    /**
     * Unregister custom filter
     */
    fun unregisterCustomFilter(name: String) {
        customFilters.remove(name)
    }
}

/**
 * Filter category enum
 */
enum class FilterCategory {
    DOCUMENT,
    PHOTO,
    CUSTOM,
    UNKNOWN
}

/**
 * Filter parameters data class
 */
data class FilterParameters(
    var intensity: Float = 1.0f,
    var customParams: Map<String, Any> = emptyMap()
) {
    fun getFloat(key: String, defaultValue: Float = 1.0f): Float {
        return when (val value = customParams[key]) {
            is Number -> value.toFloat()
            else -> defaultValue
        }
    }
    
    fun getInt(key: String, defaultValue: Int = 0): Int {
        return when (val value = customParams[key]) {
            is Number -> value.toInt()
            else -> defaultValue
        }
    }
    
    fun getBoolean(key: String, defaultValue: Boolean = false): Boolean {
        return when (val value = customParams[key]) {
            is Boolean -> value
            else -> defaultValue
        }
    }
}

