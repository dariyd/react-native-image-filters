#include <metal_stdlib>
using namespace metal;

// MARK: - Helper Functions

float luminance(float4 color) {
    return dot(color.rgb, float3(0.299, 0.587, 0.114));
}

float3 adjustTemperature(float3 color, float temp) {
    // temp range: -1 to 1
    float3 warm = float3(1.0 + temp * 0.2, 1.0, 1.0 - temp * 0.2);
    return color * warm;
}

float3 adjustTint(float3 color, float tint) {
    // tint range: -1 to 1
    float3 tintColor = float3(1.0 - abs(tint) * 0.2, 1.0, 1.0 - abs(tint) * 0.2);
    if (tint > 0) {
        tintColor = float3(1.0, 1.0 - tint * 0.2, 1.0);
    }
    return color * tintColor;
}

// MARK: - Sepia Filter

kernel void sepiaFilter(
    texture2d<float, access::read> inTexture [[texture(0)]],
    texture2d<float, access::write> outTexture [[texture(1)]],
    constant float &intensity [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]]
) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }
    
    float4 color = inTexture.read(gid);
    
    // Sepia matrix
    float3 sepia;
    sepia.r = dot(color.rgb, float3(0.393, 0.769, 0.189));
    sepia.g = dot(color.rgb, float3(0.349, 0.686, 0.168));
    sepia.b = dot(color.rgb, float3(0.272, 0.534, 0.131));
    
    sepia = clamp(sepia, 0.0, 1.0);
    
    float4 outputColor = mix(color, float4(sepia, color.a), intensity);
    outTexture.write(outputColor, gid);
}

// MARK: - Vivid Filter

kernel void vividFilter(
    texture2d<float, access::read> inTexture [[texture(0)]],
    texture2d<float, access::write> outTexture [[texture(1)]],
    constant float &intensity [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]]
) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }
    
    float4 color = inTexture.read(gid);
    
    // Increase saturation and contrast
    float lum = luminance(color);
    float3 vivid = mix(float3(lum), color.rgb, 1.5); // Saturation boost
    vivid = (vivid - 0.5) * 1.2 + 0.5; // Contrast boost
    
    vivid = clamp(vivid, 0.0, 1.0);
    
    float4 outputColor = mix(color, float4(vivid, color.a), intensity);
    outTexture.write(outputColor, gid);
}

// MARK: - Dramatic Filter

kernel void dramaticFilter(
    texture2d<float, access::read> inTexture [[texture(0)]],
    texture2d<float, access::write> outTexture [[texture(1)]],
    constant float &intensity [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]]
) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }
    
    float4 color = inTexture.read(gid);
    
    // High contrast, slightly desaturated
    float lum = luminance(color);
    float3 dramatic = mix(float3(lum), color.rgb, 0.8); // Slight desaturation
    dramatic = (dramatic - 0.5) * 1.5 + 0.5; // Strong contrast
    
    // Crush blacks and highlights
    dramatic = pow(dramatic, float3(0.9));
    
    dramatic = clamp(dramatic, 0.0, 1.0);
    
    float4 outputColor = mix(color, float4(dramatic, color.a), intensity);
    outTexture.write(outputColor, gid);
}

// MARK: - Warm Filter

kernel void warmFilter(
    texture2d<float, access::read> inTexture [[texture(0)]],
    texture2d<float, access::write> outTexture [[texture(1)]],
    constant float &intensity [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]]
) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }
    
    float4 color = inTexture.read(gid);
    
    // Add warm temperature
    float3 warm = adjustTemperature(color.rgb, 0.3);
    warm = mix(warm, warm * 1.05, 0.5); // Slight brightness boost
    
    warm = clamp(warm, 0.0, 1.0);
    
    float4 outputColor = mix(color, float4(warm, color.a), intensity);
    outTexture.write(outputColor, gid);
}

// MARK: - Cool Filter

kernel void coolFilter(
    texture2d<float, access::read> inTexture [[texture(0)]],
    texture2d<float, access::write> outTexture [[texture(1)]],
    constant float &intensity [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]]
) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }
    
    float4 color = inTexture.read(gid);
    
    // Add cool temperature
    float3 cool = adjustTemperature(color.rgb, -0.3);
    cool = mix(cool, cool * 0.95, 0.3); // Slight darkness
    
    cool = clamp(cool, 0.0, 1.0);
    
    float4 outputColor = mix(color, float4(cool, color.a), intensity);
    outTexture.write(outputColor, gid);
}

