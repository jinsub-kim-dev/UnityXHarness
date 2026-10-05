# Unity Dev Harness Viewer - Express Port Fix + macOS Launcher

## Layout

```txt
<project>/
├─ artifacts/
└─ .claude/
   └─ hooks/
      ├─ open-viewer.cmd       # Windows manual wrapper
      ├─ open-viewer.ps1       # Windows PowerShell launcher
      ├─ open-viewer.sh        # macOS/Linux launcher
      ├─ open-viewer.command   # macOS Finder double-click wrapper
      └─ viewer/
         ├─ package.json
         ├─ server.js
         └─ viewer.html
```

## Windows manual test

```powershell
cd C:\Works\Ref\AIOFramework-main
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\.claude\hooks\open-viewer.ps1
```

or

```powershell
cd C:\Works\Ref\AIOFramework-main
.\.claude\hooks\open-viewer.cmd
```

## macOS manual test

```bash
cd /path/to/project
chmod +x ./.claude/hooks/open-viewer.sh
./.claude/hooks/open-viewer.sh
```

Finder double-click test:

```bash
chmod +x ./.claude/hooks/open-viewer.command
open ./.claude/hooks/open-viewer.command
```

Agent/hook command on macOS:

```bash
./.claude/hooks/open-viewer.sh
```

## Behavior

