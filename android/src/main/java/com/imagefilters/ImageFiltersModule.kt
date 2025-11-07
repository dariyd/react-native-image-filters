package com.imagefilters

import android.graphics.Bitmap
import android.util.Base64
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.ReadableArray
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.bridge.WritableNativeArray
import com.facebook.react.bridge.WritableNativeMap
import com.facebook.react.module.annotations.ReactModule
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream
import java.util.UUID
import kotlin.math.roundToInt

@ReactModule(name = ImageFiltersModule.NAME)
class ImageFiltersModule(reactContext: ReactApplicationContext) :
    NativeImageFiltersSpec(reactContext) {
    
    companion object {
        const val NAME = "ImageFilters"
    }
    
    private val imageLoader = ImageLoader(reactContext)
    private val filterEngine = FilterEngine(reactContext)
    private val moduleScope = CoroutineScope(Dispatchers.Main)
    
    override fun getName(): String = NAME
    
    @ReactMethod
    override fun applyFilter(options: ReadableMap, promise: Promise) {
        moduleScope.launch {
            try {
                val result = processFilter(options)
                promise.resolve(result)
            } catch (e: Exception) {
                promise.reject("FILTER_ERROR", e.message, e)
            }
        }
    }
    
    @ReactMethod
    override fun applyFilters(optionsArray: ReadableArray, promise: Promise) {
        moduleScope.launch {
            try {
                val results = WritableNativeArray()
                
                for (i in 0 until optionsArray.size()) {
                    val options = optionsArray.getMap(i)
                    if (options != null) {
                        val result = processFilter(options)
                        results.pushMap(result)
                    }
                }
                
                promise.resolve(results)
            } catch (e: Exception) {
                promise.reject("FILTER_ERROR", e.message, e)
            }
        }
    }
    
    @ReactMethod
    override fun getAvailableFilters(type: String?, promise: Promise) {
        try {
            val filters = FilterRegistry.getFilters(type)
            val array = WritableNativeArray()
            filters.forEach { array.pushString(it) }
            promise.resolve(array)
        } catch (e: Exception) {
            promise.reject("REGISTRY_ERROR", e.message, e)
        }
    }
    
    @ReactMethod
    override fun preloadImage(uri: String, promise: Promise) {
        moduleScope.launch {
            try {
                imageLoader.preloadImage(uri)
                promise.resolve(null)
            } catch (e: Exception) {
                promise.reject("PRELOAD_ERROR", e.message, e)
            }
        }
    }
    
    @ReactMethod
    override fun clearCache(promise: Promise) {
        try {
            imageLoader.clearCache()
            promise.resolve(null)
        } catch (e: Exception) {
            promise.reject("CACHE_ERROR", e.message, e)
        }
    }
    
    // Helper Methods
    
    private suspend fun processFilter(options: ReadableMap): WritableNativeMap = withContext(Dispatchers.IO) {
        val sourceUri = options.getString("sourceUri")
            ?: throw IllegalArgumentException("sourceUri is required")
        
        val filterName = options.getString("filter")
            ?: throw IllegalArgumentException("filter is required")
        
        val intensity = if (options.hasKey("intensity")) {
            options.getDouble("intensity").toFloat()
        } else {
            1.0f
        }
        
        val customParams = if (options.hasKey("customParams")) {
            options.getMap("customParams")?.toHashMap() ?: emptyMap()
        } else {
            emptyMap()
        }
        
        val returnFormat = options.getString("returnFormat") ?: "uri"
        val quality = if (options.hasKey("quality")) {
            options.getDouble("quality").toFloat()
        } else {
            0.9f
        }
        
        // Load image
        val bitmap = imageLoader.loadImage(sourceUri)
        
        // Create filter parameters
        val parameters = FilterParameters(
            intensity = intensity,
            customParams = customParams as Map<String, Any>
        )
        
        // Apply filter
        val filteredBitmap = filterEngine.applyFilter(bitmap, filterName, parameters)
        
        // Prepare result
        val result = WritableNativeMap()
        result.putInt("width", filteredBitmap.width)
        result.putInt("height", filteredBitmap.height)
        
        // Save to file if URI format requested
        if (returnFormat == "uri" || returnFormat == "both") {
            val fileUri = saveBitmapToTemp(filteredBitmap, quality)
            result.putString("uri", fileUri)
        }
        
        // Convert to base64 if requested
        if (returnFormat == "base64" || returnFormat == "both") {
            val base64 = bitmapToBase64(filteredBitmap, quality)
            result.putString("base64", base64)
        }
        
        // Clean up
        if (bitmap != filteredBitmap) {
            bitmap.recycle()
        }
        
        result
    }
    
    private fun saveBitmapToTemp(bitmap: Bitmap, quality: Float): String {
        val tempDir = reactApplicationContext.cacheDir
        val fileName = "filtered_${UUID.randomUUID()}.jpg"
        val file = File(tempDir, fileName)
        
        FileOutputStream(file).use { out ->
            val q = normalizeQuality(quality)
            bitmap.compress(Bitmap.CompressFormat.JPEG, q, out)
        }
        
        return "file://${file.absolutePath}"
    }
    
    private fun bitmapToBase64(bitmap: Bitmap, quality: Float): String {
        val outputStream = ByteArrayOutputStream()
        val q = normalizeQuality(quality)
        bitmap.compress(Bitmap.CompressFormat.JPEG, q, outputStream)
        val bytes = outputStream.toByteArray()
        return Base64.encodeToString(bytes, Base64.DEFAULT)
    }

    private fun normalizeQuality(input: Float): Int {
        val q = if (input.isNaN()) 0.9f else input
        val normalized = if (q <= 1f) q * 100f else q
        return normalized.roundToInt().coerceIn(0, 100)
    }
}

// Extension to convert ReadableMap to HashMap
private fun ReadableMap.toHashMap(): Map<String, Any> {
    val map = mutableMapOf<String, Any>()
    val iterator = this.keySetIterator()
    
    while (iterator.hasNextKey()) {
        val key = iterator.nextKey()
        val type = this.getType(key)
        
        when (type) {
            com.facebook.react.bridge.ReadableType.Null -> {
                // Skip null values
            }
            com.facebook.react.bridge.ReadableType.Boolean -> {
                map[key] = this.getBoolean(key) as Any
            }
            com.facebook.react.bridge.ReadableType.Number -> {
                map[key] = this.getDouble(key) as Any
            }
            com.facebook.react.bridge.ReadableType.String -> {
                this.getString(key)?.let { map[key] = it as Any }
            }
            com.facebook.react.bridge.ReadableType.Map -> {
                this.getMap(key)?.toHashMap()?.let { map[key] = it as Any }
            }
            com.facebook.react.bridge.ReadableType.Array -> {
                // Handle if needed
            }
        }
    }
    
    return map as Map<String, Any>
}

