#!/bin/sh
# Gate 3 독립 실행용 스크립트 (수동 테스트 / 디버그용)
# Stop hook에서는 unity-validate.sh가 play mode 안에서 직접 호출함.
# inject:true 테스트 시 play mode 수동 진입 필요.

MCP_URL="${MCP_URL:-http://127.0.0.1:8080/mcp}"
SESSION_ID=""
REQUEST_ID=0

SCRIPT_PATH="$0"
HOOK_DIR="$(CDPATH= cd -- "$(dirname -- "$SCRIPT_PATH")" && pwd)"
STATE_DIR="$HOOK_DIR/.viewer-state"
TEST_FILE="$STATE_DIR/gate3-test.json"
LOG_FILE="$STATE_DIR/gate3-test-runner.log"

TMP_DIR="${TMPDIR:-/tmp}"
BODY_FILE="$TMP_DIR/gate3-runner-body-$$.json"
HEADER_FILE="$TMP_DIR/gate3-runner-headers-$$.txt"
RESPONSE_FILE="$TMP_DIR/gate3-runner-response-$$.txt"

cleanup() { rm -f "$BODY_FILE" "$HEADER_FILE" "$RESPONSE_FILE"; }
trap cleanup EXIT HUP INT TERM

log() {
    level="${2:-INFO}"
    line="[$(date '+%H:%M:%S')][$level] $1"
    printf '[gate3] %s\n' "$line" >&2
    printf '%s\n' "$line" >> "$LOG_FILE" 2>/dev/null
}

printf '\n' >> "$LOG_FILE" 2>/dev/null
printf '%s\n' "============================================================" >> "$LOG_FILE" 2>/dev/null
log "gate3-test-runner started (standalone mode)"

command -v python3 >/dev/null 2>&1 || { log "python3 not found" "WARN"; exit 0; }

if [ ! -f "$TEST_FILE" ]; then
    log "gate3-test.json not found. Skipping." "WARN"
    exit 0
fi

log "Config: $(cat "$TEST_FILE" | tr -d '\n')"

next_id() { REQUEST_ID=$((REQUEST_ID + 1)); printf '%s' "$REQUEST_ID"; }

send_mcp() {
    kind="$1"; rid="$2"; shift 2

    python3 - "$BODY_FILE" "$kind" "$rid" "$@" <<'PY'
import json, sys
path, kind, rid = sys.argv[1], sys.argv[2], sys.argv[3] if len(sys.argv) > 3 else ""
extra = sys.argv[4:] if len(sys.argv) > 4 else []
if kind == "initialize":
    p = {"jsonrpc":"2.0","id":int(rid),"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"gate3-test-runner","version":"2.0"}}}
elif kind == "initialized":
    p = {"jsonrpc":"2.0","method":"notifications/initialized","params":{}}
elif kind == "tool":
    p = {"jsonrpc":"2.0","id":int(rid),"method":"tools/call","params":{"name":extra[0],"arguments":json.loads(extra[1])}}
with open(path,"w",encoding="utf-8") as f: json.dump(p,f,separators=(",",":"))
PY

    if [ -n "$SESSION_ID" ]; then
        curl -sS --max-time 15 -X POST "$MCP_URL" \
            -H "Content-Type: application/json" \
            -H "Accept: application/json, text/event-stream" \
            -H "Mcp-Session-Id: $SESSION_ID" \
            -D "$HEADER_FILE" --data-binary "@$BODY_FILE" -o "$RESPONSE_FILE" >/dev/null || return 1
    else
        curl -sS --max-time 15 -X POST "$MCP_URL" \
            -H "Content-Type: application/json" \
            -H "Accept: application/json, text/event-stream" \
            -D "$HEADER_FILE" --data-binary "@$BODY_FILE" -o "$RESPONSE_FILE" >/dev/null || return 1
    fi

    new_sid="$(python3 - "$HEADER_FILE" <<'PY'
import sys
for line in open(sys.argv[1], encoding="utf-8", errors="replace"):
    name, sep, val = line.partition(":")
    if sep and name.lower() == "mcp-session-id": print(val.strip()); break
PY
)"
    [ -n "$new_sid" ] && SESSION_ID="$new_sid"

    python3 - "$RESPONSE_FILE" <<'PY'
import sys
text = open(sys.argv[1], encoding="utf-8", errors="replace").read().strip()
for line in text.splitlines():
    if line.startswith("data:"): print(line[5:].strip()); raise SystemExit(0)
print(text)
PY
}

# MCP 세션 초기화
log "Connecting to MCP..."
if ! send_mcp "initialize" "$(next_id)" >/dev/null 2>&1; then
    log "MCP not available" "WARN"; exit 0
fi
send_mcp "initialized" "" >/dev/null 2>&1 || true
log "MCP session established (id=$SESSION_ID)"

# gate3-test.json → 툴 arguments JSON 빌드
g3_args="$(python3 - "$TEST_FILE" <<'PY'
import json, sys
cfg = json.load(open(sys.argv[1]))
args = {"type_name": cfg["type_name"]}
if "call_start" in cfg: args["call_start"] = bool(cfg["call_start"])
if "inject" in cfg: args["inject"] = bool(cfg["inject"])
if "check_non_null_fields" in cfg: args["check_non_null_fields"] = cfg["check_non_null_fields"]
print(json.dumps(args))
PY
)"

log "Calling gate3_run_test..."
g3_result="$(send_mcp "tool" "$(next_id)" "gate3_run_test" "$g3_args")" || {
    log "gate3_run_test failed" "ERROR"; exit 0
}

# 결과 파싱
g3_text="$(printf '%s' "$g3_result" | python3 -c '
import json, sys
raw = sys.stdin.read().strip()
if not raw: raise SystemExit(0)
obj = json.loads(raw)
result = obj.get("result") or {}
for item in result.get("content") or []:
    if item.get("type") == "text":
        text = item.get("text") or ""
        try:
            p = json.loads(text)
            print(p.get("message") or p.get("data") or text)
        except:
            print(text)
        raise SystemExit(0)
sc = result.get("structuredContent")
if sc: print(sc.get("message") or sc.get("data") or str(sc))
' 2>/dev/null || true)"

if printf '%s' "$g3_text" | grep -q "^PASS"; then
    log "PASS: $g3_text"
elif printf '%s' "$g3_text" | grep -q "^FAIL"; then
    log "FAIL: $g3_text" "ERROR"
else
    log "RESULT: $g3_text" "WARN"
fi

log "gate3-test-runner finished"
exit 0
