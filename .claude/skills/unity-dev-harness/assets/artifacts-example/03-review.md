# 03. 리뷰

작성: code-reviewer
일시: 2026-05-28 14:51
대상: `Assets/Scripts/Player/PlayerController.cs`, `Assets/Scripts/Player/GroundChecker.cs`

## 우선순위 점검
| 우선순위 | 항목 | 결과 |
| --- | --- | --- |
| ① 컴파일 가능성 | 검증 게이트 1단계 통과 | ✅ |
| ② 책임 분리 | PlayerController(입력·명령) / GroundChecker(판정) / Rigidbody2D(물리) 분리 | ✅ |
| ③ 컨벤션 | SerializeField + private, 매직넘버 제거 | ✅ |
| ④ 성능 | Update 내 GetComponent·Find 없음, FixedUpdate에서 물리 적용 | ✅ |

## 잘된 점
- 입력 수집(`Update`)과 물리 적용(`FixedUpdate`) 분리가 명확함.
- 지면 체크가 `GroundChecker`로 분리되어 다른 캐릭터에서도 재사용 가능.

## 개선 제안 (비차단)
- `moveSpeed`, `jumpForce` 같은 튜닝 값을 ScriptableObject로 뽑으면 캐릭터 다양화에 유리. **이번 단계에서는 보류** (요구사항 범위 밖).
- `GroundChecker.checkPoint`가 null일 때 NRE 가능성. 가드 한 줄 추가 권장.
  ```csharp
  if (checkPoint == null) { IsGrounded = false; return; }
  ```

## 결정
- 차단 이슈 없음. 4단계 사용자 검증으로 진행.
- 개선 제안 2건은 `artifacts/improvement-log.md`에 후속 기록.
