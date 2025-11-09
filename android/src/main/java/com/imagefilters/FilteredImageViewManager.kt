package com.imagefilters

import android.graphics.Bitmap
import androidx.appcompat.widget.AppCompatImageView
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.common.MapBuilder
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.annotations.ReactProp
import com.facebook.react.uimanager.events.RCTEventEmitter
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class FilteredImageViewManager(private val reactContext: ReactApplicationContext) :
    SimpleViewManager<FilteredImageView>() {
    
    companion object {
        const val REACT_CLASS = "FilteredImageView"
    }
    
    override fun getName(): String = REACT_CLASS
    
    override fun createViewInstance(reactContext: ThemedReactContext): FilteredImageView {
        return FilteredImageView(reactContext)
    }
    
    @ReactProp(name = "sourceUri")
    fun setSourceUri(view: FilteredImageView, sourceUri: String?) {
        view.setSourceUri(sourceUri)
    }
    
    @ReactProp(name = "filter")
    fun setFilter(view: FilteredImageView, filter: String?) {
        view.setFilter(filter)
    }
    
    @ReactProp(name = "intensity")
    fun setIntensity(view: FilteredImageView, intensity: Float) {
        view.setIntensity(intensity)
    }
    
    @ReactProp(name = "customParams")
    fun setCustomParams(view: FilteredImageView, customParams: ReadableMap?) {
        view.setCustomParams(customParams?.toHashMap() ?: emptyMap())
    }
    
    @ReactProp(name = "resizeMode")
    fun setResizeMode(view: FilteredImageView, resizeMode: String?) {
        view.setResizeMode(resizeMode ?: "cover")
    }
    
    override fun getExportedCustomDirectEventTypeConstants(): Map<String, Any>? {
        return MapBuilder.of(
            "onFilterApplied", MapBuilder.of("registrationName", "onFilterApplied"),
            "onError", MapBuilder.of("registrationName", "onError")
        )
    }
}

class FilteredImageView(private val context: ThemedReactContext) : AppCompatImageView(context) {
    
    private val imageLoader = ImageLoader(context)
    private val filterEngine = FilterEngine(context)
    private val viewScope = CoroutineScope(Dispatchers.Main)
    
    private var currentBitmap: Bitmap? = null
    private var sourceUri: String? = null
    private var filterName: String? = null
    private var intensity: Float = 1.0f
    private var customParams: Map<String, Any> = emptyMap()
    
    init {
        scaleType = ScaleType.CENTER_CROP
    }
    
    fun setSourceUri(uri: String?) {
        if (sourceUri != uri) {
            sourceUri = uri
            loadAndRenderImage()
        }
    }
    
    fun setFilter(filter: String?) {
        if (filterName != filter) {
            filterName = filter
            applyFilterAndRender()
        }
    }
    
    fun setIntensity(value: Float) {
        if (intensity != value) {
            intensity = value.coerceIn(0f, 1f)
            applyFilterAndRender()
        }
    }
    
    fun setCustomParams(params: Map<String, Any?>) {
        customParams = params as Map<String, Any>
        applyFilterAndRender()
    }
    
    fun setResizeMode(mode: String) {
        scaleType = when (mode) {
            "cover" -> ScaleType.CENTER_CROP
            "contain" -> ScaleType.FIT_CENTER
            "stretch" -> ScaleType.FIT_XY
            "center" -> ScaleType.CENTER
            else -> ScaleType.CENTER_CROP
        }
    }
    
    private fun loadAndRenderImage() {
        val uri = sourceUri
        if (uri.isNullOrEmpty()) return
        
        viewScope.launch {
            try {
                val bitmap = withContext(Dispatchers.IO) {
                    imageLoader.loadImage(uri)
                }
                
                // Swap bitmaps on main thread to avoid race conditions
                val oldBitmap = currentBitmap
                currentBitmap = bitmap
                
                // Recycle old bitmap after swap to prevent memory leaks
                oldBitmap?.let { old ->
                    if (!old.isRecycled && old != bitmap) {
                        old.recycle()
                    }
                }
                
                applyFilterAndRender()
            } catch (e: Exception) {
                sendErrorEvent(e.message ?: "Failed to load image")
            }
        }
    }
    
    private fun applyFilterAndRender() {
        val bitmap = currentBitmap
        val filter = filterName
        
        if (bitmap == null || filter.isNullOrEmpty()) {
            if (bitmap != null) {
                setImageBitmap(bitmap)
            }
            return
        }
        
        viewScope.launch {
            try {
                val parameters = FilterParameters(
                    intensity = intensity,
                    customParams = customParams
                )
                
                val filteredBitmap = withContext(Dispatchers.IO) {
                    filterEngine.applyFilter(bitmap, filter, parameters)
                }
                
                setImageBitmap(filteredBitmap)
                sendFilterAppliedEvent()
            } catch (e: Exception) {
                sendErrorEvent(e.message ?: "Failed to apply filter")
            }
        }
    }
    
    private fun sendFilterAppliedEvent() {
        context.getJSModule(RCTEventEmitter::class.java)
            .receiveEvent(id, "onFilterApplied", null)
    }
    
    private fun sendErrorEvent(error: String) {
        val event = com.facebook.react.bridge.Arguments.createMap()
        event.putString("error", error)
        context.getJSModule(RCTEventEmitter::class.java)
            .receiveEvent(id, "onError", event)
    }
    
    override fun onDetachedFromWindow() {
        super.onDetachedFromWindow()
        // Now we can safely recycle since we own the bitmap (it's a copy)
        currentBitmap?.let { bitmap ->
            if (!bitmap.isRecycled) {
                bitmap.recycle()
            }
        }
        currentBitmap = null
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

