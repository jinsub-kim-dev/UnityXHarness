# 개선 기록

## 2026-05-28 PlayerController 1차 작업

### 무엇이 아쉬웠나
1. 3단계 자동 검증에서 공중 무한 점프가 발견됨 (1차 시도 실패).
2. 4단계 사용자 검증에서 착지 직후 점프 입력이 가끔 누락됨 (판정: 수정 필요).

### 원인
1. PlayerController가 GroundChecker.IsGrounded를 참조하지 않고 점프 요청만으로 velocity를 적용함. 설계 문서에는 명시돼 있었으나 구현에서 누락.
2. 점프 입력 감지가 `Update`에서 `Input.GetKeyDown` 1프레임이고, 직후 `FixedUpdate`에서 grounded가 아직 false인 순간이 있을 수 있음 (착지 판정과 입력 타이밍 차).

### 반영
1. (즉시) `PlayerController.FixedUpdate`에서 `groundChecker.IsGrounded` 조건 추가 완료.
2. (다음 작업) 점프 입력 버퍼 도입 검토. 입력 후 일정 시간(예: 0.1s) 안에 grounded가 되면 점프 처리.
   - 대상 파일: `Assets/Scripts/Player/PlayerController.cs`
   - 관련 Skill: 새로 추가 검토 — `input-buffer-pattern` (점프·대시 등 공통 입력 버퍼 패턴)

### 다음 테스트
- 입력 버퍼 도입 후 4단계 사용자 검증에서 누락이 사라지는지 확인.
- 회귀: 공중 무한 점프가 다시 생기지 않는지 3단계 자동 검증으로 확인.

### 하네스 자체 개선 메모
- 설계 문서(01-design.md)에 "grounded 조건 필수" 항목이 명시돼 있었으나 구현에서 빠졌다. code-reviewer가 게이트 통과 전에 설계 ↔ 구현 항목 매칭 체크를 한 번 더 도입하면 좋을 것.
  - 반영 대상: `.claude/agents/code-reviewer.md` 작업 방식에 "설계 항목 체크리스트 매칭" 추가.
