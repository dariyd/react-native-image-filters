package com.imagefilters

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.util.Base64
import com.bumptech.glide.Glide
import com.bumptech.glide.load.engine.DiskCacheStrategy
import com.bumptech.glide.request.FutureTarget
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File
import java.io.IOException
import java.net.URL
import java.util.concurrent.TimeUnit

/**
 * Image loader that supports local and remote URIs with caching using Glide
 */
class ImageLoader(private val context: Context) {
    
    companion object {
        private const val MAX_CACHE_SIZE_MB = 50L
        private const val TIMEOUT_SECONDS = 30L
    }
    
    /**
     * Load image from URI
     * @param uri Image URI (file://, https://, content://, or data:)
     * @return Loaded Bitmap
     */
    suspend fun loadImage(uri: String): Bitmap = withContext(Dispatchers.IO) {
        when {
            uri.startsWith("http://") || uri.startsWith("https://") -> {
                loadRemoteImage(uri)
            }
            uri.startsWith("file://") -> {
                loadLocalImage(uri)
            }
            uri.startsWith("content://") -> {
                loadContentUri(uri)
            }
            uri.startsWith("data:") -> {
                loadDataUri(uri)
            }
            else -> {
                // Assume local file path
                loadLocalImage("file://$uri")
            }
        }
    }
    
    /**
     * Preload image into cache
     * @param uri Image URI to preload
     */
    suspend fun preloadImage(uri: String) = withContext(Dispatchers.IO) {
        try {
            val futureTarget: FutureTarget<Bitmap> = Glide.with(context)
                .asBitmap()
                .load(uri)
                .diskCacheStrategy(DiskCacheStrategy.ALL)
                .submit()
            
            futureTarget.get(TIMEOUT_SECONDS, TimeUnit.SECONDS)
            Glide.with(context).clear(futureTarget)
        } catch (e: Exception) {
            throw ImageLoaderException("Failed to preload image: ${e.message}")
        }
    }
    
    /**
     * Clear the image cache
     */
    fun clearCache() {
        Glide.get(context).clearMemory()
        Thread {
            Glide.get(context).clearDiskCache()
        }.start()
    }
    
    /**
     * Remove specific image from cache
     * @param uri Image URI to remove
     */
    fun removeFromCache(uri: String) {
        // Per-URI eviction isn't directly supported by Glide; clear caches instead.
        clearCache()
    }
    
    // MARK: - Private Methods
    
    private suspend fun loadRemoteImage(uri: String): Bitmap = withContext(Dispatchers.IO) {
        try {
            val futureTarget: FutureTarget<Bitmap> = Glide.with(context)
                .asBitmap()
                .load(uri)
                .diskCacheStrategy(DiskCacheStrategy.ALL)
                .submit()
            
            val glideBitmap = futureTarget.get(TIMEOUT_SECONDS, TimeUnit.SECONDS)
                ?: throw ImageLoaderException("Failed to load remote image: $uri")
            
            // Create a mutable copy of the bitmap so we own it and can safely use it
            // after clearing the Glide target
            val bitmap = glideBitmap.copy(glideBitmap.config ?: Bitmap.Config.ARGB_8888, true)
            
            // Now safe to clear the target since we have our own copy
            Glide.with(context).clear(futureTarget)
            
            bitmap ?: throw ImageLoaderException("Failed to copy bitmap")
        } catch (e: Exception) {
            throw ImageLoaderException("Failed to load remote image: ${e.message}")
        }
    }
    
    private suspend fun loadLocalImage(uri: String): Bitmap = withContext(Dispatchers.IO) {
        try {
            val path = uri.removePrefix("file://")
            val file = File(path)
            
            if (!file.exists()) {
                throw ImageLoaderException("File not found: $path")
            }
            
            BitmapFactory.decodeFile(path)
                ?: throw ImageLoaderException("Failed to decode image: $path")
        } catch (e: Exception) {
            throw ImageLoaderException("Failed to load local image: ${e.message}")
        }
    }
    
    private suspend fun loadContentUri(uri: String): Bitmap = withContext(Dispatchers.IO) {
        try {
            val futureTarget: FutureTarget<Bitmap> = Glide.with(context)
                .asBitmap()
                .load(Uri.parse(uri))
                .submit()
            
            val glideBitmap = futureTarget.get(TIMEOUT_SECONDS, TimeUnit.SECONDS)
                ?: throw ImageLoaderException("Failed to load content URI: $uri")
            
            // Create a mutable copy of the bitmap so we own it and can safely use it
            // after clearing the Glide target
            val bitmap = glideBitmap.copy(glideBitmap.config ?: Bitmap.Config.ARGB_8888, true)
            
            // Now safe to clear the target since we have our own copy
            Glide.with(context).clear(futureTarget)
            
            bitmap ?: throw ImageLoaderException("Failed to copy bitmap")
        } catch (e: Exception) {
            throw ImageLoaderException("Failed to load content URI: ${e.message}")
        }
    }
    
    private fun loadDataUri(uri: String): Bitmap {
        try {
            // Parse data URI (e.g., data:image/png;base64,...)
            val commaIndex = uri.indexOf(',')
            if (commaIndex == -1) {
                throw ImageLoaderException("Invalid data URI")
            }
            
            val dataString = uri.substring(commaIndex + 1)
            val data = Base64.decode(dataString, Base64.DEFAULT)
            
            return BitmapFactory.decodeByteArray(data, 0, data.size)
                ?: throw ImageLoaderException("Failed to decode data URI")
        } catch (e: Exception) {
            throw ImageLoaderException("Failed to load data URI: ${e.message}")
        }
    }
}

/**
 * Exception thrown by ImageLoader
 */
class ImageLoaderException(message: String) : IOException(message)

