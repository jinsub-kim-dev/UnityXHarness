#!/bin/bash
# [PreToolUse] Unity 프로젝트 파일 직접 삭제 차단

INPUT=$(cat)
CMD=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('command',''))" 2>/dev/null)

if echo "$CMD" | grep -qE "rm[[:space:]].*\.(unity|prefab|asset)"; then
    python3 -c "import json; print(json.dumps({'hookSpecificOutput':{'hookEventName':'PreToolUse','permissionDecision':'deny','permissionDecisionReason':'Unity 프로젝트 파일 직접 삭제는 허용되지 않습니다. Unity 에디터를 통해 삭제하세요.'}}))"
    exit 0
fi
exit 0
