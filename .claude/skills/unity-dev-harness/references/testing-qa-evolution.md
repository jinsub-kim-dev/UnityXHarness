# 검증 / QA / 개선 사양 (Unity 게임 개발)

## 4단계 검증 게이트

구현 후 검증은 아래 4단계를 순서대로 진행한다. **각 단계는 게이트다. 통과하지 못하면 다음 단계로 넘어가지 않고 즉시 보고 → 수정 → 같은 단계 재검증한다.** 1~3단계는 자동 진행, 4단계는 사용자 수동.

| 단계 | 내용 | 주체 | 통과 기준 |
| --- | --- | --- | --- |
| 1. 컴파일 | 스크립트가 컴파일되는가 | `unity-validate` hook (`refresh_unity`+`editor/state`) / 미연동 시 자동 검증 불가 | 컴파일 에러 0 |
| 2. 런타임 에러 | Play 진입 시 Debug.LogError·Exception이 없는가 | `unity-validate` hook (`manage_editor`+`read_console`) / 미연동 시 자동 검증 불가 | 에러·예외 0 |
| 3. 기능 점검 (자동) | 개발한 기능이 실제로 동작하는가 (콘솔 에러 없음 기준 1차 판정) | `unity-validate` hook / 미연동 시 자동 검증 불가 | 추가 에러 없음 |
| 4. 기능 점검 (사용자) | 사용자가 직접 최종 확인 | 사람 | 사용자가 통과로 판정 |

> 1~3단계는 Phase 8에서 설치하는 Stop hook `unity-validate.*`가 CoplayDev MCP for Unity에 붙어 자동 수행한다. 에러가 있으면 `{"decision":"block"}`으로 Claude Stop을 막아 수정 루프로 잇고, 매 실행마다 `artifacts/02-validation.md`의 게이트 표를 갱신한다. 상세는 `unity-ai-mcp-guide.md`.

### MCP 연동 여부에 따른 1~3단계 분기 (자동 검증의 전제)

1~3단계 자동 검증은 **MCP for Unity가 에디터를 조작·조회할 수 있을 때만** 성립한다. Phase 0에서 확정한 MCP 연동 여부에 따라 두 경로로 갈린다.

- **MCP 연동됨**: 1~3단계를 Stop hook `unity-validate.*`가 MCP 명령(`refresh_unity`, `manage_editor`, `read_console`, `mcpforunity://editor/state`)으로 자동 실행한다. 통과하면 `02-validation.md`에 `✅`, 콘솔 에러가 잡히면 `❌`로 기록하고 Claude Stop을 차단해 수정 루프로 잇는다. 위의 표 그대로 진행한다.
- **MCP 미연동**: 1~3단계의 자동 검증을 **건너뛴다(skip)**. AI가 컴파일·런타임·기능을 대신 판정할 수 없으므로, 이 세 단계는 결과를 만들지 않고 **"수동 검증 필요(manual)"** 상태로 남긴다. `artifacts/02-validation.md`에 자동 결과 대신 사람이 직접 확인할 수동 체크리스트를 기록하고, 뷰어에도 1~3단계를 "수동 검증 필요"로 표시한다. 4단계 사용자 피드백은 그대로 진행한다.

> 핵심: MCP가 없으면 1~3단계는 "실패"가 아니라 "자동 검증을 수행할 수 없는 상태"다. 게이트를 거짓으로 통과시키지 말고, 수동 검증이 필요함을 명확히 남긴다.

### 게이트 동작

- (MCP 연동됨) 1→2→3은 자동으로 연결 진행한다.
- (MCP 미연동) 1~3은 자동 진행하지 않고 "수동 검증 필요"로 남긴다. 자동 게이트가 없으므로 바로 4단계 사용자 점검으로 넘어가되, 02-validation의 수동 체크리스트를 함께 안내한다.
- 단계 실패 시: 그 단계에서 멈추고 결과를 `artifacts/02-validation.md`에 기록 → debugger 분석 → gameplay-engineer 수정 → **실패한 단계부터 다시** 검증.
- 다음 단계로의 진행은 직전 단계 통과(또는 미연동 시 수동 확인)를 전제로만 허용한다.

### 4단계 사용자 피드백 (HTML 제출 → 자동 저장)

