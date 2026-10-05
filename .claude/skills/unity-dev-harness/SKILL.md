---
name: unity-dev-harness
description: Unity 게임 개발용 하네스 엔지니어링 설계·생성 스킬. 자신의 Unity 프로젝트(2D/3D, 신규/기능추가/버그수정/리팩토링)를 Agent, Skill, Orchestrator, Test, Evolution 구조로 바꾸고 싶어 할 때, 그 일을 Claude Code 하네스(.claude/agents, .claude/skills, .claude/hooks, CLAUDE.md, artifacts)로 만들어준다. "유니티 게임 개발 하네스 만들어줘", "내 Unity 프로젝트용 에이전트 팀 설계해줘", "게임플레이/디버깅/리뷰 에이전트 만들어줘", "Unity MCP로 명령하는 하네스 구성해줘", "기존 Unity 하네스 점검/개선해줘" 같은 요청에서 반드시 사용한다. 단순한 C# 문법 질문, 하네스와 무관한 단발성 코딩 질문, Unity가 아닌 다른 엔진 작업에는 사용하지 않는다.
---

# Unity 게임 개발 하네스

## 역할

이 스킬은 Unity 게임 개발 업무를 현재 프로젝트 안의 `.claude` 하네스 구조로 바꾸도록 돕는다. 목표는 파일을 많이 만드는 것이 아니라, AI에게 게임 개발을 맡길 때 필요한 목표, 컨텍스트(프로젝트 구조·규칙), 중간 산출물, 검증(컴파일·플레이 테스트), 사람 승인, 기록을 바깥 구조로 꺼내 반복 가능하게 만드는 것이다.

"멋지게 만들어줘", "내 게임 만들어줘"처럼 막연한 요청에는 바로 장황한 설명으로 답하지 않는다. 먼저 무엇을 만드는 게임인지와 최종 산출물(예: 동작하는 PlayerController, 설계 문서, 리팩토링된 시스템)을 잡고, 부족한 정보는 확인 필요로 분리한 뒤, 작게 따라 할 수 있는 하네스로 바꾼다.

판단 기준 한 문장:

> 하네스는 AI가 덜 추측하고, 더 안전하게(컴파일·테스트로 검증되고), 더 반복 가능하게 게임 개발 작업을 하도록 만드는 작업 환경이다.

상세한 설계 원칙, 품질 기준, 피해야 할 것, 하네스 7요소는 `references/harness-principles.md`에 있다. 하네스를 설계·생성하기 전에 이 문서를 읽는다.

## 핵심 규칙 (요약)

- Phase는 0부터 8까지로 고정한다.
- 하네스 생성은 항상 청사진 승인 게이트를 지난다. 청사진을 먼저 보여주고, 명시적 승인 뒤에만 파일을 만든다.
- **Phase 0의 필수 4개 질문(게임 차원/장르, 작업 성격, Unity MCP 연동 여부, 참조 문서 경로)은 어떤 경우에도 생략하지 않는다.** 사용자의 첫 메시지나 프로젝트 파일에 답이 있는 것처럼 보여도 반드시 다시 확인한다.
- **선택지가 있는 질문은 클라이언트가 지원하는 인터랙티브 입력 UI(클릭 가능한 선택지 버튼)를 우선 사용한다.** 텍스트 코드 블록으로 선택지를 나열하는 방식은 인터랙티브 UI를 못 쓰는 환경에서만 폴백으로 쓴다.
- C# 코드와 씬·에셋은 `Assets/` 정규 위치에, 설계·검토·기록 문서는 `artifacts/`에 둔다.
- 컴파일이 1차 검증이다. 씬·에셋·대규모 리팩토링 변경은 사람 승인 지점이다.
- 게임 범위와 작업 성격에 따라 Agent 구성을 조정한다. 고정 구성을 무조건 넣지 않는다.
- **hooks 스크립트와 viewer.html은 직접 만들지 않는다.** 이 스킬의 `assets/` 폴더에 있는 자산을 프로젝트 `.claude/`로 복사·연결만 한다.
- 실행 하네스 생성 위치: `.claude/agents`, `.claude/skills`, `.claude/hooks`, `CLAUDE.md`, `artifacts/`.

