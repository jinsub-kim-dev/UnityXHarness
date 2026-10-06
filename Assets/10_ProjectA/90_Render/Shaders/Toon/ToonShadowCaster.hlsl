#ifndef O2UN_TOON_SHADOW_CASTER_INCLUDED
#define O2UN_TOON_SHADOW_CASTER_INCLUDED

#include "ToonInput.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

float3 _LightDirection;
float3 _LightPosition;

struct ShadowAttributes
{
    float4 positionOS : POSITION;
    float3 normalOS : NORMAL;
};

struct ShadowVaryings
{
    float4 positionCS : SV_POSITION;
};

ShadowVaryings ShadowVert(ShadowAttributes input)
{
    ShadowVaryings output;

    float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
    float3 normalWS = TransformObjectToWorldNormal(input.normalOS);

#if _CASTING_PUNCTUAL_LIGHT_SHADOW
    float3 lightDirectionWS = normalize(_LightPosition - positionWS);
#else
    float3 lightDirectionWS = _LightDirection;
#endif

    float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, lightDirectionWS));

#if UNITY_REVERSED_Z
    positionCS.z = min(positionCS.z, UNITY_NEAR_CLIP_VALUE);
#else
    positionCS.z = max(positionCS.z, UNITY_NEAR_CLIP_VALUE);
#endif

    output.positionCS = positionCS;
    return output;
}

half4 ShadowFrag(ShadowVaryings input) : SV_Target
{
    return 0;
}

#endif
