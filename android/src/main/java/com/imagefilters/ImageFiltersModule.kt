package com.imagefilters

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Matrix
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
    
    @ReactMethod
    override fun cropImage(options: ReadableMap, promise: Promise) {
        moduleScope.launch {
            try {
                val result = processCrop(options)
                promise.resolve(result)
            } catch (e: Exception) {
                promise.reject("CROP_ERROR", e.message, e)
            }
        }
    }
    
    @ReactMethod
    override fun resizeImage(options: ReadableMap, promise: Promise) {
        moduleScope.launch {
            try {
                val result = processResize(options)
                promise.resolve(result)
            } catch (e: Exception) {
                promise.reject("RESIZE_ERROR", e.message, e)
            }
        }
    }
    
    @ReactMethod
    override fun rotateImage(options: ReadableMap, promise: Promise) {
        moduleScope.launch {
            try {
                val result = processRotate(options)
                promise.resolve(result)
            } catch (e: Exception) {
                promise.reject("ROTATE_ERROR", e.message, e)
            }
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
    
    private suspend fun processCrop(options: ReadableMap): WritableNativeMap = withContext(Dispatchers.IO) {
        val sourceUri = options.getString("sourceUri")
            ?: throw IllegalArgumentException("sourceUri is required")
        
        val cropRect = options.getMap("cropRect")
            ?: throw IllegalArgumentException("cropRect is required")
        
        val x = cropRect.getDouble("x").toInt()
        val y = cropRect.getDouble("y").toInt()
        val width = cropRect.getDouble("width").toInt()
        val height = cropRect.getDouble("height").toInt()
        
        val returnFormat = options.getString("returnFormat") ?: "uri"
        val quality = if (options.hasKey("quality")) {
            options.getDouble("quality").toFloat()
        } else {
            0.9f
        }
        
        // Load image
        val bitmap = imageLoader.loadImage(sourceUri)
        
        // Crop using Bitmap.createBitmap
        val croppedBitmap = Bitmap.createBitmap(
            bitmap,
            x.coerceIn(0, bitmap.width),
            y.coerceIn(0, bitmap.height),
            width.coerceAtMost(bitmap.width - x),
            height.coerceAtMost(bitmap.height - y)
        )
        
        // Prepare result
        val result = WritableNativeMap()
        result.putInt("width", croppedBitmap.width)
        result.putInt("height", croppedBitmap.height)
        
        // Save to file if URI format requested
        if (returnFormat == "uri" || returnFormat == "both") {
            val fileUri = saveBitmapToTemp(croppedBitmap, quality)
            result.putString("uri", fileUri)
        }
        
        // Convert to base64 if requested
        if (returnFormat == "base64" || returnFormat == "both") {
            val base64 = bitmapToBase64(croppedBitmap, quality)
            result.putString("base64", base64)
        }
        
        // Clean up
        if (bitmap != croppedBitmap) {
            bitmap.recycle()
        }
        
        result
    }
    
    private suspend fun processResize(options: ReadableMap): WritableNativeMap = withContext(Dispatchers.IO) {
        val sourceUri = options.getString("sourceUri")
            ?: throw IllegalArgumentException("sourceUri is required")
        
        val returnFormat = options.getString("returnFormat") ?: "uri"
        val quality = if (options.hasKey("quality")) {
            options.getDouble("quality").toFloat()
        } else {
            0.9f
        }
        val mode = options.getString("mode") ?: "contain"
        
        // Load image
        val bitmap = imageLoader.loadImage(sourceUri)
        
        // Calculate target size
        val currentWidth = bitmap.width.toFloat()
        val currentHeight = bitmap.height.toFloat()
        
        val targetWidth: Int
        val targetHeight: Int
        
        if (options.hasKey("width")) {
            val width = options.getDouble("width").toInt()
            targetWidth = width
            targetHeight = if (options.hasKey("height")) {
                options.getDouble("height").toInt()
            } else {
                // Maintain aspect ratio
                (currentHeight * (width / currentWidth)).toInt()
            }
        } else if (options.hasKey("height")) {
            val height = options.getDouble("height").toInt()
            targetHeight = height
            targetWidth = (currentWidth * (height / currentHeight)).toInt()
        } else {
            throw IllegalArgumentException("width or height is required")
        }
        
        // Apply resize mode
        val resizedBitmap = when (mode) {
            "cover" -> {
                val scale = maxOf(targetWidth / currentWidth, targetHeight / currentHeight)
                val scaledWidth = (currentWidth * scale).toInt()
                val scaledHeight = (currentHeight * scale).toInt()
                val scaled = Bitmap.createScaledBitmap(bitmap, scaledWidth, scaledHeight, true)
                
                // Center crop to target size
                val x = (scaledWidth - targetWidth) / 2
                val y = (scaledHeight - targetHeight) / 2
                Bitmap.createBitmap(scaled, x, y, targetWidth, targetHeight)
            }
            "stretch" -> {
                Bitmap.createScaledBitmap(bitmap, targetWidth, targetHeight, true)
            }
            else -> { // "contain"
                val scale = minOf(targetWidth / currentWidth, targetHeight / currentHeight)
                val scaledWidth = (currentWidth * scale).toInt()
                val scaledHeight = (currentHeight * scale).toInt()
                Bitmap.createScaledBitmap(bitmap, scaledWidth, scaledHeight, true)
            }
        }
        
        // Prepare result
        val result = WritableNativeMap()
        result.putInt("width", resizedBitmap.width)
        result.putInt("height", resizedBitmap.height)
        
        // Save to file if URI format requested
        if (returnFormat == "uri" || returnFormat == "both") {
            val fileUri = saveBitmapToTemp(resizedBitmap, quality)
            result.putString("uri", fileUri)
        }
        
        // Convert to base64 if requested
        if (returnFormat == "base64" || returnFormat == "both") {
            val base64 = bitmapToBase64(resizedBitmap, quality)
            result.putString("base64", base64)
        }
        
        // Clean up
        if (bitmap != resizedBitmap) {
            bitmap.recycle()
        }
        
        result
    }
    
    private suspend fun processRotate(options: ReadableMap): WritableNativeMap = withContext(Dispatchers.IO) {
        val sourceUri = options.getString("sourceUri")
            ?: throw IllegalArgumentException("sourceUri is required")
        
        val degrees = if (options.hasKey("degrees")) {
            options.getDouble("degrees").toFloat()
        } else {
            throw IllegalArgumentException("degrees is required")
        }
        
        val returnFormat = options.getString("returnFormat") ?: "uri"
        val quality = if (options.hasKey("quality")) {
            options.getDouble("quality").toFloat()
        } else {
            0.9f
        }
        val expand = if (options.hasKey("expand")) {
            options.getBoolean("expand")
        } else {
            true
        }
        
        // Load image
        val bitmap = imageLoader.loadImage(sourceUri)
        
        // Create rotation matrix
        val matrix = Matrix()
        matrix.postRotate(degrees)
        
        // Apply rotation
        val rotatedBitmap = if (expand) {
            // Expand canvas to fit rotated image
            Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)
        } else {
            // Rotate without expanding (may clip)
            val result = Bitmap.createBitmap(bitmap.width, bitmap.height, bitmap.config)
            val canvas = Canvas(result)
            canvas.rotate(degrees, bitmap.width / 2f, bitmap.height / 2f)
            canvas.drawBitmap(bitmap, 0f, 0f, null)
            result
        }
        
        // Prepare result
        val result = WritableNativeMap()
        result.putInt("width", rotatedBitmap.width)
        result.putInt("height", rotatedBitmap.height)
        
        // Save to file if URI format requested
        if (returnFormat == "uri" || returnFormat == "both") {
            val fileUri = saveBitmapToTemp(rotatedBitmap, quality)
            result.putString("uri", fileUri)
        }
        
        // Convert to base64 if requested
        if (returnFormat == "base64" || returnFormat == "both") {
            val base64 = bitmapToBase64(rotatedBitmap, quality)
            result.putString("base64", base64)
        }
        
        // Clean up
        if (bitmap != rotatedBitmap) {
            bitmap.recycle()
        }
        
        result
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

