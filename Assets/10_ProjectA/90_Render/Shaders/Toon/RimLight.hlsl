#ifndef O2UN_TOON_RIM_LIGHT_INCLUDED
#define O2UN_TOON_RIM_LIGHT_INCLUDED

#include "ToonInput.hlsl"

float3 CalcRimLight(float3 normalWS, float3 viewDirWS, float3 lightDirWS)
{
    float fresnel = 1.0 - saturate(dot(normalWS, viewDirWS));
    float rimArea = pow(fresnel, exp2(lerp(0.0, 3.0, _RimLight_Power)));

    float softMask = saturate((rimArea - _RimLight_InsideMask) / max(1.0 - _RimLight_InsideMask, 1e-4));
    float hardMask = step(_RimLight_InsideMask, rimArea);
    float rimMask = lerp(softMask, hardMask, _RimLight_FeatherOff);

    float halfLambert = 0.5 * dot(normalWS, lightDirWS) + 0.5;
    rimMask = lerp(rimMask, saturate(rimMask - halfLambert), _LightDirection_MaskOn);

    return _RimLightColor.rgb * rimMask * _RimLight;
}

#endif