- If the same viewer server is already running, it reuses the server and only opens the browser.
- If the recorded previous port is occupied but the health check fails or points to another artifact directory, it stops the old Node process on that port and starts a fresh server.
- By default, it only kills `node` processes. To allow killing non-Node processes on the recorded port, set `VIEWER_KILL_NON_NODE=1`.
- It no longer skips opening the browser based on `opened-*` session marker files (that mechanism was removed).
- `02-validation.md` is not required to open the viewer. Missing validation output is logged as a warning.
- **Change-detection gate (new)**: Stop fires on every assistant turn, not just once per conversation. Running the full MCP round-trip (compile wait + Play mode enter/exit) and reopening a browser tab on *every* turn felt like the hook was hanging. `CLAUDE_SESSION_ID` turned out to be the wrong signal for this (in some environments it doesn't rotate per conversation, causing a permanent skip). Instead, both `unity-validate.*` and `open-viewer.*` track a `last-*-ts` timestamp file and skip immediately if no `Assets/**/*.cs` or `artifacts|docs/**/*.md` file has changed since. Set `FORCE_REVALIDATE=1` / `FORCE_REOPEN_VIEWER=1` to bypass the gate for a single run (e.g. manual testing).

## Environment variables

```txt
CLAUDE_PROJECT_DIR      Optional explicit project root.
ARTIFACT_DIR            Optional explicit artifacts directory.
VIEWER_PORT             Optional preferred port.
VIEWER_KILL_NON_NODE=1  Allow killing non-node process on the recorded viewer port.
VIEWER_NO_OPEN=1        Start/reuse server without opening a browser. Useful for script tests.
FORCE_REOPEN_VIEWER=1   Bypass the once-per-conversation gate and reopen the browser this run.
```

## Logs

```txt
<project>/.claude/hooks/open-viewer.bootstrap.log
<project>/.claude/hooks/.viewer-state/open-viewer-cmd.log
<project>/.claude/hooks/.viewer-state/open-viewer.log
<project>/.claude/hooks/.viewer-state/server.stdout.log
<project>/.claude/hooks/.viewer-state/server.stderr.log
<project>/.claude/hooks/.viewer-state/npm-install.log
```

## Claude Code hook settings

Claude Code에서 자동으로 viewer를 열려면 프로젝트 루트의 `.claude/settings.json` 또는 개인용 `.claude/settings.local.json`에 hook 설정을 추가합니다.

제공 파일:

```txt
.claude/settings.windows.json
.claude/settings.macos.json
.claude/settings.template.md
```

권장 방식:

- 혼자 쓰는 로컬 환경: OS에 맞는 내용을 `.claude/settings.local.json`에 복사
- 팀/프로젝트 공통 설정: `.claude/settings.json`에 병합
- Windows/macOS 사용자가 섞이면 실제 `.claude/settings.json` 하나를 강제하지 말고 샘플만 커밋

Windows:

```powershell
copy .claude\settings.windows.json .claude\settings.local.json
```

macOS/Linux:

```bash
cp .claude/settings.macos.json .claude/settings.local.json
chmod +x ./.claude/hooks/open-viewer.sh
```

기존 settings 파일이 이미 있다면 덮어쓰지 말고 `hooks.Stop` 항목만 병합하세요.

## 자동 검증 hook (unity-validate)

`unity-validate.sh`(macOS/Linux) / `unity-validate.ps1`(Windows)은 4단계 검증 게이트의 1~3단계를 자동 수행하는 Stop hook이다. CoplayDev **MCP for Unity**(오픈소스, https://coplaydev.github.io/unity-mcp/)에 HTTP로 붙는다.

동작:

1. MCP 세션 `initialize`. 연결 실패(=MCP 미실행) 시 아무것도 막지 않고 `artifacts/02-validation.md`를 1~3단계 `🔧 수동 검증 필요`로 남기고 종료.
2. `read_console{clear}` → `refresh_unity{force,compile}` + `mcpforunity://editor/state` 폴링(최대 60s) → `manage_editor{play}` → 5s 대기 → `read_console{get,errors}` → `manage_editor{stop}` → Gate3(`gate3_run_test`, `gate3-test.json` 있을 때만).
3. 실패(컴파일 에러/콘솔 에러/Gate3 실패)하면 `{"decision":"block","reason":...}`을 stdout에 출력해 Claude Stop을 차단하고 수정을 유도한다(재시도). 실패가 `VALIDATE_MAX_RETRIES`(기본 2)회를 넘으면 더 이상 차단하지 않고 재시도 카운트를 리셋해 Stop을 통과시킨다(무한 루프 방지).
4. 통과하면 `✅`로 기록하고 재시도 카운트를 리셋한 뒤 종료(차단 없음).

Stop은 대화 중 어시스턴트가 응답을 마칠 때마다(턴마다) 매번 발동한다. MCP 왕복 + Play 모드 진입/종료를 매 턴 반복하면 사실상 멈춘 것처럼 느껴지므로, 마지막 검증 이후 `Assets/**/*.cs` 또는 `artifacts|docs/**/*.md`가 실제로 바뀐 적이 없으면 스킵한다(`.viewer-state/last-validated-ts.txt`). 단, Stop hook 표준 입력의 `stop_hook_active`(이 Stop이 우리 hook의 block으로 인한 재시도 실행인지, https://code.claude.com/docs/en/hooks#stop-input)가 `true`면 파일 변경 여부와 무관하게 항상 재검증한다. 강제로 다시 돌리려면 `FORCE_REVALIDATE=1`.

settings의 `hooks.Stop`에 **뷰어 런처보다 먼저** 등록한다(검증 → 02-validation 갱신 → 뷰어 오픈).

환경변수:

```txt
MCP_URL                  MCP 엔드포인트. 기본 http://127.0.0.1:8080/mcp
CLAUDE_PROJECT_DIR       프로젝트 루트. 미지정 시 hook 위치 기준 ../.. 추정
ARTIFACT_DIR             artifacts 디렉터리. 기본 <project>/artifacts
FORCE_REVALIDATE=1       변경 없음 스킵을 무시하고 강제로 다시 검증
VALIDATE_MAX_RETRIES=2   실패 시 block으로 재시도를 유도하는 최대 횟수(기본 2)
```

**중요(Windows):** `unity-validate.ps1`은 한글 주석과 이모지(⚠️ 등)를 포함하므로 반드시 UTF-8 BOM으로 저장돼야 한다. BOM 없이 저장하면 Windows PowerShell 5.1이 일부 멀티바이트 문자를 오해석해 파싱 에러가 난다. 이 파일을 도구로 전체 재작성할 때는 BOM 유지 여부를 확인한다.

전제: macOS/Linux는 `python3`와 `curl` 필요(없으면 검증 skip, 차단 안 함). Windows는 PowerShell 사용.

수동 테스트:

```bash
# MCP가 떠 있는 상태에서
MCP_URL="http://127.0.0.1:8080/mcp" sh ./.claude/hooks/unity-validate.sh
cat artifacts/02-validation.md
```
