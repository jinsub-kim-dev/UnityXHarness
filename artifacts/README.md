# artifacts 산출물 지도

하네스(`unity-dev-orchestrator`) 실행 과정의 설계·검증·기록 문서. 실제 코드는 `Assets/10_ProjectA/00_Script/` 정규 위치에 있다. 이 폴더에 C# 코드를 두지 않는다.

진행 단위는 `docs/design/game-plan.md`의 Key Systems **시스템 1개**다. 새 시스템을 시작하면 00~04는 초기화되고, `improvement-log.md`·`chain-log.md`만 남는다.

| 파일 | 내용 | 만든 역할 | 다음에 읽는 역할 |
| --- | --- | --- | --- |
| 00-input.md | 대상 시스템, game-plan 발췌, 제약, 승인 지점, 7요소 | Orchestrator | 모든 역할 |
| 01-design.md | 책임 분리, 의존 그래프, DI 등록, 수치 초기값, 설계 체크리스트(D-xx), 자동 검증 시나리오(T-xx) | unity-architect | gameplay-engineer, code-reviewer, unity-ai-operator |
| 02-validation.md | 4단계 검증 게이트 결과 (`게이트 진행 요약` 표는 뷰어가 파싱) | unity-ai-operator | Orchestrator, 뷰어 |
| 03-review.md | 설계↔구현 매칭, 차단/비차단 이슈 | code-reviewer | Orchestrator, gameplay-engineer |
| 04-user-feedback.md | 사용자 4단계 검증 결과 (뷰어 submit 시 자동 저장) | 사용자(뷰어) | Orchestrator |
| improvement-log.md | 직전 실행 1건의 회고·원인·반영·다음 테스트 (덮어쓰기) | Orchestrator | 다음 실행 Phase 0 |
| chain-log.md | improvement-log 축약본 누적 (append) | Orchestrator | 과거 내역 필요 시 |

## 이번 실행 요약
- 작업: (아직 없음 — 첫 시스템: 플레이어 이동)
- 4단계 게이트 결과: -
- 후속: -
