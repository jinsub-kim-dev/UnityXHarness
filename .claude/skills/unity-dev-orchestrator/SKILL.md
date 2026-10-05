---
name: unity-dev-orchestrator
description: 3D 탑다운 뱀서 MVP 개발의 입구 Skill. docs/design/game-plan.md의 시스템 단위 구현 요청("적 스폰 시스템 만들어줘", "다음 시스템 진행해", "자동 공격 구현해줘")과 후속 요청("다시", "피드백 반영해줘", "이 버그만", "이전 설계 기반으로", "수치 조정")에서 사용한다. 설계 → 구현 → 리뷰 → 씬 구성 → 4단계 검증 → 기록 흐름을 subagent로 위임하며 관리한다. 단일 클래스의 작은 수정은 add-feature 에이전트, 기획 문서 작성은 game-plan/prd Skill을 쓴다.
---

# Unity Dev Orchestrator

## 역할
메인 세션이 이 Skill을 따라 시스템 1개를 끝까지 진행한다. 직접 코드를 쓰지 않고 `Agent` 도구로 위임하고, 산출물을 이어받고, 승인·검증 게이트를 관리한다.

| 단계 | 담당 (`subagent_type`) | Skill |
| --- | --- | --- |
| 설계 | `unity-architect` | system-design |
| 구현·수정 | `gameplay-engineer` | csharp-convention-guide, create-component, extend-class |
| 리뷰 | `code-reviewer` | csharp-convention-guide |
| 씬 구성·Gate 1~3 | `unity-ai-operator` | scene-setup, unity-validation-gates |

실행 모드: **Subagent Pipeline + Producer-Reviewer**. (이 환경에는 TeamCreate/TaskCreate가 없으므로 Agent Team을 쓰지 않는다. 같은 단계 재작업은 SendMessage로 기존 subagent를 이어서 쓴다.)
Unity MCP 도구는 메인 세션에서만 연결이 보장되므로, subagent에서 `mcp__unity-mcp__*`를 쓸 수 없으면 operator 단계는 메인 세션이 `unity-validation-gates`/`scene-setup` Skill을 직접 따라 수행한다.

## 0. 실행 분기
1. `artifacts/improvement-log.md`를 읽는다(직전 회고·다음 입력). 필요하면 `chain-log.md`.
2. `artifacts/00-input.md`가 있으면 진행 중인 시스템과 단계를 파악한다.
3. 요청을 분류한다.

| 분류 | 신호 | 시작 단계 |
| --- | --- | --- |
| 새 시스템 | "다음 시스템", 시스템명 지정, 00-input 없음 | 1 (artifacts 00~04 초기화) |
| 피드백 수정 | `04-user-feedback.md` 판정 "수정 필요", "피드백 반영" | 3 (피드백을 입력으로) |
| 버그만 | "이 버그만", 콘솔 에러 제시 | 3 (설계 변경 없음) |
| 설계 변경 | "이전 설계 기반으로 ~ 바꿔", 범위 변경 | 2 |
| 수치 조정 | "속도/체력/간격 조정" | 3 (설계 수치표 갱신 포함) |

시스템 미지정 "다음 시스템"이면 game-plan Development Order에서 `chain-log.md`에 완료 기록이 없는 첫 항목을 고르고 사람에게 확인한다.

## 1. 입력 정리 → `artifacts/00-input.md`
- 새 시스템이면 `artifacts/`의 `00~04*.md`를 삭제한다(`README.md`, `improvement-log.md`, `chain-log.md`는 유지).
- 대상 시스템, game-plan 해당 행(Key Systems·MVP 설명·Development Order 확인 포인트), `docs/requirements/{system}.md` 유무, 선행 시스템 완료 여부, 사람 승인 지점, 7요소를 적는다.
- 요구가 모호하면(예: 웨이브 증가 규칙이 전혀 없음) 추측하지 말고 질문 목록을 만들어 **멈춘다**. 큰 시스템이면 `/prd {system}` 선작성을 권한다.

## 2. 설계 → `artifacts/01-design.md`
- `unity-architect`에 위임: "00-input.md 기준으로 system-design Skill에 따라 01-design.md 작성".
- 결과를 요약해 사람에게 보여준다(클래스 구조, Common 수정 여부, 씬 변경 목록, D-xx/T-xx).
- 🙋 **사람 승인 게이트**: 승인 전에는 구현으로 넘어가지 않는다. 수정 요청이면 architect에 재위임.

