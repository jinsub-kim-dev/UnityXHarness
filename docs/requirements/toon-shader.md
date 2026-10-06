# ToonShader.shader PRD

## Overview
HLSL 파일 4개를 조립하는 URP ShaderLab 셰이더.
로직은 없고 Properties 블록과 두 Pass의 include 선언만 담는다.

## Goals
- Outline Pass와 ToonForward Pass 두 개를 하나의 SubShader로 구성한다
- CBUFFER는 ToonInput.hlsl include 체인에 위임하고 이 파일에는 작성하지 않는다

## Out of Scope
- HLSL 셰이딩 로직 (각 .hlsl 파일 담당)
- CBUFFER 선언

## Technical Requirements

### Properties
| 그룹 | 프로퍼티 | 타입 |
|---|---|---|
| Base | _BaseMap, _BaseColor | 2D, Color |
| Cel Shading | _1st_ShadeColor, _2nd_ShadeColor | Color |
| | _BaseColor_Step, _BaseShade_Feather | Range(0,1), Range(0,0.5) |
| | _ShadeColor_Step, _1st2nd_Shades_Feather | Range(0,1), Range(0,0.5) |
| Rim Light | _RimLight [Toggle], _RimLightColor | Float, Color |
| | _RimLight_Power, _RimLight_InsideMask | Range(0,1), Range(0,1) |
| | _RimLight_FeatherOff [Toggle], _LightDirection_MaskOn [Toggle] | Float |
| Outline | _Outline_Color, _Outline_Width | Color, Float |
| | _Nearest_Distance, _Farthest_Distance | Float |

### Pass 구성
- **Pass 1 "Outline"**: `LightMode = SRPDefaultUnlit`, `Cull Front`
  - include: `ToonInput.hlsl`, `Outline.hlsl`
- **Pass 2 "ToonForward"**: `LightMode = UniversalForward`, `Cull Back`
  - include: `ToonInput.hlsl`, `ToonForward.hlsl`

## Acceptance Criteria
- [ ] 이 .shader 파일 안에 CBUFFER_START 블록이 없다
- [ ] Material 인스펙터에서 SRP Batcher Compatible로 표시된다
- [ ] Outline / ToonForward 두 Pass가 모두 정상 렌더링된다
- [ ] Unity 6 URP 프로젝트에서 컴파일 오류가 없다