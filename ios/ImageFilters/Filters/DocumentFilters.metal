#include <metal_stdlib>
using namespace metal;

// MARK: - Helper Functions

float luminance(float4 color) {
    return dot(color.rgb, float3(0.299, 0.587, 0.114));
}

float adaptiveThreshold(float value, float threshold, float contrast) {
    float adjusted = (value - threshold) * contrast + 0.5;
    return clamp(adjusted, 0.0, 1.0);
}

// MARK: - Document Scan Filter

kernel void scanFilter(
    texture2d<float, access::read> inTexture [[texture(0)]],
    texture2d<float, access::write> outTexture [[texture(1)]],
    constant float4 &params [[buffer(0)]],  // threshold, contrast, sharpness, intensity
    uint2 gid [[thread_position_in_grid]]
) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }
    
    float threshold = params.x;
    float contrast = params.y;
    float sharpness = params.z;
    float intensity = params.w;
    
    // Read input color
    float4 color = inTexture.read(gid);
    
    // Convert to grayscale
    float gray = luminance(color);
    
    // Apply adaptive threshold
    float thresholded = adaptiveThreshold(gray, threshold, contrast);
    
    // Apply sharpness (simple edge enhancement)
    if (sharpness > 1.0) {
        float sum = 0.0;
        int kernelSize = 3;
        int halfSize = kernelSize / 2;
        
        for (int dy = -halfSize; dy <= halfSize; dy++) {
            for (int dx = -halfSize; dx <= halfSize; dx++) {
                uint2 samplePos = uint2(int2(gid) + int2(dx, dy));
                if (samplePos.x < inTexture.get_width() && samplePos.y < inTexture.get_height()) {
                    float4 sampleColor = inTexture.read(samplePos);
                    float sampleGray = luminance(sampleColor);
                    sum += sampleGray;
                }
            }
        }
        
        float avg = sum / float(kernelSize * kernelSize);
        float edge = gray - avg;
        thresholded += edge * (sharpness - 1.0);
        thresholded = clamp(thresholded, 0.0, 1.0);
    }
    
    // Mix with original based on intensity
    float4 outputColor = mix(color, float4(thresholded, thresholded, thresholded, color.a), intensity);
    
    outTexture.write(outputColor, gid);
}

// MARK: - Black & White Filter

kernel void blackWhiteFilter(
    texture2d<float, access::read> inTexture [[texture(0)]],
    texture2d<float, access::write> outTexture [[texture(1)]],
    constant float4 &params [[buffer(0)]],  // threshold, contrast, noiseReduction, intensity
    uint2 gid [[thread_position_in_grid]]
) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }
    
    float threshold = params.x;
    float contrast = params.y;
    float intensity = params.w;
    
    // Read input color
    float4 color = inTexture.read(gid);
    
    // Convert to grayscale with high contrast
    float gray = luminance(color);
    
    // Apply threshold
    float bw = gray > threshold ? 1.0 : 0.0;
    
    // Smooth transition around threshold for better quality
    float smoothWidth = 0.05;
    bw = smoothstep(threshold - smoothWidth, threshold + smoothWidth, gray);
    
    // Apply contrast
    bw = (bw - 0.5) * contrast + 0.5;
    bw = clamp(bw, 0.0, 1.0);
    
    // Mix with original
    float4 outputColor = mix(color, float4(bw, bw, bw, color.a), intensity);
    
    outTexture.write(outputColor, gid);
}

// MARK: - Enhance Filter

kernel void enhanceFilter(
    texture2d<float, access::read> inTexture [[texture(0)]],
    texture2d<float, access::write> outTexture [[texture(1)]],
    constant float4 &params [[buffer(0)]],  // brightness, contrast, saturation, intensity
    uint2 gid [[thread_position_in_grid]]
) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }
    
    float brightness = params.x;
    float contrast = params.y;
    float saturation = params.z;
    float intensity = params.w;
    
    // Read input color
    float4 color = inTexture.read(gid);
    
    // Apply brightness
    float3 enhanced = color.rgb * brightness;
    
    // Apply contrast
    enhanced = (enhanced - 0.5) * contrast + 0.5;
    
    // Apply saturation
    float gray = luminance(float4(enhanced, 1.0));
    enhanced = mix(float3(gray), enhanced, saturation);
    
    // Clamp values
    enhanced = clamp(enhanced, 0.0, 1.0);
    
    // Mix with original
    float4 outputColor = mix(color, float4(enhanced, color.a), intensity);
    
    outTexture.write(outputColor, gid);
}

