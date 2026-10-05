# 하네스 설계 워크플로우 (Unity 게임 개발)

이 문서는 Phase 0부터 8까지 각 단계를 실제로 어떻게 진행하는지 적은 절차서다. 무엇을 묻고, 무엇을 판단하고, 무엇을 산출하고, 다음 단계로 무엇을 넘기는지를 단계별로 따른다. 설계 원칙·품질 기준은 `harness-principles.md`, Agent/Team 계약은 `agent-team-design.md`를 함께 참조한다.

## 청사진 승인 게이트 (전 단계 공통)

하네스 생성은 항상 두 단계로 갈린다.

1. 청사진 단계: Phase 0~6의 결과를 모아 파일을 만들지 않고 설계안(작업 절차, 산출물 계약, 실행 모드, Agent 역할표, Skill 목록, Orchestrator 흐름, Phase 8 뷰어 연결)을 보여준다. 끝에 "이 구조로 실행 가능한 하네스를 구성해드릴까요?"로 승인을 요청한다.
2. 구성 단계: 직전 청사진에 명시적으로 승인받으면 그때 파일을 만든다.

청사진을 보여주기 전에는 어떤 표현도 파일 생성 승인으로 해석하지 않는다. 즉 Phase 0~6은 청사진을 만드는 과정이고, Phase 7~8은 승인 후 실행 단계에 해당한다.

---

## Phase 0. 현재 상황 확인 + 필수 입력 수집

**목적**: 무엇을, 어떤 조건에서 만드는지 확정한다. 이 입력이 이후 모든 단계의 Agent 구성과 검증 기준을 결정한다.

**핵심 원칙**: 0-A → 0-B → 0-C → 0-D 순서로 **반드시** 진행한다. 사용자의 첫 메시지에 일부 정보가 있어도 이 절차를 생략하지 않는다. 특히 0-C의 4개 질문은 어떤 경우에도 건너뛰지 않는다(파일에서 추정 불가하거나 추정이 틀리면 Agent 구성이 어긋남).

---

### 0-A. 프로젝트 자동 읽기

다음을 조용히 읽고 파악한다(사용자에게 묻지 않음).

| 대상 | 파악할 것 |
| --- | --- |
| 프로젝트 루트 / `Assets/` | 폴더 구조, 기존 시스템(Manager·Module 등), 코딩 컨벤션 단서 |
| `Packages/manifest.json` | 설치된 패키지(URP/HDRP, 2D Tilemap, Cinemachine 등) → 2D/3D 추정 단서 |
| 기존 `.claude/agents`, `.claude/skills`, `.claude/hooks`, `CLAUDE.md` | 기존 하네스 유무, 신규/기존확장/유지보수 판단 |
| 기존 `artifacts/` | 이전 실행 기록 |
| `artifacts/improvement-log.md` | 직전 회고·원인·반영·다음 테스트. 있으면 그대로 읽고 0-B 확인에 활용 |
| `artifacts/chain-log.md` | `improvement-log.md`를 축약해 누적한 참조 로그. 과거 작업 흐름 전체가 필요할 때만 수동 또는 자동 추가 참조 |
| `ProjectSettings/` (선택) | 렌더 파이프라인, 입력 시스템 종류 |

읽지 못한 항목은 "추정 불가"로 표시한다. 추정 가능한 항목은 추정값을 적어두되, 0-B에서 사용자 확인을 받는다.

---

### 0-B. 읽은 내용 확인 (간단)

0-A에서 파악한 내용을 4~6줄로 요약해 사용자에게 보여준다.

```
프로젝트를 살펴봤습니다:
- 폴더 구조: Assets/Scripts/{Player, Common, ...}, 네이밍은 PascalCase
- 패키지로 보아 2D 프로젝트로 추정 (com.unity.2d.tilemap 설치됨)
- 기존 하네스 없음 (신규 구축으로 진행)
- (그 외 파악한 것)

위 내용 맞나요? 빠지거나 다른 부분이 있으면 알려주세요.
```

사용자 응답이 오기 전까지 0-C로 넘어가지 않는다. 사용자가 수정·보완하면 반영하고 다음 단계로.

---

### 0-C. 필수 질문 (무조건 묻기)

