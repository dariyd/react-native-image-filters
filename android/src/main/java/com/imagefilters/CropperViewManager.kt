package com.imagefilters

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.*
import android.view.GestureDetector
import android.view.MotionEvent
import android.view.ScaleGestureDetector
import android.view.View
import androidx.appcompat.widget.AppCompatImageView
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.common.MapBuilder
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.annotations.ReactProp
import com.facebook.react.uimanager.events.RCTEventEmitter
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min

class CropperViewManager(private val reactContext: ReactApplicationContext) :
    SimpleViewManager<CropperView>() {
    
    companion object {
        const val REACT_CLASS = "CropperView"
    }
    
    override fun getName(): String = REACT_CLASS
    
    override fun createViewInstance(reactContext: ThemedReactContext): CropperView {
        return CropperView(reactContext)
    }
    
    @ReactProp(name = "sourceUri")
    fun setSourceUri(view: CropperView, sourceUri: String?) {
        view.setSourceUri(sourceUri)
    }
    
    @ReactProp(name = "initialCropRect")
    fun setInitialCropRect(view: CropperView, cropRect: ReadableMap?) {
        view.setInitialCropRect(cropRect)
    }
    
    @ReactProp(name = "aspectRatio")
    fun setAspectRatio(view: CropperView, aspectRatio: Double) {
        view.setAspectRatio(if (aspectRatio > 0) aspectRatio.toFloat() else null)
    }
    
    @ReactProp(name = "minCropSize")
    fun setMinCropSize(view: CropperView, size: ReadableMap?) {
        view.setMinCropSize(size)
    }
    
    @ReactProp(name = "showGrid")
    fun setShowGrid(view: CropperView, showGrid: Boolean) {
        view.setShowGrid(showGrid)
    }
    
    @ReactProp(name = "gridColor")
    fun setGridColor(view: CropperView, color: String?) {
        view.setGridColor(color)
    }
    
    @ReactProp(name = "overlayColor")
    fun setOverlayColor(view: CropperView, color: String?) {
        view.setOverlayColor(color)
    }
    
    override fun getExportedCustomDirectEventTypeConstants(): Map<String, Any>? {
        return MapBuilder.of(
            "onCropRectChange", MapBuilder.of("registrationName", "onCropRectChange"),
            "onGestureEnd", MapBuilder.of("registrationName", "onGestureEnd")
        )
    }
    
    override fun getCommandsMap(): Map<String, Int>? {
        return MapBuilder.of(
            "getCropRect", 1,
            "resetCropRect", 2,
            "setCropRect", 3
        )
    }
    
    override fun receiveCommand(view: CropperView, commandId: String, args: com.facebook.react.bridge.ReadableArray?) {
        when (commandId) {
            "getCropRect" -> view.getCurrentCropRect()
            "resetCropRect" -> view.resetCropRect()
            "setCropRect" -> {
                args?.getMap(0)?.let { view.setCropRect(it) }
            }
        }
    }
}

@SuppressLint("ClickableViewAccessibility")
class CropperView(private val context: ThemedReactContext) : View(context) {
    
    private val imageLoader = ImageLoader(context)
    private val viewScope = CoroutineScope(Dispatchers.Main)
    
    private var currentBitmap: Bitmap? = null
    private var imageRect = RectF()
    private var cropRect = RectF()
    
    // Gesture detection
    private val scaleGestureDetector: ScaleGestureDetector
    private val gestureDetector: GestureDetector
    
    // Props
    private var aspectRatio: Float? = null
    private var minCropSize = PointF(50f, 50f)
    private var showGrid = true
    private var gridColor = Color.WHITE
    private var overlayColor = Color.argb(128, 0, 0, 0)
    
    // Drawing
    private val overlayPaint = Paint().apply {
        style = Paint.Style.FILL
    }
    private val strokePaint = Paint().apply {
        style = Paint.Style.STROKE
        strokeWidth = 4f
        color = Color.WHITE
    }
    private val gridPaint = Paint().apply {
        style = Paint.Style.STROKE
        strokeWidth = 2f
        color = Color.argb(128, 255, 255, 255)
    }
    private val handlePaint = Paint().apply {
        style = Paint.Style.FILL
        color = Color.WHITE
    }
    
    // Drag state
    private var dragHandle: CropHandle = CropHandle.NONE
    private var lastTouchX = 0f
    private var lastTouchY = 0f
    private var dragStartRect = RectF()
    
