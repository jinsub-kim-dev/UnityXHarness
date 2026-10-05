# Unity 게임 개발 하네스 (unity-dev-harness)

Unity 게임 개발 작업을 Claude Code 하네스로 바꾸도록 돕는 교육용 스킬입니다. 하네스는 AI에게 게임 개발을 맡길 때 필요한 목표·컨텍스트·검증·승인·기록을 Agent / Skill / Orchestrator / hooks 구조로 꺼내, 더 안전하고 반복 가능하게 만드는 작업 환경입니다.

대상: **Unity는 알지만 AI Agent 하네스는 처음인 초중급 개발자**

## 무엇을 하나요

자신의 Unity 프로젝트를 가지고 "이 작업을 AI 팀에게 맡기고 싶다"고 할 때, 이 스킬이 먼저 **청사진**(역할표·흐름·검증)을 보여주고, 승인하면 실제 `.claude/agents`, `.claude/skills`, `.claude/hooks`, `CLAUDE.md`, `artifacts/` 하네스를 만들어 줍니다.

게임 범위(2D/3D·장르), 작업 성격(신규/기능추가/버그/리팩토링), Unity MCP(MCP for Unity) 연동 여부를 입력받아 팀 구성을 조정합니다.

표준 5개 역할:
- **unity-architect** — 설계/아키텍처 (Manager·시스템 구조)
- **gameplay-engineer** — 게임플레이 구현 (C# 스크립트)
- **debugger** — 버그 수정/디버깅
- **code-reviewer** — 코드 리뷰/리팩토링
- **unity-ai-operator** — Unity 에디터에 MCP로 명령 (씬/에셋 구성·테스트 위임). 1~3단계 컴파일·런타임 검증은 unity-validate hook이 자동 수행

> 에셋·씬 구성과 에디터 조작은 unity-ai-operator가 MCP for Unity(CoplayDev)로 위임합니다. MCP 연동이 없으면 수동 체크리스트로 대체합니다.

## 4단계 검증

구현한 기능은 4단계로 검증합니다. 1~3단계는 **CoplayDev의 오픈소스 [MCP for Unity](https://coplaydev.github.io/unity-mcp/)에 연결돼 있으면 Stop hook(`unity-validate`)이 자동으로** 진행하고, 각 단계에서 막히면(콘솔 에러 등) Claude를 멈춰 세워 수정 루프로 잇습니다. MCP가 없으면 1~3단계는 건너뛰고 "수동 검증 필요"로 표시합니다.

1. 컴파일 (`refresh_unity` + 에디터 상태 대기)
2. 런타임 에러 (`manage_editor` play 진입 + 콘솔 에러 확인)
3. 기능 점검 (MCP 자동 · 콘솔 에러 없음 기준 1차 판정)
4. 기능 점검 (사용자가 직접 확인)

검증이 끝나면 hooks가 결과를 HTML 페이지로 자동으로 열어 줍니다(Stop event hook). 4단계는 그 페이지에서 직접 확인 내용을 적고 제출하면 `artifacts/04-user-feedback.md`로 자동 저장됩니다.

> **hooks·뷰어·검증 자산은 스킬의 `assets/` 폴더에 동봉되어 있습니다.** 이 스킬은 자산을 새로 만들지 않고, `assets/`의 `hooks/`·`settings.*.json`을 프로젝트 `.claude/`로 복사·연결만 합니다(자동 검증은 MCP for Unity + python3/curl 또는 PowerShell, 뷰어는 Node.js 필요). 복사 절차는 `assets/README.md`를 참조하세요.

## 설치

개인용 스킬로 설치하면 모든 Claude Code 프로젝트에서 쓸 수 있습니다.

```
mkdir -p ~/.claude/skills
cp -R unity-dev-harness ~/.claude/skills/
```

특정 프로젝트에서만 쓰려면 프로젝트 루트에서:

```
mkdir -p .claude/skills
cp -R unity-dev-harness .claude/skills/
```

Claude Code를 새 세션으로 열면 `/unity-dev-harness`로 호출하거나, 요청이 description과 맞으면 자동으로 사용됩니다.

## 첫 사용 예시

```
/unity-dev-harness 2D 플랫포머 플레이어 컨트롤러 만드는 하네스를 짜줘.
```

청사진을 확인한 뒤 마음에 들면:

```
좋아, 이 구조로 실제 사용할 수 있게 만들어줘.
```

## 구성

```
unity-dev-harness/
  SKILL.md
  references/
    harness-principles.md           설계 원칙·품질 기준·7요소
    harness-design-workflow.md      청사진 게이트, Phase 0-8, 게임 범위 분기
    agent-team-design.md            Agent/Skill/Orchestrator 제작 사양
    unity-ai-mcp-guide.md           MCP for Unity 연동, 자동 검증 hook, 위임 패턴
    orchestrator-artifacts-template.md  청사진·Agent·Skill·Orchestrator·CLAUDE.md 템플릿
    testing-qa-evolution.md         4단계 검증, drift, 개선 기록
  assets/                           Phase 8에서 복사해 쓰는 자산 (직접 만들지 않음, Node.js 필요)
    hooks/
      open-viewer.sh / .command     macOS/Linux 런처 (Finder용 포함)
      open-viewer.ps1 / .cmd        Windows 런처
      viewer/server.js·viewer.html  Express 서버 + 결과 확인 화면
    settings.windows.json           Stop hook 등록용 settings (Windows)
    settings.macos.json             Stop hook 등록용 settings (macOS/Linux)
    settings.template.md            settings 병합 안내
    HOOK-README.md                  hook 동작·환경변수·로그 상세
    artifacts-example/              예제 산출물 (2D 플랫포머 시나리오)
    README.md                       자산 복사·연결 안내
```
