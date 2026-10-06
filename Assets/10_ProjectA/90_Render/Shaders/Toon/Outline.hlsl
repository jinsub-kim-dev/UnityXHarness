#ifndef O2UN_TOON_OUTLINE_INCLUDED
#define O2UN_TOON_OUTLINE_INCLUDED

#include "ToonInput.hlsl"

#define OUTLINE_WIDTH_SCALE 0.01

struct OutlineAttributes
{
    float4 positionOS : POSITION;
    float3 normalOS : NORMAL;
};

struct OutlineVaryings
{
    float4 positionCS : SV_POSITION;
};

OutlineVaryings OutlineVert(OutlineAttributes input)
{
    OutlineVaryings output;

    float3 pivotWS = TransformObjectToWorld(float3(0.0, 0.0, 0.0));
    float cameraDistance = distance(pivotWS, GetCameraPositionWS());
    float distanceRange = max(_Farthest_Distance - _Nearest_Distance, 1e-4);
    float distanceScale = 1.0 - saturate((cameraDistance - _Nearest_Distance) / distanceRange);

    float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
    float3 normalWS = TransformObjectToWorldNormal(input.normalOS);
    positionWS += normalWS * (_Outline_Width * OUTLINE_WIDTH_SCALE * distanceScale);

    output.positionCS = TransformWorldToHClip(positionWS);
    return output;
}

half4 OutlineFrag(OutlineVaryings input) : SV_Target
{
    return half4(_Outline_Color.rgb, 1.0);
}

#endif
