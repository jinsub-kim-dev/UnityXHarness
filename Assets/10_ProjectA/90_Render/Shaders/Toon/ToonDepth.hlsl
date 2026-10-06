#ifndef O2UN_TOON_DEPTH_INCLUDED
#define O2UN_TOON_DEPTH_INCLUDED

#include "ToonInput.hlsl"

struct DepthAttributes
{
    float4 positionOS : POSITION;
    float3 normalOS : NORMAL;
};

struct DepthVaryings
{
    float4 positionCS : SV_POSITION;
};

struct DepthNormalsVaryings
{
    float4 positionCS : SV_POSITION;
    float3 normalWS : TEXCOORD0;
};

DepthVaryings DepthOnlyVert(DepthAttributes input)
{
    DepthVaryings output;
    output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
    return output;
}

half DepthOnlyFrag(DepthVaryings input) : SV_Target
{
    return input.positionCS.z;
}

DepthNormalsVaryings DepthNormalsVert(DepthAttributes input)
{
    DepthNormalsVaryings output;
    output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
    output.normalWS = TransformObjectToWorldNormal(input.normalOS);
    return output;
}

half4 DepthNormalsFrag(DepthNormalsVaryings input) : SV_Target
{
    float3 normalWS = NormalizeNormalPerPixel(input.normalWS);

#if defined(_GBUFFER_NORMALS_OCT)
    float2 octNormalWS = PackNormalOctQuadEncode(normalWS);
    float2 remappedOctNormalWS = saturate(octNormalWS * 0.5 + 0.5);
    half3 packedNormalWS = PackFloat2To888(remappedOctNormalWS);
    return half4(packedNormalWS, 0.0);
#else
    return half4(normalWS, 0.0);
#endif
}

#endif
