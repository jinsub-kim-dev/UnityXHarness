# ToonInput.hlsl PRD

## Overview
Toon 셰이더 패스 전체가 공유하는 CBUFFER·텍스처 선언 파일.
모든 패스가 이 파일 하나를 `#include` 해 Material 입력 선언을 한곳에서 관리한다.

## Goals
- CBUFFER_START(UnityPerMaterial) 를 이 파일에서만 선언한다
- TEXTURE2D(_BaseMap) / SAMPLER 선언을 포함한다
- include guard로 다중 include를 안전하게 처리한다

## Out of Scope
- 셰이딩 로직
- NormalMap, ShadingGradeMap 등 추가 텍스처

## Technical Requirements
- 의존: `Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl`
- CBUFFER 프로퍼티 목록 (프로퍼티 이름과 타입을 한 곳에서 관리하고, 최종 호환성은 Unity Inspector에서 확인)

  | 이름 | 타입 |
  |---|---|
  | _BaseMap_ST | float4 |
  | _BaseColor | float4 |
  | _1st_ShadeColor | float4 |
  | _2nd_ShadeColor | float4 |
  | _BaseColor_Step | float |
  | _BaseShade_Feather | float |
  | _ShadeColor_Step | float |
  | _1st2nd_Shades_Feather | float |
  | _RimLight | float |
  | _RimLightColor | float4 |
  | _RimLight_Power | float |
  | _RimLight_InsideMask | float |
  | _RimLight_FeatherOff | float |
  | _LightDirection_MaskOn | float |
  | _Outline_Color | float4 |
  | _Outline_Width | float |
  | _Nearest_Distance | float |
  | _Farthest_Distance | float |

## Acceptance Criteria
- [ ] 여러 번 include해도 중복 선언 오류가 없다
- [ ] ToonForward / Outline 두 Pass 모두 include 시 SRP Batcher Compatible 표시된다