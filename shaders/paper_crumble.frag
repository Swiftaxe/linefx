#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 uResolution;
uniform vec2 uOffset;
uniform float uIntensity;

out vec4 fragColor;

// Simple noise function for crumpling
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Fractal noise for more detail
float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    
    for (int i = 0; i < 4; i++) {
        value += amplitude * noise(p * frequency);
        frequency *= 2.0;
        amplitude *= 0.5;
    }
    
    return value;
}

void main() {
    vec2 fragCoord = FlutterFragCoord();
    vec2 uv = fragCoord / uResolution;
    
    // Base white paper color
    vec3 paperColor = vec3(0.87, 0.87, 0.87);
    
    // Calculate distance-based intensity
    float dist = length(uOffset) / (uResolution.x * 0.15);
    float crumple = uIntensity * smoothstep(0.0, 1.0, dist);
    
    // Create crumple displacement pattern
    vec2 noisePos = uv * 10.0 + uOffset * 0.01;
    float crumplePattern = fbm(noisePos);
    
    // Add shadow/depth based on crumple
    float shadow = 1.0 - crumple * 0.4 * (crumplePattern - 0.5);
    shadow = clamp(shadow, 0.5, 1.0);
    
    // Apply shadow to paper color
    vec3 finalColor = paperColor * shadow;
    
    // Slightly darken the creases
    float crease = fbm(noisePos * 2.0);
    finalColor -= crumple * 0.15 * vec3(crease - 0.5);
    
    fragColor = vec4(finalColor, 1.0);
}
