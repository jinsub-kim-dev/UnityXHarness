# ToonForward.hlsl PRD

## Overview
Toon 셰이더 메인 패스의 vert/frag 함수.
ToonInput.hlsl(CBUFFER)과 RimLight.hlsl(림 함수)을 include하고
Cel Shading + Rim Light를 합산한 색상을 출력한다.

## Goals
- `ToonVert` / `ToonFrag` 함수를 작성한다
- dot(N, L)을 smoothstep 두 번으로 Base / 1st Shade / 2nd Shade 세 단계로 분리한다
- Shade 색상은 베이스 텍스처를 대체하지 않고 곱해서 색조를 유지한다
- CalcRimLight 결과를 Cel Shading 색상에 더해 최종 출력한다

## Out of Scope
- CBUFFER 선언 (ToonInput.hlsl 담당)
- 림 라이트 계산 세부 (RimLight.hlsl 담당)
- NormalMap, ShadingGradeMap, 추가 광원

## Technical Requirements
- 의존: `Lighting.hlsl`, `ToonInput.hlsl`, `RimLight.hlsl`
- Varyings: positionCS, positionWS, normalWS, uv
- 광원: `GetMainLight()` 단일 방향광
- Shade 색상 합성: `baseColor * shadeColor` (replace 아닌 tint)

## Acceptance Criteria
- [ ] 메인 Directional Light 방향에 따라 3단계 셀 셰이딩이 나타난다
- [ ] `_BaseShade_Feather` 를 낮추면 경계가 선명해진다
- [ ] 컬러 텍스처 적용 시 Shade 영역에서 텍스처 색조가 유지된다
- [ ] `_RimLight = 0` 이면 림 기여가 없다