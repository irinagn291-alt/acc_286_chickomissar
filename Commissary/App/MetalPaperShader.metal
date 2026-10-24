#include <metal_stdlib>
using namespace metal;

/// Paper grain for the one home hero plate. Stitchable color effect.
[[ stitchable ]] half4 paperGrain(float2 position, half4 currentColor, float time) {
    float n = fract(sin(dot(position, float2(12.9898, 78.233)) + time * 0.15) * 43758.5453);
    half shade = half(0.975 + n * 0.025);
    return half4(currentColor.rgb * shade, currentColor.a);
}
