# Outline.hlsl PRD

## Overview
Cull Front 패스용 아웃라인 vert/frag 함수.
ToonInput.hlsl을 include해 CBUFFER를 공유한다.

## Goals
- `OutlineVert` / `OutlineFrag` 함수를 작성한다
- 카메라 거리에 따라 아웃라인 두께를 자동 스케일한다

## Out of Scope
- CBUFFER 선언 (ToonInput.hlsl 담당)
- Baked Normal Texture

## Technical Requirements
- 의존: `ToonInput.hlsl`
- 거리 기준: 버텍스별이 아닌 **오브젝트 피벗** 기준으로 계산해 물체 안에서 거리 보정 기준이 흔들리지 않게 한다
- 거리 스케일: `_Nearest_Distance` 이하에서 최대 두께, `_Farthest_Distance` 이상에서 두께 0

## Acceptance Criteria
- [ ] 카메라가 Farthest_Distance 이상이면 아웃라인이 보이지 않는다
- [ ] 거리 보정 기준이 오브젝트 피벗으로 일관되게 적용된다