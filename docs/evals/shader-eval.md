# Shader Eval Checklist — URP Toon Shader

> 이 파일은 URP 툰셰이딩 셰이더의 코드 품질을 검토할 때 사용하는 Eval 기준서입니다.
> 각 항목을 **Pass / Warn / Fail** 로 표시하고 이유를 한 줄로 기록합니다.

---

## 1. 성능 (Performance)

| # | 항목 | 판정 기준 |
|---|---|---|
| P-01 | Vertex Shader 내 per-object 상수 반복 계산 | draw call당 한 번이면 되는 계산이 vertex마다 반복되면 Warn |
| P-02 | `distance()` / `length()` 사용 | 비교 목적이면 dot() 제곱 비교로 대체 가능 여부 확인. sqrt가 불필요하면 Warn |
| P-03 | Fragment Shader 내 uniform 기반 반복 계산 | uniform 값으로 결정되는 계산이 per-fragment로 돌아가면 Warn |

---

## 2. 플랫폼 호환성 (Compatibility)

| # | 항목 | 판정 기준 |
|---|---|---|
| C-01 | `ShadowCaster` pass 존재 여부 | 없으면 Fail — 다른 오브젝트에 그림자 드리우지 못함 |
| C-02 | `DepthOnly` pass 존재 여부 | 없으면 Fail — SSAO · Depth Priming 미지원 |
| C-03 | 추가 조명 처리 (ForwardAdd / additional lights) | 포인트·스팟 라이트 적용 안 되면 Warn |
| C-04 | URP 전용 여부 | HDRP · Built-in RP 미지원이면 Warn (프로젝트 파이프라인 고정 시 Pass) |

---

## 3. 파라미터 노출 (Properties)

| # | 항목 | 판정 기준 |
|---|---|---|
| PR-01 | 수치 파라미터의 `Range()` 지정 여부 | Float로 선언된 슬라이더가 음수·비정상값을 허용하면 Warn |
| PR-02 | 관련 파라미터 `[Header()]` 그룹화 | 그룹화 없으면 Warn |
| PR-03 | Boolean 파라미터 `[Toggle]` 사용 여부 | Float로 0/1을 표현하면 Warn |