    private enum class CropHandle {
        NONE, TOP_LEFT, TOP_RIGHT, BOTTOM_LEFT, BOTTOM_RIGHT,
        TOP, BOTTOM, LEFT, RIGHT, CENTER
    }
    
    init {
        setBackgroundColor(Color.BLACK)
        setWillNotDraw(false)
        
        scaleGestureDetector = ScaleGestureDetector(context, ScaleListener())
        gestureDetector = GestureDetector(context, GestureListener())
        
        setOnTouchListener { _, event ->
            var handled = scaleGestureDetector.onTouchEvent(event)
            handled = gestureDetector.onTouchEvent(event) || handled
            
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    dragHandle = getHandleAtPoint(event.x, event.y)
                    lastTouchX = event.x
                    lastTouchY = event.y
                    dragStartRect.set(cropRect)
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    if (dragHandle != CropHandle.NONE) {
                        val dx = event.x - lastTouchX
                        val dy = event.y - lastTouchY
                        updateCropRect(dx, dy)
                        lastTouchX = event.x
                        lastTouchY = event.y
                        invalidate()
                        sendCropRectChangeEvent()
                        true
                    } else {
                        handled
                    }
                }
                MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                    if (dragHandle != CropHandle.NONE) {
                        dragHandle = CropHandle.NONE
                        sendGestureEndEvent()
                    }
                    handled
                }
                else -> handled
            }
        }
    }
    
    fun setSourceUri(uri: String?) {
        if (uri.isNullOrEmpty()) return
        
        viewScope.launch {
            try {
                val bitmap = imageLoader.loadImage(uri)
                post {
                    // Recycle old bitmap on main thread to avoid race condition with drawing
                    val oldBitmap = currentBitmap
                    currentBitmap = bitmap
                    oldBitmap?.recycle()
                    
                    updateImageLayout()
                    resetCropRect()
                    invalidate()
                }
            } catch (e: Exception) {
                // Handle error
            }
        }
    }
    
    fun setInitialCropRect(rect: ReadableMap?) {
        rect?.let {
            val x = if (it.hasKey("x")) it.getDouble("x").toFloat() else 0f
            val y = if (it.hasKey("y")) it.getDouble("y").toFloat() else 0f
            val width = if (it.hasKey("width")) it.getDouble("width").toFloat() else 0f
            val height = if (it.hasKey("height")) it.getDouble("height").toFloat() else 0f
            
            cropRect.set(x, y, x + width, y + height)
            invalidate()
        }
    }
    
    fun setAspectRatio(ratio: Float?) {
        aspectRatio = ratio
    }
    
    fun setMinCropSize(size: ReadableMap?) {
        size?.let {
            val width = if (it.hasKey("width")) it.getDouble("width").toFloat() else 50f
            val height = if (it.hasKey("height")) it.getDouble("height").toFloat() else 50f
            minCropSize.set(width, height)
        }
    }
    
    fun setShowGrid(show: Boolean) {
        showGrid = show
        invalidate()
    }
    
    fun setGridColor(color: String?) {
        gridColor = parseColor(color) ?: Color.WHITE
        gridPaint.color = Color.argb(128, Color.red(gridColor), Color.green(gridColor), Color.blue(gridColor))
        invalidate()
    }
    
    fun setOverlayColor(color: String?) {
        overlayColor = parseColor(color) ?: Color.argb(128, 0, 0, 0)
        invalidate()
    }
    
    override fun onSizeChanged(w: Int, h: Int, oldw: Int, oldh: Int) {
        super.onSizeChanged(w, h, oldw, oldh)
        updateImageLayout()
        if (cropRect.isEmpty) {
            resetCropRect()
        }
    }
    
    private fun updateImageLayout() {
        val bitmap = currentBitmap
        if (bitmap == null || bitmap.isRecycled) {
            return
        }
        
        val viewWidth = width.toFloat()
        val viewHeight = height.toFloat()
        val imageWidth = bitmap.width.toFloat()
        val imageHeight = bitmap.height.toFloat()
        
        val scale = min(viewWidth / imageWidth, viewHeight / imageHeight)
        val scaledWidth = imageWidth * scale
        val scaledHeight = imageHeight * scale
        
        val left = (viewWidth - scaledWidth) / 2
        val top = (viewHeight - scaledHeight) / 2
        
        imageRect.set(left, top, left + scaledWidth, top + scaledHeight)
    }
    
    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        
        val bitmap = currentBitmap
        // Check if bitmap exists and is not recycled
        if (bitmap == null || bitmap.isRecycled) {
            return
        }
        
        // Draw image
        canvas.drawBitmap(bitmap, null, imageRect, null)
        
        // Draw overlay (darken area outside crop)
        overlayPaint.color = overlayColor
        
        val path = Path().apply {
            addRect(0f, 0f, width.toFloat(), height.toFloat(), Path.Direction.CW)
            addRect(cropRect, Path.Direction.CCW)
        }
        canvas.drawPath(path, overlayPaint)
        
        // Draw crop rect border
        canvas.drawRect(cropRect, strokePaint)
        
        // Draw grid
        if (showGrid) {
            val thirdWidth = cropRect.width() / 3
            val thirdHeight = cropRect.height() / 3
            
            // Vertical lines
            for (i in 1..2) {
                val x = cropRect.left + (thirdWidth * i)
                canvas.drawLine(x, cropRect.top, x, cropRect.bottom, gridPaint)
            }
            
            // Horizontal lines
            for (i in 1..2) {
                val y = cropRect.top + (thirdHeight * i)
                canvas.drawLine(cropRect.left, y, cropRect.right, y, gridPaint)
            }
        }
        
        // Draw corner handles
        val handleSize = 40f
        drawHandle(canvas, cropRect.left, cropRect.top, handleSize)
        drawHandle(canvas, cropRect.right - handleSize, cropRect.top, handleSize)
        drawHandle(canvas, cropRect.left, cropRect.bottom - handleSize, handleSize)
        drawHandle(canvas, cropRect.right - handleSize, cropRect.bottom - handleSize, handleSize)
    }
    
    private fun drawHandle(canvas: Canvas, x: Float, y: Float, size: Float) {
        canvas.drawRect(x, y, x + size, y + size, handlePaint)
    }
    
    private fun getHandleAtPoint(x: Float, y: Float): CropHandle {
        val touchRadius = 60f
        
        // Check corners
        if (distance(x, y, cropRect.left, cropRect.top) < touchRadius) return CropHandle.TOP_LEFT
        if (distance(x, y, cropRect.right, cropRect.top) < touchRadius) return CropHandle.TOP_RIGHT
        if (distance(x, y, cropRect.left, cropRect.bottom) < touchRadius) return CropHandle.BOTTOM_LEFT
        if (distance(x, y, cropRect.right, cropRect.bottom) < touchRadius) return CropHandle.BOTTOM_RIGHT
        
        // Check edges
        if (abs(x - cropRect.left) < touchRadius && y > cropRect.top && y < cropRect.bottom) return CropHandle.LEFT
        if (abs(x - cropRect.right) < touchRadius && y > cropRect.top && y < cropRect.bottom) return CropHandle.RIGHT
        if (abs(y - cropRect.top) < touchRadius && x > cropRect.left && x < cropRect.right) return CropHandle.TOP
        if (abs(y - cropRect.bottom) < touchRadius && x > cropRect.left && x < cropRect.right) return CropHandle.BOTTOM
        
        // Check center
        if (cropRect.contains(x, y)) return CropHandle.CENTER
        
        return CropHandle.NONE
    }
    
    private fun distance(x1: Float, y1: Float, x2: Float, y2: Float): Float {
        return kotlin.math.sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2))
    }
    
    private fun updateCropRect(dx: Float, dy: Float) {
        val newRect = RectF(cropRect)
        
        when (dragHandle) {
            CropHandle.TOP_LEFT -> {
                newRect.left += dx
                newRect.top += dy
            }
            CropHandle.TOP_RIGHT -> {
                newRect.right += dx
                newRect.top += dy
            }
            CropHandle.BOTTOM_LEFT -> {
                newRect.left += dx
                newRect.bottom += dy
            }
            CropHandle.BOTTOM_RIGHT -> {
                newRect.right += dx
                newRect.bottom += dy
            }
            CropHandle.LEFT -> newRect.left += dx
            CropHandle.RIGHT -> newRect.right += dx
            CropHandle.TOP -> newRect.top += dy
            CropHandle.BOTTOM -> newRect.bottom += dy
            CropHandle.CENTER -> {
                newRect.offset(dx, dy)
            }
            CropHandle.NONE -> return
        }
        
        // Apply aspect ratio
        aspectRatio?.let { ratio ->
            newRect.set(applyAspectRatio(newRect, ratio, dragHandle))
        }
        
        // Apply minimum size
        val width = newRect.width()
        val height = newRect.height()
        if (width < minCropSize.x) {
            if (dragHandle in listOf(CropHandle.LEFT, CropHandle.TOP_LEFT, CropHandle.BOTTOM_LEFT)) {
                newRect.left = newRect.right - minCropSize.x
            } else {
                newRect.right = newRect.left + minCropSize.x
            }
        }
        if (height < minCropSize.y) {
            if (dragHandle in listOf(CropHandle.TOP, CropHandle.TOP_LEFT, CropHandle.TOP_RIGHT)) {
                newRect.top = newRect.bottom - minCropSize.y
            } else {
                newRect.bottom = newRect.top + minCropSize.y
            }
        }
        
        // Keep within image bounds
        if (newRect.left < imageRect.left) newRect.left = imageRect.left
        if (newRect.top < imageRect.top) newRect.top = imageRect.top
        if (newRect.right > imageRect.right) newRect.right = imageRect.right
        if (newRect.bottom > imageRect.bottom) newRect.bottom = imageRect.bottom
        
        cropRect.set(newRect)
    }
    
    private fun applyAspectRatio(rect: RectF, ratio: Float, handle: CropHandle): RectF {
        val newRect = RectF(rect)
        val currentRatio = rect.width() / rect.height()
        
        when (handle) {
            CropHandle.TOP_LEFT, CropHandle.TOP_RIGHT,
            CropHandle.BOTTOM_LEFT, CropHandle.BOTTOM_RIGHT -> {
                if (currentRatio > ratio) {
                    newRect.right = newRect.left + (newRect.height() * ratio)
                } else {
                    newRect.bottom = newRect.top + (newRect.width() / ratio)
                }
            }
            CropHandle.LEFT, CropHandle.RIGHT -> {
                newRect.bottom = newRect.top + (newRect.width() / ratio)
            }
            CropHandle.TOP, CropHandle.BOTTOM -> {
                newRect.right = newRect.left + (newRect.height() * ratio)
            }
            else -> {}
        }
        
        return newRect
    }
    
    fun getCurrentCropRect(): Map<String, Any> {
        return mapOf(
            "x" to cropRect.left,
            "y" to cropRect.top,
            "width" to cropRect.width(),
            "height" to cropRect.height()
        )
    }
    
    fun resetCropRect() {
        cropRect.set(imageRect)
        invalidate()
    }
    
    fun setCropRect(rect: ReadableMap) {
        setInitialCropRect(rect)
    }
    
    private fun sendCropRectChangeEvent() {
        val event = Arguments.createMap()
        val rectMap = Arguments.createMap()
        rectMap.putDouble("x", cropRect.left.toDouble())
        rectMap.putDouble("y", cropRect.top.toDouble())
        rectMap.putDouble("width", cropRect.width().toDouble())
        rectMap.putDouble("height", cropRect.height().toDouble())
        event.putMap("cropRect", rectMap)
        
        context.getJSModule(RCTEventEmitter::class.java)
            .receiveEvent(id, "onCropRectChange", event)
    }
    
    private fun sendGestureEndEvent() {
        val event = Arguments.createMap()
        val rectMap = Arguments.createMap()
        rectMap.putDouble("x", cropRect.left.toDouble())
        rectMap.putDouble("y", cropRect.top.toDouble())
        rectMap.putDouble("width", cropRect.width().toDouble())
        rectMap.putDouble("height", cropRect.height().toDouble())
        event.putMap("cropRect", rectMap)
        
        context.getJSModule(RCTEventEmitter::class.java)
            .receiveEvent(id, "onGestureEnd", event)
    }
    
    private fun parseColor(colorString: String?): Int? {
        if (colorString == null) return null
        return try {
            Color.parseColor(colorString)
        } catch (e: Exception) {
            null
        }
    }
    
    inner class ScaleListener : ScaleGestureDetector.SimpleOnScaleGestureListener() {
        override fun onScale(detector: ScaleGestureDetector): Boolean {
            // Can add zoom functionality here if needed
            return true
        }
    }
    
    inner class GestureListener : GestureDetector.SimpleOnGestureListener() {
        override fun onDown(e: MotionEvent): Boolean {
            return true
        }
    }
    
    override fun onDetachedFromWindow() {
        super.onDetachedFromWindow()
        currentBitmap?.let { bitmap ->
            if (!bitmap.isRecycled) {
                bitmap.recycle()
            }
        }
        currentBitmap = null
    }
}

