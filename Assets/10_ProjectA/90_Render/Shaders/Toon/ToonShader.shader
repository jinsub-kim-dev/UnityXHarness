Shader "O2un/ProjectA/Toon"
{
    Properties
    {
        [Header(Base)]
        [MainTexture] _BaseMap ("Base Map", 2D) = "white" {}
        [MainColor] _BaseColor ("Base Color", Color) = (1, 1, 1, 1)

        [Header(Blending)]
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("Src Blend", Float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Dst Blend", Float) = 0
        [Enum(Off, 0, On, 1)] _ZWrite ("ZWrite", Float) = 1

        [Header(Cel Shading)]
        _1st_ShadeColor ("1st Shade Color", Color) = (0.75, 0.75, 0.85, 1)
        _2nd_ShadeColor ("2nd Shade Color", Color) = (0.5, 0.5, 0.62, 1)
        _BaseColor_Step ("Base Color Step", Range(0, 1)) = 0.5
        _BaseShade_Feather ("Base / Shade Feather", Range(0, 0.5)) = 0.02
        _ShadeColor_Step ("Shade Color Step", Range(0, 1)) = 0.25
        _1st2nd_Shades_Feather ("1st / 2nd Shades Feather", Range(0, 0.5)) = 0.02

        [Header(Rim Light)]
        [ToggleUI] _RimLight ("Rim Light", Float) = 0
        _RimLightColor ("Rim Light Color", Color) = (1, 1, 1, 1)
        _RimLight_Power ("Rim Light Power", Range(0, 1)) = 0.3
        _RimLight_InsideMask ("Rim Light Inside Mask", Range(0, 1)) = 0.0
        [ToggleUI] _RimLight_FeatherOff ("Rim Light Feather Off", Float) = 0
        [ToggleUI] _LightDirection_MaskOn ("Light Direction Mask On", Float) = 0

        [Header(Outline)]
        _Outline_Color ("Outline Color", Color) = (0.1, 0.1, 0.1, 1)
        _Outline_Width ("Outline Width", Float) = 1
        _Nearest_Distance ("Nearest Distance", Float) = 0.5
        _Farthest_Distance ("Farthest Distance", Float) = 100
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
            "Queue" = "Geometry"
        }

        Pass
        {
            Name "Outline"
            Tags { "LightMode" = "SRPDefaultUnlit" }
            Cull Front

            HLSLPROGRAM
            #pragma vertex OutlineVert
            #pragma fragment OutlineFrag

            #include "ToonInput.hlsl"
            #include "Outline.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "ToonForward"
            Tags { "LightMode" = "UniversalForward" }
            Cull Back
            Blend [_SrcBlend] [_DstBlend]
            ZWrite [_ZWrite]

            HLSLPROGRAM
            #pragma vertex ToonVert
            #pragma fragment ToonFrag

            #include "ToonInput.hlsl"
            #include "ToonForward.hlsl"
            ENDHLSL
        }
    }

    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}