## 실행 모드

요청을 아래 세 모드 중 하나로 분류한다. 불확실하면 함께 설계로 시작한다.

| 모드 | 사용 상황 | 처리 방식 |
| --- | --- | --- |
| 빠른 설계 | 가볍게 방향이나 예시를 본다 | 질문 최소화, 작은 청사진·산출물 예시·다음 행동 제시 |
| 함께 설계 | 목표는 있지만 게임 범위·작업 성격·기존 구조가 불명확 | 3개 이하 질문으로 빈칸을 채우고 청사진 작성 |
| 실행 하네스 구성 | 청사진 승인 후 실제 파일 구성 | 기존 파일 확인 후 `.claude/*`, `CLAUDE.md`, `artifacts/` 구성 |

## 청사진 승인 게이트

1. 청사진 단계: 파일을 만들지 않고 하네스 7요소, 작업 절차, 산출물 계약, 실행 모드, Agent 역할표, Skill 목록, Orchestrator 흐름을 보여준다.
2. 구성 단계: 방금 제시한 청사진에 "이 구조로 만들어줘"처럼 명시적으로 승인받은 뒤에만 파일을 만든다.

제한:

- 첫 요청에서 "바로 만들어줘"라고 해도 청사진을 먼저 보여준다.
- "진행해", "좋아"는 직전 응답에서 청사진을 제시한 경우에만 승인으로 본다.
- 청사진을 보여주기 전에는 어떤 표현도 파일 생성 승인으로 해석하지 않는다.
- 예외는 특정 파일 경로와 구체적 수정 내용을 직접 지정한 일반 편집 요청뿐이다.

## 진행 방식 (Phase 0-8)

| Phase | 할 일 |
| --- | --- |
| 0 | 현재 상황 확인: 자동 읽기(0-A) → 읽은 내용 확인(0-B) → 필수 4개 질문(0-C, 무조건) → 보조 입력(0-D) |
| 1 | 작업 분해: 최종 산출물에 이르는 작업 단계와 의존 관계를 정리 |
| 2 | 산출물 정의: 무엇이 나오면 성공인지 정한다(동작하는 코드, 문서, 패치 등) |
| 3 | 실행 모드·팀 패턴 선택: 단일 흐름 / Subagent / Agent Team |
| 4 | Agent 설계: 누가 어떤 역할을 맡을지 |
| 5 | Skill 설계: 각 역할이 따를 작업법 |
| 6 | Orchestrator 설계: 작업 순서, 전달물, 검증, 실패 시 대응 |
| 7 | 검증과 개선: 4단계 검증 게이트와 개선 기록. 1~3단계 자동 검증은 MCP 연동 시에만 수행, 미연동 시 수동 검증 필요로 표시 |
| 8 | 결과 확인 뷰어: hooks가 7단계 기록·후속조치를 HTML 뷰어로 띄워 확인 |

자세한 단계별 질문과 산출물은 `references/harness-design-workflow.md`를 읽는다.

### Phase 0 진행 순서 (반드시 이 순서대로)

Phase 0은 다음 4단계를 **건너뛰지 않고** 차례로 수행한다. 사용자의 첫 메시지에 일부 정보가 있어도 아래 절차는 그대로 진행한다.

**0-A. 프로젝트 자동 읽기**
- 프로젝트 루트, `Assets/`, `Packages/manifest.json`, 기존 `.claude/*`, `CLAUDE.md`를 읽어 폴더 구조·코딩 컨벤션·기존 시스템·렌더 파이프라인을 파악.
- 이전 실행 컨텍스트는 기본적으로 `artifacts/improvement-log.md`를 그대로 읽는다. 이 파일의 회고·원인·반영·다음 테스트가 0단계의 연속 작업 기준이다.
- `artifacts/chain-log.md`는 `improvement-log.md`를 축약한 누적 참조 로그로 남긴다. 기본 자동 입력은 아니며, 과거 작업 흐름이 필요할 때만 수동 또는 자동으로 추가 참조한다.
- 추정만 가능한 항목(예: 2D/3D 여부)은 추정으로 기록.

