# Unity MCP 연동 사양 (unity-ai-operator + 자동 검증 hook 제작용)

## 전제

이 하네스는 **CoplayDev의 오픈소스 "MCP for Unity"**(MIT, https://coplaydev.github.io/unity-mcp/)를 기준으로 한다. Unity 6 에디터 내장 어시스턴트가 아니라, Unity 에디터에 패키지로 설치하는 MCP 서버다.

- 설치: Unity Package Manager → Add package from git URL
  - Stable: `https://github.com/CoplayDev/unity-mcp.git?path=/MCPForUnity#main`
  - Beta: `https://github.com/CoplayDev/unity-mcp.git?path=/MCPForUnity#beta`
- 구조: MCP 클라이언트(Claude Code) ↔ Python 서버(FastMCP) ↔ Unity 에디터 C# 플러그인. 클라이언트는 Unity와 직접 통신하지 않고 중간 Python 서버가 라우팅한다.
- 전송: HTTP(`/mcp`)와 stdio를 지원한다. 멀티 에이전트·여러 에디터 동시 연결에는 HTTP를 쓴다. 기본 엔드포인트는 `http://127.0.0.1:8080/mcp`(자동 검증 hook의 `MCP_URL` 기본값)이며, 환경에 따라 포트는 다를 수 있다.
- 도구 surface: 43개 도구 + 25개 읽기 전용 resource(버전에 따라 변동). 도구 그룹(animation, vfx, ui, testing, probuilder 등)을 세션별로 켜고 끌 수 있다.
- 버전·메뉴·포트는 변동된다. 하네스 문서에 특정 버전을 못박지 말고 "현재 설치된 MCP for Unity의 설정을 따른다"로 쓴다.

## 작업 분담 (Claude 직접 vs Unity MCP 위임)

| 작업 | 주체 |
| --- | --- |
| C# 스크립트 로직 작성·수정 | Claude (gameplay-engineer) |
| 코드 리뷰·리팩토링 판단 | Claude (code-reviewer) |
| 버그 원인 분석 | Claude (debugger) |
| 에셋 refresh·스크립트 컴파일 요청 | Unity MCP 위임 (`refresh_unity`) |
| 에디터 상태(컴파일/리로드/플레이) 조회 | Unity MCP resource (`mcpforunity://editor/state`) |
| 플레이 모드 진입·종료 | Unity MCP 위임 (`manage_editor`) |
| 콘솔 로그·에러 읽기/비우기 | Unity MCP 위임 (`read_console`) |
| GameObject 생성·컴포넌트 부착 | Unity MCP 위임 |
| 씬 구성·프리팹 배치 | Unity MCP 위임 |
| 플레이스홀더 에셋 생성 | Unity MCP 위임 |
| 플레이 모드 테스트 작성·실행 | Unity MCP 위임 |

기준: 코드 작성·판단은 Claude, 에디터 상태를 바꾸거나 조회하는 작업은 Unity MCP에 위임한다.

## 4단계 검증 게이트 1~3단계 자동화 (제공 hook)

이 스킬의 `assets/hooks/`에는 **Stop hook으로 동작하는 자동 검증 스크립트**가 동봉되어 있다. Claude Code가 작업을 마칠 때(Stop) 실행되어, MCP for Unity에 직접 붙어 1~3단계를 자동 수행한다.

- `assets/hooks/unity-validate.sh` (macOS/Linux, `sh` + `python3` + `curl`)
- `assets/hooks/unity-validate.ps1` (Windows, PowerShell)

동작 흐름:

1. `initialize` → `notifications/initialized`로 MCP 세션을 연다. **연결 실패 시(=MCP 미실행) 아무것도 막지 않고**, `artifacts/02-validation.md`를 1~3단계 "🔧 수동 검증 필요"로 기록한 뒤 종료한다.
2. `read_console {"action":"clear"}` — 이전 콘솔 에러를 비워 이번 실행만 판정한다.
3. `refresh_unity {"mode":"force","scope":"all","compile":"request","wait_for_ready":true}` + `mcpforunity://editor/state` 폴링 — **1단계 컴파일**. is_compiling·domain_reload·assets refresh·play_mode 전환이 모두 끝날 때까지 최대 60초 대기.
4. `manage_editor {"action":"play"}` — **2단계 런타임**. 플레이 진입. 컴파일 에러는 보통 여기서 드러난다.
5. 5초 대기 후 `read_console {"action":"get","types":["error"],"count":20}` — **2·3단계**. 에러 라인이 있으면 실패.
6. `manage_editor {"action":"stop"}` — 플레이 종료.

결과 기록(두 곳):

- **Claude Stop 차단**: 에러가 있으면 `{"decision":"block","reason":"<에러 내용>"}`을 출력한다. Claude는 멈추지 않고 그 reason을 받아 수정 작업을 이어간다(= 게이트 실패 → 자동으로 디버깅 루프).
- **`artifacts/02-validation.md`**: 매 실행 시 "게이트 진행 요약" 표를 자동 기록한다. 통과는 `✅ 통과`, 실패는 `❌ 실패`, MCP 미연동은 `🔧 수동 검증 필요`. viewer가 이 표를 읽어 게이트 상태를 표시한다.

설치는 Phase 8의 hooks 복사·settings 병합에 포함된다. settings의 `hooks.Stop`에 `unity-validate`를 **viewer 런처보다 먼저** 등록한다(검증 먼저 → 뷰어 오픈).

> 3단계 자동 점검은 "콘솔 에러 없음" 기준의 1차 판정이다. 의도한 동작의 정확성(예: 점프가 지면에서만 되는가)은 4단계 사용자 점검에서 최종 확인한다.

환경변수:

```
MCP_URL              MCP 엔드포인트 (기본 http://127.0.0.1:8080/mcp)
CLAUDE_PROJECT_DIR   프로젝트 루트 (미지정 시 hook 위치 기준 ../.. 추정)
ARTIFACT_DIR         artifacts 디렉터리 (기본 <project>/artifacts)
```

전제: macOS/Linux는 `python3`와 `curl`이 필요하다. 없으면 검증을 건너뛴다(차단하지 않음).

## unity-ai-operator 설계 규칙

대화 중 능동적으로 에디터를 조작하는 작업은 unity-ai-operator가 MCP 도구로 위임한다(자동 검증 hook과 별개로, 작업 단계에서 사용).

- 명령 전 요약·승인: 씬·에셋·GameObject 변경 명령은 변경 내용을 사람에게 요약하고 승인받은 뒤 실행한다.
- 변경 후 검증: 실행 후 `read_console`·`mcpforunity://editor/state`로 에러·컴파일 결과를 확인하고 `artifacts/`에 기록한다.
- 위임 단위: 작은 단위로 위임한다. (예: "PlayerController.cs를 Player에 부착하고 컴파일 확인")
- 실패 처리: 실패·예상 외 결과 시 자동 재시도 1회 후 사람에게 보고한다.

## 위임 메시지 형식

```md
위임 대상: Unity MCP (MCP for Unity)
작업 유형: 컴포넌트 부착 | 씬 구성 | 에셋 생성 | 테스트 작성 | 컴파일/플레이 검증
변경 요약 (사람 승인용):
대상 오브젝트/파일:
사용할 도구: refresh_unity | manage_editor | read_console | manage_gameobject | ...
실행 후 확인할 것:
실패 시 대응:
결과 기록 위치: artifacts/{phase}-unity-mcp-result.md
```

## MCP 미연동 대체 설계

MCP 미연동 시 unity-ai-operator를 제외하고, Orchestrator에 수동 체크리스트를 둔다. Phase 0에서 연동 여부를 확인해 두 경로 중 하나를 선택한다. 자동 검증 hook은 설치돼 있어도 MCP가 안 떠 있으면 스스로 "수동 검증 필요"로 빠지므로, 같은 settings를 두 경우 모두에 써도 안전하다.

```md
## 수동 적용 체크리스트 (MCP 미연동)

1. [ ] gameplay-engineer가 만든 Assets/Scripts/PlayerController.cs 확인
2. [ ] 콘솔에 컴파일 에러 없는지 확인
3. [ ] Player GameObject에 PlayerController 부착
4. [ ] 플레이 모드 진입, 동작 확인
5. [ ] 이상 시 콘솔 에러 복사 → debugger에 전달
```

## 안전 점검

- AI 생성 에셋에는 생성 표시 메타데이터가 붙을 수 있다. 상용 배포 시 사용 권리·스토어 정책은 사람 책임으로 명시한다.
- 씬·프리팹 대규모 변경 전 커밋/백업을 권장 단계로 둔다.
- 자동 검증 hook은 플레이 모드를 진입·종료한다. 저장되지 않은 씬 변경이 있으면 플레이 진입 전 사람이 저장하도록 안내한다.
- MCP 서버는 로컬에서 돈다. 포트·전송(HTTP/stdio) 설정은 환경마다 다르므로 특정 값을 못박지 않는다.
