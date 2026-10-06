#ifndef O2UN_TOON_FORWARD_INCLUDED
#define O2UN_TOON_FORWARD_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "ToonInput.hlsl"
#include "RimLight.hlsl"

struct ToonAttributes
{
    float4 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float2 uv : TEXCOORD0;
};

struct ToonVaryings
{
    float4 positionCS : SV_POSITION;
    float3 positionWS : TEXCOORD0;
    float3 normalWS : TEXCOORD1;
    float2 uv : TEXCOORD2;
};

float CelStep(float threshold, float feather, float value)
{
    float safeFeather = max(feather, 1e-4);
    return smoothstep(threshold - safeFeather, threshold + safeFeather, value);
}

ToonVaryings ToonVert(ToonAttributes input)
{
    ToonVaryings output;

    VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS.xyz);
    output.positionCS = positionInputs.positionCS;
    output.positionWS = positionInputs.positionWS;
    output.normalWS = TransformObjectToWorldNormal(input.normalOS);
    output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
    return output;
}

half4 ToonFrag(ToonVaryings input) : SV_Target
{
    float4 baseSample = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv) * _BaseColor;

    float3 normalWS = normalize(input.normalWS);
    float3 viewDirWS = GetWorldSpaceNormalizeViewDir(input.positionWS);
    Light mainLight = GetMainLight();

    float halfLambert = 0.5 * dot(normalWS, mainLight.direction) + 0.5;
    float baseMask = CelStep(_BaseColor_Step, _BaseShade_Feather, halfLambert);
    float shadeMask = CelStep(_ShadeColor_Step, _1st2nd_Shades_Feather, halfLambert);

    float3 baseColor = baseSample.rgb;
    float3 firstShadeColor = baseColor * _1st_ShadeColor.rgb;
    float3 secondShadeColor = baseColor * _2nd_ShadeColor.rgb;

    float3 shadeColor = lerp(secondShadeColor, firstShadeColor, shadeMask);
    float3 celColor = lerp(shadeColor, baseColor, baseMask) * mainLight.color;

    float3 rimColor = CalcRimLight(normalWS, viewDirWS, mainLight.direction);
    return half4(celColor + rimColor, baseSample.a);
}

#endif
