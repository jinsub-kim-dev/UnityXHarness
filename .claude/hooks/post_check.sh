#!/bin/bash
# [PostToolUse] C# 파일 수정 후 FindObjectOfType 사용 감지

INPUT=$(cat)

TOOL_NAME=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_name',''))")
FILE_PATH=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))" 2>/dev/null)

[[ "$TOOL_NAME" != "Write" && "$TOOL_NAME" != "Edit" ]] && exit 0
[[ "$FILE_PATH" != *.cs ]] && exit 0

if grep -q "FindObjectOfType" "$FILE_PATH" 2>/dev/null; then
    python3 -c "import json,sys; print(json.dumps({'decision':'block','reason':sys.argv[1]}))" \
        "[컨벤션 위반] FindObjectOfType 사용이 감지됐습니다: $FILE_PATH\nVContainer DI 주입으로 대체하세요."
    exit 0
fi

exit 0
