#!/bin/sh
# artifacts 폴더 초기화 - 프롬프트 시작 시 실행 (chain-log, improvement-log 제외)
# UserPromptSubmit 훅에 등록

SCRIPT_PATH="$0"
HOOK_DIR="$(CDPATH= cd -- "$(dirname -- "$SCRIPT_PATH")" && pwd)"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-}"
if [ -z "$PROJECT_DIR" ]; then
    PROJECT_DIR="$(CDPATH= cd -- "$HOOK_DIR/../.." && pwd)"
fi
ARTIFACT_DIR="${ARTIFACT_DIR:-$PROJECT_DIR/artifacts}"
STATE_DIR="$HOOK_DIR/.viewer-state"
mkdir -p "$STATE_DIR" 2>/dev/null || true

# 이 시각 이후 수정된 .cs 파일을 unity-validate가 감지할 수 있도록 타임스탬프 기록
date -Iseconds > "$STATE_DIR/last-clear-ts.txt" 2>/dev/null || \
    date '+%Y-%m-%dT%H:%M:%S' > "$STATE_DIR/last-clear-ts.txt" 2>/dev/null || true

if [ -d "$ARTIFACT_DIR" ]; then
    count=0
    for f in "$ARTIFACT_DIR"/*.md; do
        [ -f "$f" ] || continue
        name="$(basename "$f")"
        case "$name" in
            chain-log.md|improvement-log.md) continue ;;
        esac
        rm -f "$f" && count=$((count + 1))
    done
    [ "$count" -gt 0 ] && printf 'artifacts cleared (%d files)\n' "$count" >&2
fi

exit 0
