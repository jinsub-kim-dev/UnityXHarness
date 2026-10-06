#ifndef O2UN_TOON_INPUT_INCLUDED
#define O2UN_TOON_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

TEXTURE2D(_BaseMap);
SAMPLER(sampler_BaseMap);

CBUFFER_START(UnityPerMaterial)
    float4 _BaseMap_ST;
    float4 _BaseColor;
    float4 _1st_ShadeColor;
    float4 _2nd_ShadeColor;
    float _BaseColor_Step;
    float _BaseShade_Feather;
    float _ShadeColor_Step;
    float _1st2nd_Shades_Feather;
    float _RimLight;
    float4 _RimLightColor;
    float _RimLight_Power;
    float _RimLight_InsideMask;
    float _RimLight_FeatherOff;
    float _LightDirection_MaskOn;
    float4 _Outline_Color;
    float _Outline_Width;
    float _Nearest_Distance;
    float _Farthest_Distance;
CBUFFER_END

#endif