// MARK: - Grayscale Filter

kernel void grayscaleFilter(
    texture2d<float, access::read> inTexture [[texture(0)]],
    texture2d<float, access::write> outTexture [[texture(1)]],
    constant float &intensity [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]]
) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }
    
    // Read input color
    float4 color = inTexture.read(gid);
    
    // Convert to grayscale
    float gray = luminance(color);
    
    // Mix with original based on intensity
    float4 outputColor = mix(color, float4(gray, gray, gray, color.a), intensity);
    
    outTexture.write(outputColor, gid);
}

// MARK: - Color Pop Filter

kernel void colorPopFilter(
    texture2d<float, access::read> inTexture [[texture(0)]],
    texture2d<float, access::write> outTexture [[texture(1)]],
    constant float4 &params [[buffer(0)]],  // saturation, vibrance, clarity, intensity
    uint2 gid [[thread_position_in_grid]]
) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }
    
    float saturation = params.x;
    float vibrance = params.y;
    float intensity = params.w;
    
    // Read input color
    float4 color = inTexture.read(gid);
    
    // Calculate luminance
    float lum = luminance(color);
    
    // Apply saturation
    float3 enhanced = mix(float3(lum), color.rgb, saturation);
    
    // Apply vibrance (selective saturation boost for less saturated colors)
    float currentSaturation = length(enhanced - float3(lum));
    float vibranceBoost = (1.0 - currentSaturation) * (vibrance - 1.0);
    enhanced = mix(float3(lum), enhanced, 1.0 + vibranceBoost);
    
    // Slight contrast boost for clarity
    enhanced = (enhanced - 0.5) * 1.1 + 0.5;
    
    // Clamp values
    enhanced = clamp(enhanced, 0.0, 1.0);
    
    // Mix with original
    float4 outputColor = mix(color, float4(enhanced, color.a), intensity);
    
    outTexture.write(outputColor, gid);
}

// MARK: - Edge Detection Helper (for future use)

kernel void detectEdges(
    texture2d<float, access::read> inTexture [[texture(0)]],
    texture2d<float, access::write> outTexture [[texture(1)]],
    constant float &threshold [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]]
) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }
    
    // Sobel operator for edge detection
    float3 sobelX = float3(-1, 0, 1);
    float3 sobelY = float3(-1, 0, 1);
    
    float edgeX = 0.0;
    float edgeY = 0.0;
    
    for (int dy = -1; dy <= 1; dy++) {
        for (int dx = -1; dx <= 1; dx++) {
            uint2 samplePos = uint2(int2(gid) + int2(dx, dy));
            if (samplePos.x < inTexture.get_width() && samplePos.y < inTexture.get_height()) {
                float4 sampleColor = inTexture.read(samplePos);
                float gray = luminance(sampleColor);
                
                int idx = (dy + 1) * 3 + (dx + 1);
                float weightX = sobelX[abs(dx)] * (dy == 0 ? 2.0 : 1.0) * (dx < 0 ? -1.0 : 1.0);
                float weightY = sobelY[abs(dy)] * (dx == 0 ? 2.0 : 1.0) * (dy < 0 ? -1.0 : 1.0);
                
                edgeX += gray * weightX;
                edgeY += gray * weightY;
            }
        }
    }
    
    float edge = sqrt(edgeX * edgeX + edgeY * edgeY);
    edge = edge > threshold ? 1.0 : 0.0;
    
    outTexture.write(float4(edge, edge, edge, 1.0), gid);
}

