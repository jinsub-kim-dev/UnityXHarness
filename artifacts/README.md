# artifacts 산출물 지도

이 폴더는 하네스 실행 과정의 설계·검증·기록을 담는다. 실제 코드는 `Assets/Scripts/` 정규 위치에 있다.

| 파일 | 내용 | 만든 역할 | 다음에 읽는 역할 |
| --- | --- | --- | --- |
| 00-input.md | 요청·게임 범위·제약·7요소 초안 | Orchestrator | 모든 역할 |
| 01-design.md | 책임 분리, 입력→물리 흐름, 클래스 구조 | unity-architect | gameplay-engineer |
| 02-validation.md | 4단계 검증 게이트 결과 | unity-ai-operator + Orchestrator | code-reviewer, hooks 뷰어 |
| 03-review.md | 코드 리뷰, 차단/비차단 이슈 | code-reviewer | Orchestrator |
| 04-user-feedback.md | 사용자 4단계 검증 결과 (뷰어 자동 저장) | 사용자 (hooks 뷰어) | Orchestrator |
| improvement-log.md | 회고·원인·반영·다음 테스트 | Orchestrator | 다음 실행 Phase 0-A |
| chain-log.md | improvement-log 축약본(누적 참조 로그) | Orchestrator | 필요 시 과거 내역 참조 |

## 이번 실행 요약
- 작업: 2D 플랫포머 PlayerController 신규 구현
- 4단계 게이트 결과: ①✅ ②✅ ③❌→✅(재검증) ④수정 필요(사용자 피드백)
- 후속: 점프 입력 버퍼 도입 검토