## 3. 구현 → `Assets/10_ProjectA/00_Script/...`
- `gameplay-engineer`에 위임: 01-design(필요 시 03-review 차단 이슈, 04-user-feedback, 02-validation 실패 상세 포함)을 입력으로.
- 구현 후 engineer는 `.claude/codebase-index.md`에 ProjectA 섹션을 갱신한다.

## 4. 리뷰 → `artifacts/03-review.md`
- `code-reviewer`에 위임: 01-design D-xx 1:1 매칭 + 컨벤션 + 의존 방향 + 성능.
- 차단 이슈가 있으면 3으로 돌아간다(SendMessage로 같은 engineer 이어서). **최대 2회**, 이후 사람에게 보고.

## 5. 씬 구성
- 01-design의 씬·프리팹 변경이 있으면 `unity-ai-operator`(scene-setup)가 변경 요약을 만든다.
- 🙋 **사람 승인 게이트** → 승인 후 실행.

## 6. Gate 1~3 → `artifacts/02-validation.md`
- `unity-ai-operator`(unity-validation-gates) 수행.
- 실패: 실패 상세를 engineer에 전달 → 수정 → 리뷰(변경분만) → **실패 게이트부터** 재검증. 같은 게이트 2회 연속 실패면 멈추고 사람에게 보고.
- MCP 불가로 `🔧 수동 검증 필요`가 나오면 그대로 두고 수동 체크리스트를 안내한다.

## 7. Gate 4 — 사용자 확인
- 사람에게 02-validation의 "사용자 확인 가이드"를 짧게 안내한다.
- 턴이 끝나면 Stop hook이 컨벤션 체크 후 뷰어를 연다(`.claude/hooks/open-viewer.ps1`). 사용자가 뷰어에서 제출하면 `artifacts/04-user-feedback.md`가 생긴다.
- 다음 요청에서 04를 읽어 "통과"면 8로, "수정 필요"면 3으로.

## 8. 마무리 기록
- `artifacts/README.md`의 "이번 실행 요약" 갱신.
- `artifacts/chain-log.md` 맨 아래에 이번 실행 축약본 append (날짜 · 시스템 / 4단계 결과 / 핵심 개선점 / 다음 입력).
- `artifacts/improvement-log.md`를 이번 실행 1건으로 **덮어쓴다** (무엇이 아쉬웠나 / 원인 / 반영 / 다음 테스트 / 하네스 자체 개선 메모).
- 하네스 개선점이 Agent·Skill 수정으로 이어지면 수정 제안을 사람에게 보여주고 승인 후 반영한다.

## 산출물 계약
| 단계 | 위치 | 만드는 역할 | 다음에 읽는 역할 |
| --- | --- | --- | --- |
| 입력 | `artifacts/00-input.md` | Orchestrator | 전원 |
| 설계 | `artifacts/01-design.md` | unity-architect | engineer, reviewer, operator |
| 코드 | `Assets/10_ProjectA/00_Script/...` | gameplay-engineer | reviewer, operator |
| 코드 인덱스 | `.claude/codebase-index.md` | gameplay-engineer | architect, add-feature |
| 검증 | `artifacts/02-validation.md` | unity-ai-operator | Orchestrator, 뷰어 |
| 리뷰 | `artifacts/03-review.md` | code-reviewer | Orchestrator, engineer |
| 사용자 피드백 | `artifacts/04-user-feedback.md` | 사용자(뷰어) | Orchestrator |
| 개선 / 체인 | `improvement-log.md` / `chain-log.md` | Orchestrator | 다음 실행 0단계 |

## 사람 승인 지점
- 설계안(2단계)
- 씬·프리팹·에셋 변경(5단계)
- `00_CommonFramework` 수정, LifetimeScope 신규 추가
- 패키지 추가, asmdef 도입, 허용 범위 밖 라이브러리 기능
- 재시도 한도 초과

## 실패 처리
| 상황 | 처리 |
| --- | --- |
| 입력 부족 | 질문 목록 작성 후 멈춤 |
| 리뷰 차단 이슈 | engineer 수정 → 재리뷰, 최대 2회 |
| Gate 실패 | engineer 수정 → 실패 게이트부터 재검증, 최대 2회 |
| 설계-구현 충돌 | 한쪽을 지우지 않고 근거를 03-review에 남긴 뒤 사람에게 판단 요청 |
| MCP 불가 | `🔧 수동 검증 필요`로 기록, 수동 체크리스트 안내 |
| subagent 무응답·이상 결과 | 1회 재시도 후 보고 |