// MARK: - Vintage Filter

kernel void vintageFilter(
    texture2d<float, access::read> inTexture [[texture(0)]],
    texture2d<float, access::write> outTexture [[texture(1)]],
    constant float &intensity [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]]
) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }
    
    float4 color = inTexture.read(gid);
    
    // Vintage look: faded, warm, slight sepia
    float lum = luminance(color);
    float3 vintage = color.rgb * 0.9 + 0.05; // Fade
    vintage = adjustTemperature(vintage, 0.2); // Warm
    
    // Slight sepia tint
    float3 sepia;
    sepia.r = dot(vintage, float3(0.393, 0.769, 0.189));
    sepia.g = dot(vintage, float3(0.349, 0.686, 0.168));
    sepia.b = dot(vintage, float3(0.272, 0.534, 0.131));
    
    vintage = mix(vintage, sepia, 0.3);
    
    vintage = clamp(vintage, 0.0, 1.0);
    
    float4 outputColor = mix(color, float4(vintage, color.a), intensity);
    outTexture.write(outputColor, gid);
}

// MARK: - Fade Filter

kernel void fadeFilter(
    texture2d<float, access::read> inTexture [[texture(0)]],
    texture2d<float, access::write> outTexture [[texture(1)]],
    constant float &intensity [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]]
) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }
    
    float4 color = inTexture.read(gid);
    
    // Washed out, faded look
    float3 faded = color.rgb * 0.85 + 0.15; // Lift shadows
    faded = mix(faded, float3(0.5), 0.2); // Reduce contrast
    
    faded = clamp(faded, 0.0, 1.0);
    
    float4 outputColor = mix(color, float4(faded, color.a), intensity);
    outTexture.write(outputColor, gid);
}

// MARK: - Chrome Filter

kernel void chromeFilter(
    texture2d<float, access::read> inTexture [[texture(0)]],
    texture2d<float, access::write> outTexture [[texture(1)]],
    constant float &intensity [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]]
) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }
    
    float4 color = inTexture.read(gid);
    
    // Metallic, high contrast
    float lum = luminance(color);
    float3 chrome = mix(float3(lum), color.rgb, 0.7); // Desaturate
    chrome = (chrome - 0.5) * 1.4 + 0.5; // High contrast
    
    chrome = clamp(chrome, 0.0, 1.0);
    
    float4 outputColor = mix(color, float4(chrome, color.a), intensity);
    outTexture.write(outputColor, gid);
}

// MARK: - Custom Parameters Filter

kernel void customFilter(
    texture2d<float, access::read> inTexture [[texture(0)]],
    texture2d<float, access::write> outTexture [[texture(1)]],
    constant float4 &params [[buffer(0)]],  // brightness, contrast, saturation, exposure
    constant float4 &params2 [[buffer(1)]], // temperature, tint, vibrance, intensity
    uint2 gid [[thread_position_in_grid]]
) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }
    
    float brightness = params.x;
    float contrast = params.y;
    float saturation = params.z;
    float exposure = params.w;
    
    float temperature = params2.x;
    float tint = params2.y;
    float vibrance = params2.z;
    float intensity = params2.w;
    
    float4 color = inTexture.read(gid);
    
    // Apply exposure
    float3 adjusted = color.rgb * exposure;
    
    // Apply brightness
    adjusted = adjusted * brightness;
    
    // Apply contrast
    adjusted = (adjusted - 0.5) * contrast + 0.5;
    
    // Apply temperature
    if (temperature != 0.0) {
        adjusted = adjustTemperature(adjusted, temperature);
    }
    
    // Apply tint
    if (tint != 0.0) {
        adjusted = adjustTint(adjusted, tint);
    }
    
    // Apply saturation
    float lum = luminance(float4(adjusted, 1.0));
    adjusted = mix(float3(lum), adjusted, saturation);
    
    // Apply vibrance (selective saturation)
    if (vibrance != 1.0) {
        float currentSat = length(adjusted - float3(lum));
        float vibranceBoost = (1.0 - currentSat) * (vibrance - 1.0);
        adjusted = mix(float3(lum), adjusted, 1.0 + vibranceBoost);
    }
    
    adjusted = clamp(adjusted, 0.0, 1.0);
    
    float4 outputColor = mix(color, float4(adjusted, color.a), intensity);
    outTexture.write(outputColor, gid);
}

