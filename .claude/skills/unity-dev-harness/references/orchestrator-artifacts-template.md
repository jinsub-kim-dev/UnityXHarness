# Orchestrator와 산출물 템플릿 (Unity 게임 개발)

이 문서는 실제 `.claude` 파일이나 하네스 청사진을 작성할 때 사용한다. Orchestrator는 일을 직접 다 하는 존재가 아니라, 역할을 나누고 산출물을 이어받고 검증·승인 지점을 관리하는 입구다.

## 하네스 청사진 템플릿

```md
## 하네스 청사진: {게임/작업 이름}

### 목표
- 이 하네스가 돕는 일:
- 최종 산출물: (동작하는 코드 / 설계 문서 / 버그 패치 등)
- 게임 범위: (2D/3D, 장르)
- 작업 성격: (신규/기능추가/버그/리팩토링)
- Unity MCP (MCP for Unity): (연결됨/없음)
- 참조 문서: (경로 또는 없음)

### 하네스 7요소
| 요소 | 이번 하네스에서의 내용 |
| --- | --- |
| 목표 |  |
| 컨텍스트 | (폴더 구조, 네이밍, 기존 시스템) |
| 도구 | (Read/Edit / Unity MCP) |
| 중간 산출물 |  |
| 검증 | (컴파일 / 컨벤션 / 플레이 테스트) |
| 권한과 승인 | (씬·에셋 변경 승인 지점) |
| 기록과 개선 |  |

### 사람의 작업 절차
1.
2.

### 실행 모드와 팀 패턴
- 실행 모드: 단일 흐름 | Subagent | Agent Team
- 패턴: Pipeline | Producer-Reviewer | Fan-out/Fan-in | Supervisor
- 선택 이유:

### Agent 역할표
| Agent | 맡는 일 | 분리 이유 | 입력 | 출력 | 하지 말아야 할 일 |
| --- | --- | --- | --- | --- | --- |

### Skill 목록
| Skill | 사용 Agent | 절차 요약 | 품질 기준 |
| --- | --- | --- | --- |

### Orchestrator 흐름
- 이름: `unity-dev-orchestrator`
- 위치: `.claude/skills/unity-dev-orchestrator/SKILL.md`
- 사람 승인 지점:

### 산출물 계약
| 단계 | 위치 | 만드는 역할 | 다음에 읽는 역할 |
| --- | --- | --- | --- |
| 입력 정리 | `artifacts/00-input.md` | Orchestrator | 모든 역할 |
| 설계 | `artifacts/01-design.md` | architect | gameplay-engineer |
| 구현 | `Assets/Scripts/...` | gameplay-engineer | reviewer, unity-ai-operator |
| 검증 | `artifacts/02-validation.md` | unity-ai-operator | Orchestrator |
| 리뷰 | `artifacts/03-review.md` | code-reviewer | Orchestrator |
| 개선 기록 | `artifacts/improvement-log.md` | Orchestrator | 다음 실행 Phase 0-A |
| 사용자 피드백 | `artifacts/04-user-feedback.md` | 사용자(viewer submit) | Orchestrator |
| 결과 확인 뷰어 | `.claude/hooks/` (스킬 assets에서 복사) | Stop hook | 사람 |
| 체인 로그 | `artifacts/chain-log.md` | Orchestrator(실행 끝에 improvement-log 축약본 누적) | 필요 시 과거 내역 참조 |

### Phase 8 뷰어 연결
- **hooks·viewer를 새로 만들지 않는다.** 스킬의 `assets/`에서 복사한다.
- `assets/hooks/*` → `.claude/hooks/` (런처 4종 + Gate 1·2 `unity-validate.*` + Gate 3 `gate3-test-runner.*` + `viewer/`)
- OS에 맞는 `assets/settings.windows.json`(또는 `settings.macos.json`)의 `hooks.Stop`을 `.claude/settings.json` 또는 `.claude/settings.local.json`에 병합 (`unity-validate.*` → `gate3-test-runner.*` → `open-viewer.*` 순서)
- Stop hook이 자동으로 Node(Express) 서버를 띄우고 viewer를 브라우저로 연다 (Node.js 필요)
- 뷰어는 `artifacts/`를 읽어 4단계 게이트 상태·산출물·개선 기록을 표시하고, 4단계 사용자 피드백을 submit하면 `artifacts/04-user-feedback.md`로 자동 저장한다

### 검증 (4단계 게이트)
| 단계 | 방법 | 통과 기준 |
| --- | --- | --- |
| 1. 컴파일 (Gate 1) | `unity-validate.*` / 수동 |  |
| 2. Play 모드 콘솔 에러 (Gate 2) | `unity-validate.*` Play 모드 진입 후 LogError·Exception |  |
| 3. 기능 테스트 (Gate 3) | `gate3-test-runner.*` + `gate3-test.json` (`gate3_run_test` MCP 도구) |  |
| 4. 사용자 확인 | hooks HTML 제출 → `artifacts/04-user-feedback.md` |  |
```

## Agent 템플릿

`references/agent-team-design.md`의 Agent 파일 구조를 따른다.

## Skill 템플릿

```md
---
name: {skill-name}
description: {트리거와 제외 조건이 분명한 한 문단}
---

# {Skill Name}

## 역할
이 Skill이 맡는 반복 업무.

## 사용 조건
- 사용해야 하는 경우
- 사용하지 말아야 하는 경우

## 입력
- 먼저 읽을 파일 / 확인할 정보

## 절차
1. ...

## 출력
- 저장 위치 / 파일명 / 형식 (코드는 Assets/, 문서는 artifacts/)

## 품질 기준
- 통과 기준 / 사람 승인 조건 / 실패 시 처리
```

## Orchestrator Skill 템플릿

```md
---
name: unity-dev-orchestrator
description: Unity 게임 개발 작업의 전체 흐름을 묶는 입구 Skill. "기능 만들어줘", "이 시스템 구현해줘", "버그 고쳐줘", "리팩토링해줘"와 재실행·기능추가·부분수정 요청에서 사용한다.
---

# Unity Dev Orchestrator

## 역할
설계 → 구현 → 검증 → 리뷰 흐름을 묶고, 산출물을 이어받고, 컴파일·플레이 검증과 사람 승인을 관리한다.

## 실행 모드 확인
1. `artifacts/`를 확인해 초기 실행 / 부분 재실행 / 새 실행을 정한다.
2. 후속 키워드: "다시", "기능 추가", "이 버그만", "이전 설계 기반", "리팩토링".

## 진행
1. 요청·게임 범위·제약을 `artifacts/00-input.md`에 저장
2. (Team 모드) `TeamCreate`로 팀 구성
3. `TaskCreate`로 설계/구현/검증/리뷰 등록
4. architect 설계 → `artifacts/01-design.md`
5. gameplay-engineer 구현 → `Assets/Scripts/`
6. 4단계 검증 (각 단계 게이트, 막히면 다음으로 넘어가지 않고 즉시 보고→수정→재검증) → `artifacts/02-validation.md`
   1. 컴파일 에러 확인 (Gate 1, `unity-validate.*`)
   2. Play 모드 콘솔 에러 확인 (Gate 2, `unity-validate.*`)
   3. 기능 테스트 (Gate 3, `gate3-test-runner.*` + `gate3-test.json`)
   4. 사용자 확인 (피드백 창구로 결과 입력)
7. code-reviewer 리뷰 → `artifacts/03-review.md`
8. 사람 승인 지점: 씬·에셋 변경, 대규모 리팩토링
9. 개선 기록 갱신, `TeamDelete`
10. Phase 8: hooks가 `artifacts/` 결과·후속조치를 viewer로 표시
11. 마무리: `artifacts/improvement-log.md`를 다음 실행 기준으로 갱신하고, `artifacts/chain-log.md`에는 improvement-log 축약본만 누적(덮어쓰지 않음)

## 실패 처리
- 컴파일/런타임/기능 점검 실패 → 해당 단계에서 멈추고 보고 → debugger 분석 → 수정 → 같은 단계 재검증
- 입력 부족 → 질문 목록 작성, 멈춤
```

## CLAUDE.md 포인터 템플릿

```md
# {프로젝트명}

## 이 프로젝트의 하네스
이 프로젝트는 Unity 게임 개발 하네스를 사용합니다.

## 자연어 라우팅
게임 기능 구현·버그 수정·리팩토링 요청이 오면, 개별 Agent를 직접 부르기 전에
`unity-dev-orchestrator` Skill을 먼저 사용하세요.

예: "플레이어 점프 기능 만들어줘" → unity-dev-orchestrator 실행

## Unity 프로젝트 규칙
- C# 스크립트 위치: `Assets/Scripts/`
- 네이밍: (PascalCase 클래스, camelCase 필드 등 프로젝트 규칙)
- 씬·에셋 변경은 사람 승인 후 unity-ai-operator(MCP)가 수행

## 주요 위치
- Agent: `.claude/agents/`
- Skill: `.claude/skills/`
- 결과 확인 뷰어 hooks: `.claude/hooks/`
- 설계·검토·기록: `artifacts/`

## 변경 이력
- (날짜) 초기 하네스 구성
```
