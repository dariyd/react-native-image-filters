package com.imagefilters

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.ColorMatrix
import android.graphics.ColorMatrixColorFilter
import android.graphics.Paint
import androidx.core.graphics.applyCanvas
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlin.math.min

/**
 * Filter engine for GPU/CPU-accelerated image processing
 * Uses Android graphics APIs for filtering
 */
class FilterEngine(private val context: Context) {
    
    /**
     * Apply filter to bitmap
     */
    suspend fun applyFilter(
        bitmap: Bitmap,
        filterName: String,
        parameters: FilterParameters
    ): Bitmap = withContext(Dispatchers.Default) {
        
        val category = FilterRegistry.getCategory(filterName)
        
        when (category) {
            FilterCategory.DOCUMENT -> applyDocumentFilter(bitmap, filterName, parameters)
            FilterCategory.PHOTO -> applyPhotoFilter(bitmap, filterName, parameters)
            FilterCategory.CUSTOM -> applyCustomFilter(bitmap, parameters)
            FilterCategory.UNKNOWN -> throw FilterException("Unknown filter: $filterName")
        }
    }
    
    // MARK: - Document Filters
    
    private fun applyDocumentFilter(
        bitmap: Bitmap,
        filterName: String,
        parameters: FilterParameters
    ): Bitmap {
        return when (filterName) {
            "scan" -> applyScanFilter(bitmap, parameters)
            "blackWhite" -> applyBlackWhiteFilter(bitmap, parameters)
            "enhance" -> applyEnhanceFilter(bitmap, parameters)
            "perspective" -> applyPerspectiveFilter(bitmap, parameters)
            "grayscale" -> applyGrayscaleFilter(bitmap, parameters)
            "colorPop" -> applyColorPopFilter(bitmap, parameters)
            else -> throw FilterException("Unknown document filter: $filterName")
        }
    }
    