아래 4개는 **사용자의 첫 메시지나 프로젝트 파일에 답이 있는 것처럼 보여도 반드시 다시 확인한다.** (4번은 답이 "없음"이어도 질문 자체는 반드시 한다.)

#### 질문 방식

**우선: 인터랙티브 선택지 UI** — VSCode Claude 플러그인, Claude 앱 등 클라이언트가 클릭 가능한 선택지 입력을 지원하면 그것을 사용한다. 사용자는 버튼을 눌러 답한다. 한 응답에 네 질문을 묶어 한꺼번에 묻는 것을 우선한다.

**폴백: 텍스트 선택지** — 인터랙티브 UI를 못 쓰는 환경(순수 터미널 등)에서는 아래 형식으로 번호 매긴 선택지를 출력하고 사용자가 번호로 답하게 한다.

```
1. 어떤 게임을 만드시나요?
   1) 2D 캐주얼·퍼즐 (가벼운 입력·UI 중심)
   2) 2D 플랫포머 (물리·충돌·이동 중심)
   3) 3D 액션·RPG (카메라·전투·상태 시스템)
   4) 장르무관 (아키텍처·구조 설계 중심)
   5) 프로토타입 (빠른 검증, 얇은 하네스)

2. 지금 하려는 일은?
   1) 새 시스템 설계
   2) 기존에 기능 추가
   3) 버그 수정
   4) 리팩토링·구조 개선

3. Unity MCP(MCP for Unity)를 연결해 두셨나요?
   1) MCP for Unity 연결됨
   2) 아직 없음

4. 하네스 구성 시 참조할 문서(코딩 컨벤션 등)가 있나요?
   1) 있음 → 경로 입력
   2) 없음
```

질문 4에서 "있음"을 선택하면 이어서 문서 경로를 텍스트로 입력받는다. 여러 개면 콤마로 구분해 모두 받는다.

#### 선택지 내용 (UI/텍스트 공통)

| 입력 항목 | 선택지 |
| --- | --- |
| 게임 차원/장르 | 2D 캐주얼·퍼즐 / 2D 플랫포머 / 3D 액션·RPG / 장르무관(아키텍처 중심) / 프로토타입 |
| 작업 성격 | 신규 설계 / 기능 추가 / 버그 수정 / 리팩토링·구조 개선 |
| Unity MCP 연동 여부 | MCP for Unity 연결됨 / 아직 없음 |
| 참조 문서 경로 | 있음(경로 입력) / 없음 |

#### 왜 무조건 다시 확인하는가
- **장르**: 파일에서 추정 불가. 같은 2D여도 퍼즐과 플랫포머는 강조 시스템이 다름.
- **작업 성격**: 사용자의 의도. 신규/기능추가/버그/리팩토링에 따라 Agent 구성이 갈림.
- **MCP 연동 여부**: 환경 의존. 추정이 틀리면 unity-ai-operator의 동작 가정이 깨짐.
- **참조 문서 경로**: 프로젝트마다 컨벤션 문서 위치·존재 여부가 다르고 파일에서 자동 추정할 수 없음. 답이 있으면 그 문서를 읽어 Phase 5 Skill 설계에 그대로 반영한다(추정으로 대체하지 않는다).

#### 참조 문서 경로를 받았을 때

