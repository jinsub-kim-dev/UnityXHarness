# 02. 검증 (4단계 게이트)

작성: unity-ai-operator + Orchestrator
일시: 2026-05-28 14:25 ~ 14:52
대상: `Assets/Scripts/Player/PlayerController.cs`, `Assets/Scripts/Player/GroundChecker.cs`

## 게이트 진행 요약
| 단계 | 결과 | 시간 |
| --- | --- | --- |
| 1. 컴파일 | ✅ 통과 | 14:27 |
| 2. 런타임 에러 | ✅ 통과 | 14:32 |
| 3. 기능 점검 (자동) | ❌ 실패 → 수정 → ✅ 재통과 | 14:38 / 14:48 |
| 4. 기능 점검 (사용자) | ⏳ 대기 (hooks 뷰어에서 제출 예정) | - |

---

## 1단계: 컴파일
- 도구: Unity AI MCP `validate_script`
- 대상: `PlayerController.cs`, `GroundChecker.cs`
- 결과: **통과**. 컴파일 에러 0, 경고 0.

## 2단계: 런타임 에러
- 방법: Play 모드 진입, 콘솔 5초 관찰
- 결과: **통과**. `Debug.LogError` 없음, Exception 없음.

## 3단계: 기능 점검 (Unity AI 자동)
### 1차 시도 (14:38) — 실패
| 항목 | 기대 | 실제 |
| --- | --- | --- |
| A·D 키 → 좌우 이동 | velocity.x 변동 | ✅ 통과 |
| Space → 점프 | 지면에서 1회 점프 | ❌ **공중에서도 점프됨 (무한 점프)** |
| 지면 체크 | grounded 상태가 점프 후 false | ⚠ `IsGrounded` 갱신은 동작하나 `PlayerController`가 미참조 |

원인 (debugger 분석):
- `PlayerController.FixedUpdate`에서 `groundChecker.IsGrounded` 조건 누락. 점프 요청 플래그만 보고 즉시 `velocity.y` 적용.

### 수정 (14:45)
- 변경: `Assets/Scripts/Player/PlayerController.cs`
  ```csharp
  // FixedUpdate 내
  if (jumpRequested && groundChecker.IsGrounded)
  {
      rb.velocity = new Vector2(rb.velocity.x, jumpForce);
  }
  jumpRequested = false;
  ```
- 1단계·2단계 재검증: 통과.

### 2차 시도 (14:48) — 통과
| 항목 | 결과 |
| --- | --- |
| 좌우 이동 | ✅ |
| 지면에서 점프 | ✅ |
| 공중 점프 차단 | ✅ |
| 착지 후 다시 점프 | ✅ |

## 4단계: 기능 점검 (사용자)
- 자동 단계가 모두 통과했으므로 hooks 뷰어가 결과 HTML을 열고 사용자 입력을 대기 중.
- 사용자가 직접 플레이 모드에서 확인 후 hooks 뷰어에서 submit하면 `artifacts/04-user-feedback.md`로 저장됨.