1~3단계를 통과하면(또는 MCP 미연동으로 1~3단계가 "수동 검증 필요" 상태이면) `.claude/hooks/`가 결과 HTML 페이지를 연다. 4단계는 별도 파일을 직접 작성하는 방식이 아니라, **이 HTML 페이지에서 사용자가 검증 내용을 입력하고 submit하면 자동으로 `artifacts/04-user-feedback.md`로 저장**되는 형식으로 제공한다.

> MCP 미연동이면 1~3단계 자동 결과가 없으므로, 4단계 입력 폼은 1~3 통과를 기다리지 않고 바로 활성화된다. 대신 폼 상단에 "1~3단계는 자동 검증되지 않았으니 직접 확인 후 입력하라"는 안내를 표시한다.

HTML 페이지 요구사항:

- 상단: 1~3단계 자동 검증 결과(통과/실패, 막힌 지점) 표시
- 하단: 사용자 입력 폼 (확인한 항목 / 정상 동작 / 문제·이상 동작 / 재현 방법 / 판정: 통과·수정 필요)
- submit 시: 입력 내용을 `artifacts/04-user-feedback.md`로 자동 저장

저장되는 형식:

```md
## 사용자 검증 피드백
- 확인한 항목:
- 정상 동작:
- 문제/이상 동작:
- 재현 방법:
- 판정: 통과 | 수정 필요
```

- 판정이 "수정 필요"면 저장된 내용을 debugger/gameplay-engineer로 보내 수정 → 1~4단계 재검증.

### 결과 표시 (Phase 8 연동)

검증 결과 화면은 `.claude/hooks/`가 연다. Stop hook은 두 단계로 동작한다: 먼저 `unity-validate.*`가 MCP for Unity에 붙어 1~3단계를 자동 검증하고 `artifacts/02-validation.md`를 갱신한 뒤(미연동이면 "수동 검증 필요"로 기록), 이어서 viewer 런처가 Node(Express) 서버를 띄우고 브라우저로 viewer를 연다(Node.js 필요). 1~3단계 결과는 표시 전용이고, 4단계는 입력·submit이 가능하며 submit 시 서버가 `artifacts/04-user-feedback.md`로 저장한다. hooks·viewer 자산은 스킬의 `assets/`에 동봉되어 있으며 새로 만들지 않고 복사해 쓴다.

## QA / Reviewer 운영

- code-reviewer는 전체 완료 후 1회가 아니라 시스템·모듈 단위로 점진 검토한다.
- 검토 우선순위: ① 컴파일 가능성 ② 책임 분리 ③ 컨벤션 ④ 성능(Update 내 무거운 연산, GC 할당).
- 씬 변경·대규모 리팩토링 등 위험한 중간 산출물은 끝난 직후 검토한다.

## Drift 점검

| 항목 | 확인 |
| --- | --- |
| 담당자 일치 | Agent 파일명과 Orchestrator의 Task 담당자 이름 |
| 라우팅 일치 | `CLAUDE.md` 라우팅과 실제 Orchestrator 이름 |
| 코드 위치 | `Assets/Scripts/` 규칙과 실제 프로젝트 |
| MCP 가정 | 하네스의 MCP 연동 가정과 실제 상태 |
| 범위 적합성 | 하네스 구성과 현재 게임 범위 |
| 중복/사용 안 함 | 중복 Skill, 사용 안 하는 Agent |

## 개선 기록 (Evolution)

`artifacts/improvement-log.md`에 남긴다.

```md
## {날짜} 개선 기록
### 무엇이 아쉬웠나
- (예: gameplay-engineer가 FixedUpdate 대신 Update에 물리를 넣음)
### 원인
- (컨벤션 Skill에 물리 처리 규칙이 없었음)
### 반영
- 대상: .claude/skills/csharp-convention-guide/SKILL.md
- 변경: "물리는 FixedUpdate" 규칙 추가
### 다음 테스트
- 물리 이동 스크립트 생성 시 FixedUpdate 사용 확인
```

기록은 읽어서 실제 Agent·Skill에 반영하고 변경 이력을 남긴다.

## 정상 작동 신호

- AI가 게임 범위를 추측하지 않고 묻는다.
- 코드가 `Assets/` 정규 위치에 생기고 컴파일된다.
- 4단계 검증 게이트에서 막히면 진행을 멈추고 보고·수정한다.
- 씬·에셋 변경 전 사람 승인을 거친다.
- 같은 작업을 다시 요청하면 이전 산출물을 읽고 이어간다.