    private fun applyScanFilter(bitmap: Bitmap, parameters: FilterParameters): Bitmap {
        val threshold = parameters.getFloat("threshold", 0.5f)
        val contrast = parameters.getFloat("contrast", 1.2f)
        val sharpness = parameters.getFloat("sharpness", 1.1f)
        val intensity = parameters.intensity
        
        val result = Bitmap.createBitmap(bitmap.width, bitmap.height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(result)
        
        // Apply contrast and threshold
        val colorMatrix = ColorMatrix()
        colorMatrix.set(
            floatArrayOf(
                contrast, 0f, 0f, 0f, (threshold - 0.5f) * 255 * contrast,
                0f, contrast, 0f, 0f, (threshold - 0.5f) * 255 * contrast,
                0f, 0f, contrast, 0f, (threshold - 0.5f) * 255 * contrast,
                0f, 0f, 0f, 1f, 0f
            )
        )
        
        val paint = Paint().apply {
            colorFilter = ColorMatrixColorFilter(colorMatrix)
        }
        
        canvas.drawBitmap(bitmap, 0f, 0f, paint)
        
        return if (intensity < 1.0f) {
            blendBitmaps(bitmap, result, intensity)
        } else {
            result
        }
    }
    
    private fun applyBlackWhiteFilter(bitmap: Bitmap, parameters: FilterParameters): Bitmap {
        val threshold = parameters.getFloat("threshold", 0.6f)
        val intensity = parameters.intensity
        
        val result = Bitmap.createBitmap(bitmap.width, bitmap.height, Bitmap.Config.ARGB_8888)
        
        val pixels = IntArray(bitmap.width * bitmap.height)
        bitmap.getPixels(pixels, 0, bitmap.width, 0, 0, bitmap.width, bitmap.height)
        
        for (i in pixels.indices) {
            val pixel = pixels[i]
            val r = (pixel shr 16) and 0xFF
            val g = (pixel shr 8) and 0xFF
            val b = pixel and 0xFF
            
            // Luminance
            val luminance = (0.299f * r + 0.587f * g + 0.114f * b) / 255f
            
            // Apply threshold
            val bw = if (luminance > threshold) 255 else 0
            
            pixels[i] = (0xFF shl 24) or (bw shl 16) or (bw shl 8) or bw
        }
        
        result.setPixels(pixels, 0, bitmap.width, 0, 0, bitmap.width, bitmap.height)
        
        return if (intensity < 1.0f) {
            blendBitmaps(bitmap, result, intensity)
        } else {
            result
        }
    }
    
    private fun applyEnhanceFilter(bitmap: Bitmap, parameters: FilterParameters): Bitmap {
        val brightness = parameters.getFloat("brightness", 1.1f)
        val contrast = parameters.getFloat("contrast", 1.15f)
        val saturation = parameters.getFloat("saturation", 1.05f)
        val intensity = parameters.intensity
        
        val colorMatrix = ColorMatrix()
        
        // Brightness
        val brightnessMatrix = ColorMatrix().apply {
            setScale(brightness, brightness, brightness, 1f)
        }
        
        // Contrast
        val scale = contrast
        val translate = (1.0f - contrast) * 127.5f
        val contrastMatrix = ColorMatrix(
            floatArrayOf(
                scale, 0f, 0f, 0f, translate,
                0f, scale, 0f, 0f, translate,
                0f, 0f, scale, 0f, translate,
                0f, 0f, 0f, 1f, 0f
            )
        )
        
        // Saturation
        val saturationMatrix = ColorMatrix()
        saturationMatrix.setSaturation(saturation)
        
        // Combine all matrices
        colorMatrix.postConcat(brightnessMatrix)
        colorMatrix.postConcat(contrastMatrix)
        colorMatrix.postConcat(saturationMatrix)
        
        val result = Bitmap.createBitmap(bitmap.width, bitmap.height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(result)
        val paint = Paint().apply {
            colorFilter = ColorMatrixColorFilter(colorMatrix)
        }
        
        canvas.drawBitmap(bitmap, 0f, 0f, paint)
        
        return if (intensity < 1.0f) {
            blendBitmaps(bitmap, result, intensity)
        } else {
            result
        }
    }
    
    private fun applyPerspectiveFilter(bitmap: Bitmap, parameters: FilterParameters): Bitmap {
        // Simplified perspective correction
        // In production, would use proper corner detection and transformation
        return bitmap.copy(bitmap.config, true)
    }
    
    private fun applyGrayscaleFilter(bitmap: Bitmap, parameters: FilterParameters): Bitmap {
        val intensity = parameters.intensity
        
        val colorMatrix = ColorMatrix()
        colorMatrix.setSaturation(0f)
        
        val result = Bitmap.createBitmap(bitmap.width, bitmap.height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(result)
        val paint = Paint().apply {
            colorFilter = ColorMatrixColorFilter(colorMatrix)
        }
        
        canvas.drawBitmap(bitmap, 0f, 0f, paint)
        
        return if (intensity < 1.0f) {
            blendBitmaps(bitmap, result, intensity)
        } else {
            result
        }
    }
    
    private fun applyColorPopFilter(bitmap: Bitmap, parameters: FilterParameters): Bitmap {
        val saturation = parameters.getFloat("saturation", 1.4f)
        val vibrance = parameters.getFloat("vibrance", 1.3f)
        val intensity = parameters.intensity
        
        val colorMatrix = ColorMatrix()
        colorMatrix.setSaturation(saturation * vibrance)
        
        // Add slight contrast boost
        val scale = 1.1f
        val translate = (1.0f - scale) * 127.5f
        val contrastMatrix = ColorMatrix(
            floatArrayOf(
                scale, 0f, 0f, 0f, translate,
                0f, scale, 0f, 0f, translate,
                0f, 0f, scale, 0f, translate,
                0f, 0f, 0f, 1f, 0f
            )
        )
        
        colorMatrix.postConcat(contrastMatrix)
        
        val result = Bitmap.createBitmap(bitmap.width, bitmap.height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(result)
        val paint = Paint().apply {
            colorFilter = ColorMatrixColorFilter(colorMatrix)
        }
        
        canvas.drawBitmap(bitmap, 0f, 0f, paint)
        
        return if (intensity < 1.0f) {
            blendBitmaps(bitmap, result, intensity)
        } else {
            result
        }
    }
    
    // MARK: - Photo Filters
    
    private fun applyPhotoFilter(
        bitmap: Bitmap,
        filterName: String,
        parameters: FilterParameters
    ): Bitmap {
        val intensity = parameters.intensity
        
        val colorMatrix = when (filterName) {
            "sepia" -> getSepiaMatrix()
            "noir", "inkwell" -> getNoirMatrix()
            "fade" -> getFadeMatrix()
            "chrome" -> getChromeMatrix()
            "vivid" -> getVividMatrix()
            "dramatic" -> getDramaticMatrix()
            "warm" -> getWarmMatrix()
            "cool" -> getCoolMatrix()
            "vintage" -> getVintageMatrix()
            else -> getDefaultPhotoMatrix(filterName)
        }
        
        val result = Bitmap.createBitmap(bitmap.width, bitmap.height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(result)
        val paint = Paint().apply {
            colorFilter = ColorMatrixColorFilter(colorMatrix)
        }
        
        canvas.drawBitmap(bitmap, 0f, 0f, paint)
        
        return if (intensity < 1.0f) {
            blendBitmaps(bitmap, result, intensity)
        } else {
            result
        }
    }
    
    private fun getSepiaMatrix() = ColorMatrix().apply {
        set(
            floatArrayOf(
                0.393f, 0.769f, 0.189f, 0f, 0f,
                0.349f, 0.686f, 0.168f, 0f, 0f,
                0.272f, 0.534f, 0.131f, 0f, 0f,
                0f, 0f, 0f, 1f, 0f
            )
        )
    }
    
    private fun getNoirMatrix() = ColorMatrix().apply {
        setSaturation(0f)
        postConcat(ColorMatrix(floatArrayOf(
            1.2f, 0f, 0f, 0f, -25f,
            0f, 1.2f, 0f, 0f, -25f,
            0f, 0f, 1.2f, 0f, -25f,
            0f, 0f, 0f, 1f, 0f
        )))
    }
    
    private fun getFadeMatrix() = ColorMatrix(
        floatArrayOf(
            0.85f, 0f, 0f, 0f, 38f,
            0f, 0.85f, 0f, 0f, 38f,
            0f, 0f, 0.85f, 0f, 38f,
            0f, 0f, 0f, 1f, 0f
        )
    )
    
    private fun getChromeMatrix() = ColorMatrix().apply {
        setSaturation(0.7f)
        postConcat(ColorMatrix(floatArrayOf(
            1.4f, 0f, 0f, 0f, -51f,
            0f, 1.4f, 0f, 0f, -51f,
            0f, 0f, 1.4f, 0f, -51f,
            0f, 0f, 0f, 1f, 0f
        )))
    }
    
    private fun getVividMatrix() = ColorMatrix().apply {
        setSaturation(1.5f)
        postConcat(ColorMatrix(floatArrayOf(
            1.2f, 0f, 0f, 0f, 0f,
            0f, 1.2f, 0f, 0f, 0f,
            0f, 0f, 1.2f, 0f, 0f,
            0f, 0f, 0f, 1f, 0f
        )))
    }
    
    private fun getDramaticMatrix() = ColorMatrix().apply {
        setSaturation(0.8f)
        postConcat(ColorMatrix(floatArrayOf(
            1.5f, 0f, 0f, 0f, -63f,
            0f, 1.5f, 0f, 0f, -63f,
            0f, 0f, 1.5f, 0f, -63f,
            0f, 0f, 0f, 1f, 0f
        )))
    }
    
    private fun getWarmMatrix() = ColorMatrix(
        floatArrayOf(
            1.2f, 0f, 0f, 0f, 0f,
            0f, 1.05f, 0f, 0f, 0f,
            0f, 0f, 0.8f, 0f, 0f,
            0f, 0f, 0f, 1f, 0f
        )
    )
    
    private fun getCoolMatrix() = ColorMatrix(
        floatArrayOf(
            0.8f, 0f, 0f, 0f, 0f,
            0f, 0.95f, 0f, 0f, 0f,
            0f, 0f, 1.2f, 0f, 0f,
            0f, 0f, 0f, 1f, 0f
        )
    )
    
    private fun getVintageMatrix() = ColorMatrix().apply {
        setSaturation(0.85f)
        postConcat(getSepiaMatrix())
        postConcat(ColorMatrix(floatArrayOf(
            0.9f, 0f, 0f, 0f, 13f,
            0f, 0.9f, 0f, 0f, 13f,
            0f, 0f, 0.9f, 0f, 13f,
            0f, 0f, 0f, 1f, 0f
        )))
    }
    
    private fun getDefaultPhotoMatrix(filterName: String): ColorMatrix {
        // Default matrix for Instagram-style filters
        return ColorMatrix().apply {
            setSaturation(1.1f)
        }
    }
    
    // MARK: - Custom Filter
    
    private fun applyCustomFilter(bitmap: Bitmap, parameters: FilterParameters): Bitmap {
        val brightness = parameters.getFloat("brightness", 1.0f)
        val contrast = parameters.getFloat("contrast", 1.0f)
        val saturation = parameters.getFloat("saturation", 1.0f)
        val exposure = parameters.getFloat("exposure", 1.0f)
        val intensity = parameters.intensity
        
        val colorMatrix = ColorMatrix()
        
        // Saturation
        val satMatrix = ColorMatrix()
        satMatrix.setSaturation(saturation)
        colorMatrix.postConcat(satMatrix)
        
        // Brightness & Contrast
        val scale = contrast * exposure * brightness
        val translate = (1.0f - scale) * 127.5f
        val bcMatrix = ColorMatrix(
            floatArrayOf(
                scale, 0f, 0f, 0f, translate,
                0f, scale, 0f, 0f, translate,
                0f, 0f, scale, 0f, translate,
                0f, 0f, 0f, 1f, 0f
            )
        )
        colorMatrix.postConcat(bcMatrix)
        
        val result = Bitmap.createBitmap(bitmap.width, bitmap.height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(result)
        val paint = Paint().apply {
            colorFilter = ColorMatrixColorFilter(colorMatrix)
        }
        
        canvas.drawBitmap(bitmap, 0f, 0f, paint)
        
        return if (intensity < 1.0f) {
            blendBitmaps(bitmap, result, intensity)
        } else {
            result
        }
    }
    
    // MARK: - Helper Methods
    
    private fun blendBitmaps(original: Bitmap, filtered: Bitmap, intensity: Float): Bitmap {
        val result = Bitmap.createBitmap(original.width, original.height, Bitmap.Config.ARGB_8888)
        
        val originalPixels = IntArray(original.width * original.height)
        val filteredPixels = IntArray(filtered.width * filtered.height)
        
        original.getPixels(originalPixels, 0, original.width, 0, 0, original.width, original.height)
        filtered.getPixels(filteredPixels, 0, filtered.width, 0, 0, filtered.width, filtered.height)
        
        for (i in originalPixels.indices) {
            val origPixel = originalPixels[i]
            val filtPixel = filteredPixels[i]
            
            val a = (origPixel shr 24) and 0xFF
            val r = blend((origPixel shr 16) and 0xFF, (filtPixel shr 16) and 0xFF, intensity)
            val g = blend((origPixel shr 8) and 0xFF, (filtPixel shr 8) and 0xFF, intensity)
            val b = blend(origPixel and 0xFF, filtPixel and 0xFF, intensity)
            
            originalPixels[i] = (a shl 24) or (r shl 16) or (g shl 8) or b
        }
        
        result.setPixels(originalPixels, 0, result.width, 0, 0, result.width, result.height)
        
        return result
    }
    
    private fun blend(original: Int, filtered: Int, intensity: Float): Int {
        return (original * (1 - intensity) + filtered * intensity).toInt().coerceIn(0, 255)
    }
}

/**
 * Exception thrown by FilterEngine
 */
class FilterException(message: String) : Exception(message)

