# assets — Phase 8 자산 (복사해서 사용)

이 폴더의 파일들은 **이미 완성된 자산**이다. 스킬이 새로 만들지 않고, Phase 8에서 프로젝트의 `.claude/`로 복사·연결만 한다.

서버는 Node.js(Express) 기반이다. Node.js가 설치돼 있어야 자동 오픈이 동작한다.

## 구성

```
assets/
  hooks/
    open-viewer.sh         macOS / Linux 뷰어 런처 (hook command용)
    open-viewer.command    macOS Finder 더블클릭 런처
    open-viewer.ps1        Windows PowerShell 뷰어 런처
    open-viewer.cmd        Windows 수동 실행 / hook command 래퍼
    unity-validate.sh      macOS/Linux 1~3단계 자동 검증 hook (MCP for Unity)
    unity-validate.ps1     Windows 1~3단계 자동 검증 hook (MCP for Unity)
    viewer/
      server.js            로컬 Express 서버 (artifacts 서빙 + 피드백 저장)
      package.json         의존성(express, chokidar)
      viewer.html          결과 확인 화면
  settings.windows.json    Stop hook 등록용 settings (Windows, 검증+뷰어)
  settings.macos.json      Stop hook 등록용 settings (macOS/Linux, 검증+뷰어)
  settings.template.md     OS별 settings 병합 안내
  HOOK-README.md           hook 자산 원본 README (동작·환경변수·로그 상세)
  artifacts-example/       예제 산출물 (2D 플랫포머 PlayerController 시나리오)
```

## 복사·연결 (Phase 8)

대상 Unity 프로젝트 루트에서 `assets/hooks`를 `.claude/hooks`로 복사하고, OS에 맞는 settings를 병합한다.

Windows
```powershell
# hooks 복사
New-Item -ItemType Directory -Force .claude\hooks | Out-Null
Copy-Item -Recurse -Force <스킬경로>\assets\hooks\* .claude\hooks\
# settings 병합 (기존 settings가 없을 때)
Copy-Item <스킬경로>\assets\settings.windows.json .claude\settings.local.json
```

macOS / Linux
```bash
mkdir -p .claude/hooks
cp -R <스킬경로>/assets/hooks/* .claude/hooks/
chmod +x .claude/hooks/open-viewer.sh .claude/hooks/open-viewer.command .claude/hooks/unity-validate.sh
cp <스킬경로>/assets/settings.macos.json .claude/settings.local.json
```

`<스킬경로>`는 스킬이 설치된 위치다(예: `~/.claude/skills/unity-dev-harness` 또는 프로젝트의 `.claude/skills/unity-dev-harness`).

> 기존 `.claude/settings.json`(또는 `.claude/settings.local.json`)이 이미 있으면 덮어쓰지 말고 `hooks.Stop` 항목만 병합한다. OS가 섞인 팀이면 실제 settings를 강제하지 말고 샘플(`settings.*.json`)만 커밋하는 방식을 권장한다. 상세는 `settings.template.md`.

## 동작 흐름

1. Claude Code가 작업을 마치면 Stop hook이 자동 실행된다(`settings`의 `hooks.Stop`).
2. **자동 검증 hook(`unity-validate.*`)이 먼저 실행**된다. MCP for Unity(`http://127.0.0.1:8080/mcp`)에 붙어 1~3단계(컴파일·런타임·기능)를 수행하고 `artifacts/02-validation.md`를 갱신한다.
   - 콘솔 에러가 있으면 `{"decision":"block"}`을 출력해 Claude Stop을 막고(수정 루프로 이어짐), 게이트 표에 `❌`를 남긴다.
   - MCP가 안 떠 있으면 막지 않고 1~3단계를 `🔧 수동 검증 필요`로 기록한다.
3. 이어서 뷰어 런처가 `viewer/`에서 Node 서버(`server.js`)를 띄운다(최초 실행 시 `npm install`로 express·chokidar 설치).
4. 같은 서버가 이미 떠 있으면 재사용하고 브라우저만 연다. 포트 충돌·헬스체크 실패 시 이전 node 프로세스를 정리하고 새로 띄운다.
5. 브라우저로 viewer를 열어 `artifacts/`를 자동 로드한다.
6. 4단계 사용자 피드백을 submit하면 서버가 `artifacts/04-user-feedback.md`로 저장한다.

`02-validation.md`가 없어도 viewer는 열린다(검증 출력이 없으면 경고만 로깅).

## 환경변수 / 로그

주요 환경변수와 로그 경로는 `HOOK-README.md`를 참조한다. 자주 쓰는 것:

```
CLAUDE_PROJECT_DIR     프로젝트 루트 명시
ARTIFACT_DIR           artifacts 디렉터리 명시
VIEWER_PORT            선호 포트
VIEWER_NO_OPEN=1       브라우저 열지 않고 서버만(스크립트 테스트용)
```

## 전제

- **Node.js 필요** (express 서버). 미설치 시 자동 오픈이 동작하지 않는다.
- **1~3단계 자동 검증에는 CoplayDev "MCP for Unity"가 필요**하다(오픈소스, https://coplaydev.github.io/unity-mcp/). Unity 에디터에 패키지로 설치하고 HTTP(`/mcp`) 서버를 켜 둔다. macOS/Linux는 `python3`+`curl`, Windows는 PowerShell이 추가로 필요하다. MCP가 없으면 검증 hook은 막지 않고 "수동 검증 필요"로만 표시한다.
- 서버는 로컬에서만 동작하며 artifacts 디렉터리를 서빙한다.
