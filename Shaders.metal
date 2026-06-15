//
//  Shaders.metal
//  MetalFirebaseApp
//
//  Created by Takayuki Sakamoto on 2026/05/25.
//

#include <metal_stdlib>
using namespace metal;


struct VertexOut {
    float4 position [[position]];
    float2 uv;
};


struct AspectUniforms {
    float aspectScale;
};

vertex VertexOut vertexShader(
    uint vertexID [[vertex_id]],
    constant AspectUniforms& uniforms [[buffer(0)]]
) {
    
    // float x = 1.0 * uniforms.aspectScale;
    
    float4 positions[4] = {
        float4(-1.0, -1.0, 0.0, 1.0),
        float4( 1.0, -1.0, 0.0, 1.0),
        float4(-1.0,  1.0, 0.0, 1.0),
        float4( 1.0,  1.0, 0.0, 1.0)
    };
    
    float2 texCoords[4] = {
        float2(0.0, 1.0),
        float2(1.0, 1.0),
        float2(0.0, 0.0),
        float2(1.0, 0.0)
    };
     
    VertexOut out;
    
    out.position = positions[vertexID];
    out.uv = texCoords[vertexID];
    
    out.position.x *= uniforms.aspectScale;
    
    
    return out;
    
}

fragment float4 fragmentShader(
    VertexOut in [[stage_in]],
    texture2d<float> texture [[texture(0)]]
) {
    
    constexpr sampler s(address::clamp_to_edge,
                        filter::linear);
    
    return texture.sample(s, in.uv);
}
    
fragment float4 invertFragmentShader(
    VertexOut in [[stage_in]],
    texture2d<float> texture [[texture(0)]]
) {
    
    constexpr sampler textureSampler;
    
    float4 color =
    texture.sample(textureSampler, in.uv);
 
    float3 inverted =
    float3(
           1.0 - color.r,
           1.0 - color.g,
           1.0 - color.b
           );
    
    inverted *= 1.1;
    inverted = saturate(inverted);

    return float4(inverted, color.a);
}

fragment float4 monoFragmentShader(VertexOut in [[stage_in]],
                                   texture2d<float> texture [[texture(0)]]) {
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    
    float4 color = texture.sample(s, in.uv);
    
    float gray = dot(
        color.rgb,
        float3(0.299, 0.587, 0.144)
    );
    
    return float4(gray, gray, gray, color.a);
}


fragment float4 sepiaFragmentShader(VertexOut in [[stage_in]],
                                    texture2d<float> texture [[texture(0)]]) {
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    
    float4 color = texture.sample(s, in.uv);
    
    float r = dot(color.rgb, float3(0.393, 0.769, 0.189));
    float g = dot(color.rgb, float3(0.349, 0.686, 0.168));
    float b = dot(color.rgb, float3(0.272, 0.534, 0.131));
    
    return float4(r, g, b, 1.0);
}
