# RimLight.hlsl PRD

## Overview
림 라이트 기여값을 계산하는 헬퍼 함수 파일.
CBUFFER 선언 없이 순수 함수만 담고 ToonForward.hlsl에 include된다.

## Goals
- `CalcRimLight(normalWS, viewDirWS, lightDirWS) → float3` 단일 함수를 제공한다
- Toggle 프로퍼티 분기를 lerp/step으로만 처리해 GPU 동적 분기를 없앤다

## Out of Scope
- CBUFFER 선언 (ToonInput.hlsl 담당)
- Antipodean Rim, RimLightMask 텍스처, 복수 림 라이트

## Technical Requirements
- `_RimLight_Power` 가 높을수록 림 영역이 좁고 선명해야 한다
- `_RimLight_InsideMask` 로 안쪽 번짐을 잘라낼 수 있어야 한다
- `_RimLight_FeatherOff` 가 1이면 하드 엣지, 0이면 소프트 엣지
- `_LightDirection_MaskOn` 이 1이면 주광 방향 윤곽에서 림이 억제되어야 한다
- if/else 또는 삼항 연산자(`?:`) 런타임 분기 없이 구현한다

## Acceptance Criteria
- [ ] `_RimLight = 0` 이면 반환값이 (0,0,0)이다
- [ ] `_RimLight_FeatherOff = 1` 이면 InsideMask 경계에서 하드 스텝 처리된다
- [ ] `_LightDirection_MaskOn = 1` 이면 주광 방향 윤곽에서 림이 사라진다
- [ ] 함수 내에 동적 분기가 없다