# Claude Code hook settings template

이 파일은 실제 Claude Code가 읽는 설정 파일이 아닙니다.
OS에 맞는 JSON을 `.claude/settings.json` 또는 `.claude/settings.local.json`에 병합해서 사용하세요.

## Windows

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\\.claude\\hooks\\unity-validate.ps1"
          },
          {
            "type": "command",
            "command": "cmd.exe /c .\\.claude\\hooks\\open-viewer.cmd"
          }
        ]
      }
    ]
  }
}
```

## macOS / Linux

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "sh ./.claude/hooks/unity-validate.sh"
          },
          {
            "type": "command",
            "command": "bash ./.claude/hooks/open-viewer.sh"
          }
        ]
      }
    ]
  }
}
```

`unity-validate`는 1~3단계(컴파일·런타임·기능) 자동 검증 hook이고, `open-viewer`는 결과 확인 뷰어 런처다. 순서대로 등록한다(검증 먼저 → 뷰어). `unity-validate`는 MCP for Unity가 안 떠 있으면 아무것도 막지 않고 02-validation.md만 "수동 검증 필요"로 남긴다.