**0-B. 읽은 내용 확인 (간단)**
- 파악한 내용을 4~6줄로 요약해 사용자에게 보여주고 "이대로 맞나요? 빠진 게 있나요?"로 짧게 확인.
- 사용자가 수정·보완할 기회를 준다. 응답이 오기 전까지 다음 단계로 넘어가지 않는다.

**0-C. 필수 4개 질문 (무조건)**
- 아래 4개는 **어떤 경우에도 생략하지 않는다.** 사용자의 첫 메시지나 프로젝트 파일에 답이 있는 것처럼 보여도 **반드시 다시 확인한다.** 이유: 장르·작업 성격·MCP 연동·참조 문서 경로는 파일에서 추정할 수 없거나 추정이 틀리면 Agent/Skill 구성 전체가 어긋난다. (참조 문서 경로는 답이 "없음"이어도 질문 자체는 반드시 한다.)
- **질문 방식**: 클라이언트가 지원하면 인터랙티브 선택지 UI(클릭 버튼)를 사용한다. 지원하지 않는 환경에서만 텍스트로 번호 매긴 선택지를 출력한다.

| 입력 항목 | 선택지 | Agent 구성에 미치는 영향 |
| --- | --- | --- |
| 게임 차원/장르 | 2D 캐주얼·퍼즐 / 2D 플랫포머 / 3D 액션·RPG / 장르무관(아키텍처 중심) / 프로토타입 | 강조하는 시스템(물리·입력·AI·레벨)이 달라짐 |
| 작업 성격 | 신규 설계 / 기능 추가 / 버그 수정 / 리팩토링 | 신규=설계 Agent 강조, 버그=디버거 Agent 중심 |
| Unity MCP 연동 여부 | MCP for Unity(CoplayDev) 연결됨 / 아직 없음 | 연결됨=unity-ai-operator + 자동 검증 hook 포함, 없음=수동 체크리스트로 대체 |
| 참조 문서 경로(코딩 컨벤션 등) | 있음(경로 입력) / 없음 | 있으면 Phase 5 Skill 설계(예: C# 컨벤션 가이드)가 그 문서 내용을 그대로 반영, 없으면 기존 코드에서 추정 |

**0-D. 보조 입력 (추정·기본값 허용)**
- 프로젝트 규모(1인 작업 / 소규모 팀) 등은 자동 추정하거나 기본값을 쓰고, 필요할 때만 추가로 묻는다.

### 신규/기존확장/유지보수 분기

위 진행은 공통이고, 0-A에서 파악한 상태에 따라 처리 범위가 갈린다.

| 상황 | 처리 방식 |
| --- | --- |
| 신규 구축 | 청사진을 만든 뒤 승인되면 전체 하네스를 구성 |
| 기존 확장 | 기존 Orchestrator, Agent, Skill, `CLAUDE.md`를 읽고 필요한 Phase만 다시 설계 |
| 운영/유지보수 | drift, 중복, 누락 테스트, 오래된 포인터를 점검하고 개선 청사진 제시 |

### Phase 8: 결과 확인 뷰어 (hooks)

7단계까지의 실행 기록(`artifacts/`)과 사람이 후속조치해야 할 항목을 hooks가 viewer로 띄워 한눈에 확인하게 한다.

**중요: hooks 스크립트와 viewer를 직접 생성하지 않는다.** 이미 완성된 자산이 이 스킬의 `assets/` 폴더에 있다. Phase 8은 그 자산을 프로젝트로 **복사하고 연결만** 한다.

- 자산 위치(이 스킬 내): `assets/hooks/`(런처 4종 + `viewer/server.js`·`package.json`·`viewer.html` + Gate 1·2 검증 `unity-validate.ps1`·`unity-validate.sh` + Gate 3 검증 `gate3-test-runner.ps1`·`gate3-test-runner.sh`), `assets/settings.windows.json`, `assets/settings.macos.json`, `assets/settings.template.md`.
- 복사 대상(프로젝트): `assets/hooks/*` → `.claude/hooks/`. settings는 OS에 맞는 `assets/settings.windows.json`(또는 `settings.macos.json`)의 `hooks.Stop`을 프로젝트 `.claude/settings.json` 또는 `.claude/settings.local.json`에 병합.
- 런처: Windows는 `open-viewer.cmd`/`open-viewer.ps1`, macOS/Linux는 `open-viewer.sh`(+ Finder용 `open-viewer.command`).
- 트리거: Claude Code Stop event hook. 작업 종료 시 Stop hook 배열이 순서대로 실행된다.
- 동작: **(1) Gate 1·2 자동 검증**(`unity-validate.*`): 컴파일 에러 확인(Gate 1) → Play 모드 진입 후 콘솔 에러 확인(Gate 2). **(2) Gate 3 기능 테스트**(`gate3-test-runner.*`): `.claude/hooks/.viewer-state/gate3-test.json`에 정의된 대상을 Play 모드에서 `gate3_run_test` MCP 도구로 실행. `Assets/` 아래 `.cs` 파일을 만들거나 수정할 때마다 `gate3-test.json`도 함께 갱신해야 한다. **(3) 뷰어 오픈**(`open-viewer.*`): `viewer/`의 Node 서버(`server.js`, Express)를 띄우고(최초 실행 시 `npm install`) 브라우저로 viewer를 열어 `artifacts/`를 자동 로드한다. 서버가 이미 떠 있으면 재사용한다.
- 전제: **Node.js 필요.** 미설치 시 자동 오픈이 동작하지 않는다.
- `02-validation.md`가 없어도 viewer는 열린다(검증 출력이 없으면 경고만 로깅).
- 4단계 사용자 피드백은 viewer에서 submit 시 서버가 `artifacts/04-user-feedback.md`로 저장한다.
- 마무리로 이번 실행을 `artifacts/chain-log.md`에 `improvement-log.md`의 축약본으로 누적한다(덮어쓰지 않음). 원문/raw 로그가 아니라 날짜·작업·4단계 결과·핵심 개선점·다음 입력 중심의 참조 가능한 요약본으로 남긴다. 다음 실행의 Phase 0-A는 `improvement-log.md`를 먼저 읽으며, `chain-log.md`는 과거 내역이 필요할 때만 추가 참조한다.

복사·연결 절차와 OS별 명령, 환경변수·로그는 `assets/README.md`와 `assets/HOOK-README.md`에 있다. 청사진에는 "Phase 8: assets의 hooks·viewer를 `.claude/`로 복사하고 Stop hook 등록(Node.js 필요)"으로 표기한다.

## 표준 Unity 개발 하네스 구성

아래 5개 역할을 기본 후보로 둔다. 게임 범위·작업 성격에 따라 일부를 빼거나 합친다.

| Agent 파일 | 역할 | 언제 포함하나 |
| --- | --- | --- |
| `.claude/agents/unity-architect.md` | 설계/아키텍처 — Manager/Module/Service 구조, 시스템 책임 분리 | 신규 설계, 큰 기능 추가 |
| `.claude/agents/gameplay-engineer.md` | 게임플레이 구현 — C# 스크립트 작성 | 거의 항상 |
| `.claude/agents/debugger.md` | 버그 수정/디버깅 — 에러 분석, 원인 추적, 패치 | 버그 수정, 운영 단계 |
| `.claude/agents/code-reviewer.md` | 코드 리뷰/리팩토링 — 컨벤션, 성능, 책임 분리 점검 | 거의 항상(검증 책임) |
| `.claude/agents/unity-ai-operator.md` | Unity 에디터에 MCP로 명령 — 테스트 작성, 씬·에셋 구성, GameObject/컴포넌트 조작 위임 | MCP for Unity(CoplayDev) 연동 시 |

테스트 작성과 에셋·씬 구성은 `unity-ai-operator`가 직접 수행하지 않고 Unity 에디터에 MCP 도구로 위임한다(플레이 모드 테스트 생성, 씬에 프리팹 배치, 플레이스홀더 에셋 생성 등). MCP 연동이 없으면 이 Agent 대신 수동 체크리스트를 Orchestrator에 둔다.

4단계 검증 게이트의 1~3단계는 Stop hook으로 자동 수행한다. Gate 1(`unity-validate.*`)은 컴파일 에러, Gate 2(`unity-validate.*`)는 Play 모드 진입 후 콘솔 에러를 확인한다. Gate 3(`gate3-test-runner.*`)은 `.claude/hooks/.viewer-state/gate3-test.json`에 정의된 테스트를 Play 모드에서 `gate3_run_test` MCP 도구로 실행한다. `Assets/` 아래 `.cs` 파일을 만들거나 수정할 때마다 `gate3-test.json`도 함께 갱신해야 한다. 에러가 있으면 Claude Stop을 차단해 수정 루프로 이어간다. MCP가 없으면 1~3단계를 "수동 검증 필요"로 표시한다.

Unity MCP 도구 사용 규칙, 자동 검증 hook 동작, 위임 패턴은 `references/unity-ai-mcp-guide.md`를 읽는다.

## 실행 하네스 구성 위치

| 목적 | 위치 |
| --- | --- |
| 프로젝트 안내·라우팅 | `CLAUDE.md` |
| Agent 정의 | `.claude/agents/{agent-name}.md` |
| 작업 Skill | `.claude/skills/{skill-name}/SKILL.md` |
| Orchestrator Skill | `.claude/skills/unity-dev-orchestrator/SKILL.md` |
| 결과 확인 뷰어 hooks | `.claude/hooks/` |
| 설계·검토·기록 | `artifacts/` |
| 실제 C# 코드 | `Assets/Scripts/` 등 정규 위치 |
| 산출물 지도 | `artifacts/README.md` |
| 개선 기록 | `artifacts/improvement-log.md` |

`CLAUDE.md`에는 전체 실행 규칙을 길게 복사하지 않는다. 하네스 존재, 자연어 라우팅, 주요 위치, Unity 프로젝트 규칙, 변경 이력 같은 포인터를 둔다.

## Agent Team 실행 기준

Agent Team으로 간주하려면 Agent 정의 파일만으로는 부족하고, Orchestrator Skill 안에 `TeamCreate`, `TaskCreate`, `TaskUpdate`, `TaskGet`, `SendMessage`, `TeamDelete` 흐름과 파일 산출물 계약이 있어야 한다.

Agent Team을 쓰기 좋은 경우: 설계 결정이 구현 방향을 바꿀 때, 구현자-리뷰어가 컴파일 에러·컨벤션을 주고받을 때, 디버거가 찾은 원인이 리팩토링 범위를 바꿀 때, 여러 시스템을 병렬로 만들고 통합할 때. 단일 스크립트 작성이나 작은 버그 한 개 수정은 단일 흐름으로 둔다.

팀 규모는 작게 시작한다. 1인 작업은 2-3명, 소규모 팀 작업도 보통 5명을 넘기지 않는다. 자세한 팀 계약은 `references/agent-team-design.md`를 읽는다.

## 참조 문서

- `references/harness-principles.md`: 설계 원칙, 품질 기준, 피해야 할 것, 하네스 7요소
- `references/harness-design-workflow.md`: 청사진 게이트, Phase 0-8, 게임 범위 분기, Phase 8 뷰어
- `references/agent-team-design.md`: Agent/Skill/Orchestrator 구분, 실행 모드, Agent Team 계약, 팀 패턴, Agent 파일 구조
- `references/unity-ai-mcp-guide.md`: MCP for Unity(CoplayDev) 연동, 자동 검증 hook, unity-ai-operator 위임 패턴
- `references/orchestrator-artifacts-template.md`: 청사진·Agent·Skill·Orchestrator·`CLAUDE.md`·`artifacts/` 템플릿
- `references/testing-qa-evolution.md`: 컴파일 검증, 플레이 테스트, drift, 개선 기록