- 답변으로 받은 경로를 실제로 열어 읽는다. 존재하지 않거나 못 읽으면 사용자에게 알리고 다시 확인한다.
- 읽은 내용은 요약해 `artifacts/00-input.md`에 남기고, Phase 5에서 해당 Agent의 Skill(예: gameplay-engineer의 C# 컨벤션 가이드)을 작성할 때 이 문서 내용을 우선 기준으로 삼는다.
- "없음"이면 0-A에서 파악한 기존 코드의 컨벤션 단서로 추정해 Phase 5에서 진행한다.

---

### 0-D. 보조 입력 (추정·기본값 허용)

프로젝트 규모(1인 작업 / 소규모 팀)와 그 외 부수 정보는 자동 추정하거나 기본값을 쓴다. 추정이 어렵거나 영향이 크다고 판단될 때만 추가로 묻는다.

---

### 신규/기존확장/유지보수 분기

0-A에서 파악한 상태에 따라 처리 범위가 갈린다.

| 상황 | 처리 |
| --- | --- |
| 신규 구축 | Phase 1부터 전체 진행 |
| 기존 확장 | 기존 `.claude/agents`, `.claude/skills`, `CLAUDE.md`, `artifacts/`를 읽고 필요한 Phase만 다시 |
| 운영·유지보수 | Phase를 새로 돌기 전에 본문 끝 "성숙도 진단"과 "drift 점검"으로 현재 하네스를 평가 |

---

마지막으로 0-A~0-D의 결과를 모아 7요소(목표·컨텍스트·도구·중간 산출물·검증·권한과 승인·기록과 개선)를 채운다. 빈칸은 `확인 필요`로 남긴다.

**산출물**: `artifacts/00-input.md` (요청 요약, 자동 파악 + 사용자 확인 결과, 필수 질문 4개 답 + 참조 문서 경로와 그 내용 요약, 7요소 초안, 확인 필요 목록).

**다음 단계로 넘길 것**: 확정된 게임 범위·작업 성격·MCP 연동 여부·참조 문서 경로(있으면 요약 포함). 이 넷이 Phase 3·4·5의 분기 기준이 된다.

---

## Phase 1. 작업 분해

**목적**: 최종 산출물에 이르기까지 필요한 작업 단계와 그 선후 관계를 정리한다.

**진행**:

1. 최종 결과에서 거꾸로 짚어, 그 결과를 내려면 무엇이 먼저 끝나야 하는지 단계를 적는다. (예: PlayerController 동작 ← 입력·물리 설계 ← 요구사항 확정)
2. 각 단계를 설계 / 구현 / 검증 / 리뷰 중 어디에 속하는지 분류한다.
3. 단계 간 의존 관계(무엇이 끝나야 무엇을 시작할 수 있는지)와 병렬 가능 지점을 표시한다.

**산출물**: 작업 단계 목록과 의존 관계. 청사진의 "작업 절차" 항목이 된다.

**다음 단계로 넘길 것**: 단계 수와 의존 구조. 이것이 Phase 3에서 단일 흐름·Team 중 무엇을 쓸지 가르는 근거다.

---

## Phase 2. 산출물 정의

**목적**: "무엇이 나오면 성공인가"를 구체 파일·형식으로 못 박는다.

**진행**:

1. 최종 산출물의 형태를 정한다: 동작하는 C# 스크립트, 시스템 설계 문서, 버그 패치, 리팩토링된 코드, 플레이 가능한 씬 등.
2. 각 산출물의 위치를 정한다. 코드·씬·에셋은 `Assets/` 정규 위치, 설계·검토·기록은 `artifacts/`.
3. 중간 산출물(구현 전 설계안 등)을 어디서 사람이 확인할지 정한다.
4. "성공"의 판정 기준을 적는다: 컴파일 통과 + 컨벤션 + 플레이 테스트 시나리오 통과.

**산출물**: 산출물 계약 초안 (단계 → 위치 → 만드는 역할 → 다음에 읽는 역할).

**다음 단계로 넘길 것**: 산출물별 위치와 성공 기준. Phase 6 Orchestrator의 검증·전달 설계에 직접 쓰인다.

---

## Phase 3. 실행 모드와 팀 패턴 선택

**목적**: 단일 흐름 / Subagent / Agent Team 중 무엇으로 돌릴지, 어떤 협업 패턴을 쓸지 정한다.

**진행**:

1. Phase 1의 단계 수와 의존 구조를 본다. 단계가 적고 토론이 필요 없으면 단일 흐름.
2. 독립적으로 조사·생성할 덩어리가 있으면 Subagent.
3. 설계 결정이 구현을 바꾸거나, 구현자-리뷰어가 컴파일 에러·컨벤션을 주고받거나, 여러 시스템을 병렬로 만들고 통합해야 하면 Agent Team.
4. Team이면 패턴을 고른다: Pipeline(설계→구현→검증→리뷰), Producer-Reviewer(구현자-리뷰어 왕복), Fan-out/Fan-in(병렬 후 통합), Supervisor(작업마다 담당 재배정).

작업 성격별 기본 조정:

| 작업 성격 | 조정 |
| --- | --- |
| 신규 설계 | architect → gameplay-engineer → reviewer 풀 파이프라인 |
| 기능 추가 | 기존 구조 읽기 우선, architect는 영향 범위만 |
| 버그 수정 | debugger 중심, gameplay-engineer는 패치 적용 |
| 리팩토링 | code-reviewer + architect 중심, 테스트로 회귀 방지 |

**산출물**: 선택한 실행 모드와 패턴, 그 이유.

**다음 단계로 넘길 것**: 모드 결정. 단일 흐름이면 Phase 4에서 Agent를 최소화하고, Team이면 Phase 6에서 팀 계약을 설계한다.

---

## Phase 4. Agent 설계

**목적**: 누가 어떤 역할을 맡을지 정한다.

**진행**:

1. 표준 5개 역할(unity-architect, gameplay-engineer, debugger, code-reviewer, unity-ai-operator)에서 이번 작업에 필요한 것만 고른다.
2. 게임 범위·MCP 연동에 따라 조정한다.

   | 게임 범위 | 강조 / 조정 |
   | --- | --- |
   | 2D 캐주얼·퍼즐 | gameplay-engineer 중심, 설계 가볍게. 입력·UI·상태 머신 강조 |
   | 2D 플랫포머 | architect가 물리·충돌 책임 분리, gameplay-engineer가 이동·점프 |
   | 3D 액션·RPG | architect 비중 높임, code-reviewer 필수 |
   | 장르무관(아키텍처) | architect 중심, 구현은 예시 수준 |
   | 프로토타입 | 단일 흐름 또는 2명, 얇은 검증 |

   | MCP 연동 | 조정 |
   | --- | --- |
   | 연결됨 | unity-ai-operator 포함, 컴파일·씬·테스트 위임 |
   | 없음 | unity-ai-operator 제외, 수동 체크리스트로 대체 |

3. 각 Agent에 책임·입력·출력·하지 말아야 할 일을 적는다. (구조는 `agent-team-design.md`의 Agent 파일 템플릿)
4. Agent 수는 보통 3-4개, 최대 5개로 억제한다.

**산출물**: Agent 역할표.

**다음 단계로 넘길 것**: 확정된 Agent 목록. Phase 5에서 각 Agent가 따를 Skill을 붙인다.

---

## Phase 5. Skill 설계

**목적**: 각 역할이 따를 반복 작업법(매뉴얼)을 정한다.

**진행**:

1. Agent마다 반복적으로 따라야 할 작업법이 있는지 본다. (예: gameplay-engineer → C# 컨벤션 가이드, debugger → 디버깅 절차)
2. Phase 0-C에서 받은 참조 문서 경로가 있으면 그 문서를 읽어 해당 내용을 Skill에 그대로 반영한다(임의로 재작성하지 않는다). 경로가 없으면 0-A에서 파악한 기존 코드의 컨벤션 단서로 추정한다.
3. 각 Skill에 트리거 / 절차 / 출력 형식 / 품질 기준 / 예외 처리를 적는다.
4. 일반 작업 Skill에는 `-orchestrator` 접미사를 쓰지 않는다. Orchestrator는 Phase 6에서 따로 만든다.

**산출물**: Skill 목록과 각 Skill 개요.

**다음 단계로 넘길 것**: Skill 목록. Phase 6에서 Orchestrator가 어떤 단계에 어떤 Skill을 호출할지 엮는다.

---

## Phase 6. Orchestrator 설계

**목적**: 작업 순서, 전달물, 검증, 실패 시 대응을 하나로 묶는다.

**진행**:

1. `unity-dev-orchestrator` Skill을 설계한다. 폴더명·`name`은 `-orchestrator`로 끝낸다.
2. 실행 모드 확인 단계를 넣는다: `artifacts/`를 보고 초기 실행 / 부분 재실행 / 새 실행을 가른다. 후속 키워드("다시", "기능 추가", "이 버그만", "이전 설계 기반", "리팩토링")를 분기에 포함한다.
3. Phase 2의 산출물 계약을 작업 순서에 박는다: 각 단계의 담당 Agent, 입력 파일, 출력 위치(코드 `Assets/`, 문서 `artifacts/`), 완료 기준.
4. 검증 지점을 넣는다: 컴파일(연동 시 unity-ai-operator 위임, 미연동 시 수동 체크리스트), 플레이 테스트 시나리오, code-reviewer 점진 검토.
5. 사람 승인 지점을 명시한다: 씬·에셋 변경, 대규모 리팩토링.
6. 실패 처리를 넣는다: 컴파일 에러 → debugger → 수정 → 1회 재검증, 입력 부족 → 질문 후 멈춤.
7. Team 모드면 `TeamCreate`/`TaskCreate`/`TaskUpdate`/`TaskGet`/`SendMessage`/`TeamDelete` 흐름을 포함한다. (계약 상세는 `agent-team-design.md`)

**산출물**: Orchestrator 흐름 초안. 여기까지가 청사진의 마지막 조각이다. → 청사진 승인 게이트.

**다음 단계로 넘길 것**: 승인되면 Phase 7로 실제 파일 생성.

---

## Phase 7. 검증과 개선

**목적**: 4단계 검증 게이트를 돌리고, 다음번을 위한 개선 기록 자리를 만든다.

**진행**:

1. 4단계 검증 게이트를 실행한다: ①컴파일(Gate 1, `unity-validate.*`) ②Play 모드 콘솔 에러(Gate 2, `unity-validate.*`) ③기능 테스트(Gate 3, `gate3-test-runner.*` + `gate3-test.json`) ④사용자 확인. **①~③의 자동 검증은 MCP 연동 시에만 수행한다.** MCP 미연동이면 ①~③을 건너뛰고 "수동 검증 필요" 상태로 남긴 뒤 02-validation에 수동 체크리스트를 적고 바로 ④로 넘어간다. 1~3은(연동 시) 자동, 각 단계는 게이트라 막히면 멈추고 보고→수정→해당 단계 재검증. (상세는 `testing-qa-evolution.md`)
2. 검증 결과를 `artifacts/02-validation.md`에 기록한다.
3. `artifacts/improvement-log.md`를 만들어 개선 기록 양식을 둔다.
4. `artifacts/README.md`(산출물 지도)를 만들어 결과 위치와 다음 실행이 읽을 것을 적는다.

**산출물**: `artifacts/02-validation.md`, `artifacts/improvement-log.md`, `artifacts/README.md`.

**다음 단계로 넘길 것**: 쌓인 `artifacts/` 기록과 후속조치 항목 → Phase 8 뷰어가 읽고, 4단계 사용자 피드백은 뷰어에서 제출받는다.

---

## Phase 8. 결과 확인 뷰어 (hooks)

**목적**: 7단계까지 쌓인 실행 기록과 사람이 후속조치해야 할 항목을 hooks가 HTML 뷰어로 띄워 한눈에 확인하게 한다. 4단계 사용자 피드백을 뷰어에서 입력·submit해 `artifacts/04-user-feedback.md`로 자동 저장한다.

**중요: hooks 스크립트와 viewer.html을 직접 작성하지 않는다.** 자산은 이 스킬의 `assets/` 폴더에 이미 있다. 아래 진행은 그 자산을 복사·연결하는 것이다.

**진행**:

1. 스킬의 `assets/hooks`를 프로젝트로 복사한다.
   - `assets/hooks/*` → `.claude/hooks/` (뷰어 런처 4종 + `viewer/server.js`·`package.json`·`viewer.html` + Gate 1·2 검증 `unity-validate.sh`·`unity-validate.ps1` + Gate 3 검증 `gate3-test-runner.sh`·`gate3-test-runner.ps1`)
   - macOS/Linux면 `chmod +x .claude/hooks/open-viewer.sh .claude/hooks/open-viewer.command .claude/hooks/unity-validate.sh .claude/hooks/gate3-test-runner.sh`
2. OS에 맞는 settings를 병합한다.
   - Windows: `assets/settings.windows.json` → `.claude/settings.local.json`(또는 `.claude/settings.json`의 `hooks.Stop`에 병합)
   - macOS/Linux: `assets/settings.macos.json` → 동일
   - 기존 settings가 있으면 덮어쓰지 말고 `hooks.Stop`만 병합. 상세는 `assets/settings.template.md`.
3. 이후 Stop hook이 자동 실행되어 다음을 순서대로 수행한다.
   - **(1) Gate 1·2 자동 검증**: `unity-validate.*`가 컴파일 에러(Gate 1)와 Play 모드 진입 후 콘솔 에러(Gate 2)를 확인하고 `artifacts/02-validation.md`를 갱신한다. 에러가 잡히면 `{"decision":"block"}`으로 Claude Stop을 막고 수정 루프로 잇는다. MCP가 안 떠 있으면 막지 않고 "수동 검증 필요"로 기록한다.
   - **(2) Gate 3 기능 테스트**: `gate3-test-runner.*`가 Play 모드에서 `gate3_run_test` MCP 도구를 호출해 `.claude/hooks/.viewer-state/gate3-test.json`에 정의된 테스트를 실행한다. 실패 시 Claude Stop을 막고 수정 루프로 잇는다.
   - **(3) 뷰어 오픈**: 런처가 `viewer/`의 Node 서버(`server.js`, Express)를 띄운다(최초 실행 시 `npm install`).
   - 서버가 이미 떠 있으면 재사용하고 브라우저만 연다. 포트 충돌·헬스체크 실패 시 이전 node 프로세스를 정리하고 새로 띄운다.
   - 브라우저로 viewer를 열어 `artifacts/`를 자동 로드한다.
4. viewer가 `artifacts/`를 읽어 아래를 표시한다.

   | 항목 | 출처 |
   | --- | --- |
   | 단계별 산출물 요약 | `artifacts/00-input.md` ~ `artifacts/03-review.md` |
   | 4단계 게이트 상태 | `artifacts/02-validation.md`의 "게이트 진행 요약" 표 (MCP 미연동이면 1~3은 "수동 검증 필요"로 표시) |
   | 미해결 이슈·승인 대기 | `artifacts/02-validation.md`, `artifacts/03-review.md` |
   | 개선 기록 | `artifacts/improvement-log.md` |
   | 4단계 사용자 피드백 입력 | submit 시 서버가 `artifacts/04-user-feedback.md`로 저장 |

**설계 원칙**:

- 자산은 스킬의 `assets/`에 동봉되어 있다. 새로 만들지 말고 복사·연결만 한다. 복사·연결 절차는 `assets/README.md`, 동작·환경변수·로그는 `assets/HOOK-README.md` 참조.
- **Stop hook 등록 순서**: `hooks.Stop` 배열에 `unity-validate.*`(Gate 1·2) → `gate3-test-runner.*`(Gate 3) → `open-viewer.*`(뷰어) 순서로 등록한다. 검증이 모두 끝난 뒤 뷰어가 열려야 최신 게이트 상태를 읽는다.
- 자동 검증은 PowerShell(Windows) 또는 셸 스크립트(macOS/Linux)가 필요하다. MCP for Unity가 안 떠 있어도 안전하게 "수동 검증 필요"로 빠지므로, 연동/미연동 프로젝트에 같은 settings를 써도 된다.
- **Node.js가 필요하다.** 미설치 시 자동 오픈이 동작하지 않는다.
- `02-validation.md`가 없어도 viewer는 열린다(검증 출력 없으면 경고만).
- viewer는 `artifacts/`를 읽고, 4단계 피드백만 `artifacts/04-user-feedback.md`에 쓴다. 코드·씬·에셋은 절대 바꾸지 않는다.

### 마무리: 개선 기록 갱신 + 체인 로그 축약본 누적

뷰어 확인과 4단계 피드백까지 끝나면, 다음 실행의 0단계가 바로 이어받을 수 있도록 `artifacts/improvement-log.md`를 **통째로 덮어써서(overwrite) 이번 실행 1건만 남긴다.** 이전 내용에 이어붙이지(append) 않는다 — 이 파일은 "가장 최근 실행"만 담는 단일 스냅샷이며, 대화(세션)가 바뀌어도 이전 실행 내용이 계속 쌓이면 안 된다. 이전 실행 내용은 덮어쓰기 전에 이미 `chain-log.md`에 축약돼 있어야 한다(없으면 덮어쓰기 직전에 먼저 축약해 append). 이 파일은 체인 로그의 요약본이 아니라, 다음 실행이 그대로 읽어야 하는 작업 회고·원인·반영·다음 테스트 기록이다.

`artifacts/chain-log.md`는 별도로 **`improvement-log.md`의 축약본**을 누적한다. 목적은 원문/raw 로그를 쌓는 것이 아니라, 나중에 참조 가능한 작업 이력 요약본을 남기는 것이다. 다음 실행의 기본 입력으로 사용하지 않으며, 과거 작업 흐름 전체가 필요할 때만 수동 또는 자동으로 추가 참조한다.

- `improvement-log.md`
  - 위치: `artifacts/improvement-log.md`
  - 역할: 다음 실행 Phase 0-A의 기본 연속 작업 컨텍스트
  - 포함 내용: 무엇이 아쉬웠나, 원인, 반영, 다음 테스트, 하네스 자체 개선 메모
- `chain-log.md`
  - 위치: `artifacts/chain-log.md` (없으면 헤더와 함께 생성, 있으면 맨 아래 append)
  - 역할: `improvement-log.md`의 누적 축약본. 기본 Phase 0 입력 아님
  - 포함 내용: 날짜, 작업 요약, 4단계 결과, 핵심 개선점, 다음 입력

예시 (`artifacts/chain-log.md`):

```md
# 체인 로그

이 프로젝트에서 하네스로 진행한 작업 이력의 축약본. 한 실행이 끝날 때 improvement-log.md의 핵심만 요약해 누적한다.
Phase 0의 기본 입력은 improvement-log.md이며, 이 파일은 과거 내역 확인이 필요할 때만 참조한다.

---

## 2026-06-17 · 2D 플랫포머 PlayerController 신규
- 4단계: ①②✅ ③❌→✅ ④수정필요
- 개선점: 구현이 설계의 grounded 조건을 누락(공중 무한 점프) → reviewer에 설계↔구현 매칭 체크 추가
- 다음 입력: 점프 입력 버퍼 도입

---

## 2026-06-18 · 점프 입력 버퍼 도입
- 4단계: ①②③✅ ④통과
- 개선점: 착지 직후 입력 누락 → FixedUpdate 타이밍 버퍼로 해결, 컨벤션에 입력 버퍼 패턴 추가
- 다음 입력: -
```

다음 실행의 Phase 0-A(자동 읽기)는 `improvement-log.md`를 먼저 읽어 직전 회고·원인·반영·다음 테스트를 파악하고, 0-B 확인 단계에서 "직전 개선 기록 기준으로 X가 남아 있습니다. 맞나요?"처럼 확인한다. `chain-log.md`는 사용자가 과거 내역을 요구하거나 현재 개선 기록만으로 맥락이 부족할 때만 추가로 읽는다.

**산출물**: `.claude/hooks/`로 복사된 자산 + settings의 Stop hook 등록 + (사용자 피드백 제출 후) `artifacts/04-user-feedback.md` + `artifacts/improvement-log.md`(덮어쓰기, 최신 1건만) + `artifacts/chain-log.md`(improvement-log 축약본 영구 append).

---

## 부록 A. 하네스 성숙도 진단

"내 작업이 하네스에 맞는지 봐줘" 같은 요청에는 Phase를 새로 돌기 전에 현재 수준을 진단한다.

| 수준 | 신호 | 다음 단계 |
| --- | --- | --- |
| Lv0 비정형 | 매번 즉흥적으로 AI에게 요청 | 반복 작업을 1개 식별 |
| Lv1 단일 매뉴얼 | 자주 쓰는 프롬프트가 있음 | Skill로 추출 |
| Lv2 역할 분리 | 설계·구현·검토를 나눔 | Agent 분리 |
| Lv3 오케스트레이션 | 순서·전달·검증이 있음 | Orchestrator + artifacts |
| Lv4 진화 | 실패·피드백으로 개선 | improvement-log 운영 |

## 부록 B. 하네스 두께 조절

| 작업 위험도 | 두께 |
| --- | --- |
| 프로토타입, 단발 스크립트 | 얇게 — 빠른 생성, 가벼운 검증 |
| 핵심 게임플레이 시스템 | 중간 — 컴파일 + 리뷰 + 플레이 테스트 |
| 씬 대규모 변경, 에셋 삭제, 빌드 영향 | 두껍게 — 사람 승인 게이트, 백업, 회귀 테스트 |
