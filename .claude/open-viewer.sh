#!/usr/bin/env bash
# Re-exec under real bash when invoked via sh / POSIX mode (process substitution is unavailable there).
if [ -z "${BASH_VERSION:-}" ] || ( shopt -qo posix 2>/dev/null ); then
  exec bash "$0" "$@"
fi

# Unity Dev Harness - Express viewer launcher for macOS/Linux
# Location:
#   <project>/.claude/hooks/open-viewer.sh
# Viewer:
#   <project>/.claude/hooks/viewer/server.js
# Artifacts:
#   <project>/artifacts/*.md

set -uo pipefail

BOOTSTRAP_LOG=""
MAIN_LOG=""
STATE_DIR=""
SCRIPT_DIR=""

write_log() {
  local message="$1"
  local level="${2:-INFO}"
  local timestamp
  timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
  local line="[$timestamp][$level] $message"
  printf '%s\n' "$line" >&2
  if [ -n "$BOOTSTRAP_LOG" ]; then
    printf '%s\n' "$line" >> "$BOOTSTRAP_LOG" 2>/dev/null || true
  fi
  if [ -n "$MAIN_LOG" ]; then
    printf '%s\n' "$line" >> "$MAIN_LOG" 2>/dev/null || true
  fi
}

normalize_path() {
  local p="$1"
  if [ -z "$p" ]; then
    printf ''
    return 0
  fi
  if [ -d "$p" ]; then
    (cd "$p" 2>/dev/null && pwd -P) || printf '%s' "$p"
    return 0
  fi
  local d
  local b
  d="$(dirname "$p")"
  b="$(basename "$p")"
  if [ -d "$d" ]; then
    printf '%s/%s' "$(cd "$d" 2>/dev/null && pwd -P)" "$b"
  else
    printf '%s' "$p"
  fi
}

init_bootstrap_log() {
  local source_path="${BASH_SOURCE[0]}"
  SCRIPT_DIR="$(cd "$(dirname "$source_path")" 2>/dev/null && pwd -P)"
  if [ -z "$SCRIPT_DIR" ]; then
    SCRIPT_DIR="$(pwd -P)"
  fi
  BOOTSTRAP_LOG="$SCRIPT_DIR/open-viewer.bootstrap.log"
  {
    printf '\n'
    printf '============================================================\n'
    printf 'Start open-viewer.sh: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')"
    printf '============================================================\n'
  } >> "$BOOTSTRAP_LOG" 2>/dev/null || true
  write_log "BootstrapLog=$BOOTSTRAP_LOG"
}

init_main_log() {
  STATE_DIR="$1"
  mkdir -p "$STATE_DIR"
  MAIN_LOG="$STATE_DIR/open-viewer.log"
  {
    printf '\n'
    printf '============================================================\n'
    printf 'Start open-viewer.sh: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')"
    printf '============================================================\n'
  } >> "$MAIN_LOG"
  write_log "MainLog=$MAIN_LOG"
}

resolve_project_dir() {
  local script_dir="$1"
  write_log "ResolveProjectDir.ScriptDir=$script_dir"
  if [ -n "${CLAUDE_PROJECT_DIR:-}" ]; then
    write_log "Use CLAUDE_PROJECT_DIR=$CLAUDE_PROJECT_DIR"
    normalize_path "$CLAUDE_PROJECT_DIR"
    return 0
  fi
  local dir
  dir="$(normalize_path "$script_dir")"
  while [ -n "$dir" ] && [ "$dir" != "/" ]; do
    write_log "CheckProjectCandidate=$dir"
    if [ -d "$dir/.claude/hooks" ] || [ -d "$dir/.claude/hooks/viewer" ]; then
      write_log "ProjectDirResolved=$dir"
      printf '%s' "$dir"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  local fallback
  fallback="$(pwd -P)"
  write_log "ProjectDirFallback=$fallback" "WARN"
  printf '%s' "$fallback"
}

read_int_file() {
  local file_path="$1"
  if [ ! -f "$file_path" ]; then
    return 1
  fi
  local text
  text="$(head -n 1 "$file_path" 2>/dev/null | tr -d '[:space:]')"
  if [[ "$text" =~ ^[0-9]+$ ]]; then
    printf '%s' "$text"
    return 0
  fi
  return 1
}

get_command_path() {
  local name="$1"
  local path
  path="$(command -v "$name" 2>/dev/null || true)"
  if [ -n "$path" ]; then
    write_log "Command.$name=$path"
    printf '%s' "$path"
    return 0
  fi
  write_log "Command.$name not found" "WARN"
  return 1
}

get_port_process_ids() {
  local port="$1"
  lsof -nP -iTCP:"$port" -sTCP:LISTEN -t 2>/dev/null | sort -u || true
}

test_port_available() {
  local port="$1"
  if [ -z "$(get_port_process_ids "$port")" ]; then
    write_log "PortAvailable=$port"
    return 0
  fi
  write_log "PortUnavailable=$port" "WARN"
  return 1
}

stop_process_safe() {
  local pid="$1"
  local reason="$2"
  if [ -z "$pid" ]; then
    return 0
  fi
  if [ "$pid" = "$$" ]; then
    write_log "Skip current shell process. PID=$pid" "WARN"
    return 1
  fi
  if ! kill -0 "$pid" 2>/dev/null; then
    write_log "Process already gone. PID=$pid" "WARN"
    return 0
  fi
  local comm
  comm="$(ps -p "$pid" -o comm= 2>/dev/null | xargs basename 2>/dev/null || true)"
  local allow_kill_non_node="${VIEWER_KILL_NON_NODE:-0}"
  local is_node="0"
  if [ "$comm" = "node" ] || [ "$comm" = "nodejs" ]; then
    is_node="1"
  fi
  if [ "$is_node" != "1" ] && [ "$allow_kill_non_node" != "1" ]; then
    write_log "Skip non-node process on viewer port. PID=$pid, Name=${comm:-unknown}, Reason=$reason, Set VIEWER_KILL_NON_NODE=1 to force." "WARN"
    return 1
  fi
  write_log "StopProcess PID=$pid, Name=${comm:-unknown}, Reason=$reason" "WARN"
  kill "$pid" 2>/dev/null || true
  sleep 0.25
  if kill -0 "$pid" 2>/dev/null; then
    kill -9 "$pid" 2>/dev/null || true
  fi
  return 0
}

stop_port_processes() {
  local port="$1"
  local reason="$2"
  local ids
  ids="$(get_port_process_ids "$port")"
  if [ -z "$ids" ]; then
    write_log "No listening process found on port $port"
    return 0
  fi
  while IFS= read -r pid; do
    [ -n "$pid" ] && stop_process_safe "$pid" "$reason" || true
  done <<< "$ids"
}

extract_json_string() {
  local key="$1"
  JSON_KEY="$key" perl -0777 -ne 'my $k = $ENV{"JSON_KEY"}; if (/"\Q$k\E"\s*:\s*"((?:\\.|[^"])*)"/s) { my $v = $1; $v =~ s/\\\//\//g; $v =~ s/\\"/"/g; $v =~ s/\\\\/\\/g; print $v; }'
}

get_viewer_health() {
  local port="$1"
  local expected_artifact_dir="$2"
  local body
  local reachable="false"
  local is_viewer="false"
  local same_artifacts="false"
  local message=""
  body="$(curl -fsS --max-time 1 "http://127.0.0.1:$port/api/health" 2>/dev/null || true)"
  if [ -n "$body" ]; then
    reachable="true"
    local app
    local actual_artifact_dir
    app="$(printf '%s' "$body" | extract_json_string app)"
    actual_artifact_dir="$(printf '%s' "$body" | extract_json_string artifactDir)"
    if [ "$app" = "unity-dev-harness-viewer" ] || [ -n "$actual_artifact_dir" ]; then
      is_viewer="true"
    fi
    if [ -n "$actual_artifact_dir" ]; then
      local actual_norm
      local expected_norm
      actual_norm="$(normalize_path "$actual_artifact_dir")"
      expected_norm="$(normalize_path "$expected_artifact_dir")"
      message="artifactDir=$actual_norm"
      if [ "$actual_norm" = "$expected_norm" ]; then
        same_artifacts="true"
      fi
    elif [ "$app" = "unity-dev-harness-viewer" ]; then
      same_artifacts="true"
      message="viewer marker without artifactDir"
    else
      message="health endpoint returned non-viewer json"
    fi
  else
    message="not reachable"
  fi
  write_log "Health Port=$port, Reachable=$reachable, IsViewer=$is_viewer, SameArtifacts=$same_artifacts, Message=$message"
  printf '%s|%s|%s|%s' "$reachable" "$is_viewer" "$same_artifacts" "$message"
}

health_is_same_viewer() {
  local health="$1"
  local is_viewer
  local same_artifacts
  is_viewer="$(printf '%s' "$health" | cut -d '|' -f 2)"
  same_artifacts="$(printf '%s' "$health" | cut -d '|' -f 3)"
  [ "$is_viewer" = "true" ] && [ "$same_artifacts" = "true" ]
}

open_viewer_url() {
  local url="$1"
  write_log "OpenUrl=$url"
  if [ "${VIEWER_NO_OPEN:-0}" = "1" ]; then
    write_log "VIEWER_NO_OPEN=1, skip browser open."
    return 0
  fi
  if command -v open >/dev/null 2>&1; then
    open "$url" >/dev/null 2>&1 || true
  elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$url" >/dev/null 2>&1 || true
  else
    write_log "No browser opener found. URL=$url" "WARN"
  fi
}

get_log_tail() {
  local file_path="$1"
  local line_count="${2:-80}"
  if [ ! -f "$file_path" ]; then
    printf '(file not found)'
    return 0
  fi
  tail -n "$line_count" "$file_path" 2>/dev/null || printf '(read failed)'
}

get_candidate_ports() {
  local previous_port="${1:-}"
  local ports=""
  if [ -n "$previous_port" ]; then
    ports="$ports $previous_port"
  fi
  if [ -n "${VIEWER_PORT:-}" ] && [[ "$VIEWER_PORT" =~ ^[0-9]+$ ]]; then
    ports="$ports $VIEWER_PORT"
  fi
  ports="$ports 8765 8766 8767 8768 8769"
  printf '%s\n' $ports | awk '!seen[$0]++'
}

main() {
  init_bootstrap_log
  local script_dir
  script_dir="$SCRIPT_DIR"
  write_log "open-viewer.sh started"
  write_log "Shell=$SHELL"
  write_log "CurrentDirectory=$(pwd -P)"
  write_log "ScriptDir=$script_dir"
  write_log "CLAUDE_PROJECT_DIR=${CLAUDE_PROJECT_DIR:-'(empty)'}"
  write_log "CLAUDE_SESSION_ID=${CLAUDE_SESSION_ID:-'(empty)'}"

  local project_dir
  local hook_dir
  local viewer_dir
  local artifact_dir
  local state_dir
  project_dir="$(resolve_project_dir "$script_dir")"
  hook_dir="$project_dir/.claude/hooks"
  viewer_dir="$hook_dir/viewer"
  artifact_dir="${ARTIFACT_DIR:-$project_dir/artifacts}"
  state_dir="$hook_dir/.viewer-state"

  if [ ! -d "$hook_dir" ]; then
    write_log "HookDir not found. Use scriptDir state fallback. HookDir=$hook_dir" "WARN"
    state_dir="$script_dir/.viewer-state"
  fi

  init_main_log "$state_dir"

  # .cs 변경 감지: last-clear-ts 이후 변경된 파일이 없으면 뷰어 스킵
  local ts_file="$state_dir/last-clear-ts.txt"
  if [ -f "$ts_file" ]; then
    local last_clear
    last_clear="$(head -n 1 "$ts_file" 2>/dev/null | tr -d '[:space:]')"
    if [ -n "$last_clear" ]; then
      local changed
      changed="$(find "$project_dir/Assets" -name '*.cs' -newer "$ts_file" 2>/dev/null | head -n 1)"
      if [ -z "$changed" ]; then
        write_log "No .cs changes since last prompt. Skipping viewer."
        return 0
      fi
    fi
  fi

  local pid_file="$state_dir/server.pid"
  local port_file="$state_dir/server.port"
  local server_stdout="$state_dir/server.stdout.log"
  local server_stderr="$state_dir/server.stderr.log"
  local npm_install_log="$state_dir/npm-install.log"

  write_log "ProjectDir=$project_dir"
  write_log "HookDir=$hook_dir"
  write_log "ViewerDir=$viewer_dir"
  write_log "ArtifactDir=$artifact_dir"
  write_log "StateDir=$state_dir"
  write_log "PidFile=$pid_file"
  write_log "PortFile=$port_file"

  local validation_file="$artifact_dir/02-validation.md"
  write_log "ValidationFile=$validation_file"
  if [ ! -f "$validation_file" ]; then
    write_log "02-validation.md not found. Viewer still opens, but validation section may be empty." "WARN"
  fi

  local server_js="$viewer_dir/server.js"
  local package_json="$viewer_dir/package.json"
  local node_modules="$viewer_dir/node_modules"

  write_log "ServerJs=$server_js"
  write_log "PackageJson=$package_json"
  write_log "NodeModules=$node_modules"

  if [ ! -f "$server_js" ]; then
    write_log "server.js not found." "ERROR"
    return 0
  fi

  local previous_pid=""
  local previous_port=""
  previous_pid="$(read_int_file "$pid_file" || true)"
  previous_port="$(read_int_file "$port_file" || true)"
  write_log "PreviousPid=${previous_pid:-'(none)'}"
  write_log "PreviousPort=${previous_port:-'(none)'}"

  if [ -n "$previous_port" ]; then
    local previous_health
    previous_health="$(get_viewer_health "$previous_port" "$artifact_dir")"
    if health_is_same_viewer "$previous_health"; then
      write_log "Existing viewer server is healthy. Reuse it and open browser only."
      open_viewer_url "http://localhost:$previous_port/"
      return 0
    fi
    if ! test_port_available "$previous_port"; then
      write_log "Previous port is occupied but not usable for this project. Stop previous port processes." "WARN"
      stop_port_processes "$previous_port" "previous viewer port occupied but health check failed or points to another artifactDir"
    fi
  fi

  if [ -n "$previous_pid" ] && kill -0 "$previous_pid" 2>/dev/null; then
    local old_name
    old_name="$(ps -p "$previous_pid" -o comm= 2>/dev/null | xargs basename 2>/dev/null || true)"
    write_log "Previous PID still alive after port check. PID=$previous_pid, Name=${old_name:-unknown}" "WARN"
    stop_process_safe "$previous_pid" "stale recorded viewer process" || true
  fi

  local candidate_port
  while IFS= read -r candidate_port; do
    [ -z "$candidate_port" ] && continue
    local candidate_health
    candidate_health="$(get_viewer_health "$candidate_port" "$artifact_dir")"
    if health_is_same_viewer "$candidate_health"; then
      write_log "Viewer already running on candidate port. Port=$candidate_port"
      printf '%s\n' "$candidate_port" > "$port_file"
      open_viewer_url "http://localhost:$candidate_port/"
      return 0
    fi
  done < <(get_candidate_ports "$previous_port")

  local node_cmd
  local npm_cmd
  node_cmd="$(get_command_path node || true)"
  npm_cmd="$(get_command_path npm || true)"

  if [ -z "$node_cmd" ]; then
    write_log "Node.js not found. Opening install page." "ERROR"
    open_viewer_url "https://nodejs.org/"
    return 0
  fi

  write_log "NodeVersion=$($node_cmd -v 2>/dev/null || printf 'unknown')"
  if [ -n "$npm_cmd" ]; then
    write_log "NpmVersion=$($npm_cmd -v 2>/dev/null || printf 'unknown')"
  fi

  if [ ! -d "$node_modules" ] && [ -f "$package_json" ]; then
    if [ -n "$npm_cmd" ]; then
      write_log "Run npm install --silent"
      (cd "$viewer_dir" && "$npm_cmd" install --silent > "$npm_install_log" 2>&1)
      local npm_exit_code=$?
      write_log "NpmInstallExitCode=$npm_exit_code"
      if [ "$npm_exit_code" -ne 0 ]; then
        write_log "NpmInstallLogTail=$(printf '\n%s' "$(get_log_tail "$npm_install_log" 120)")" "ERROR"
      fi
    else
      write_log "npm not found. Cannot install dependencies." "ERROR"
    fi
  else
    write_log "Skip npm install."
  fi

  local port=""
  while IFS= read -r candidate_port; do
    [ -z "$candidate_port" ] && continue
    if test_port_available "$candidate_port"; then
      port="$candidate_port"
      break
    fi
    if [ -n "$previous_port" ] && [ "$candidate_port" = "$previous_port" ]; then
      write_log "Candidate is previous port but still occupied. Force stop and retry. Port=$candidate_port" "WARN"
      stop_port_processes "$candidate_port" "reuse previous viewer port"
      if test_port_available "$candidate_port"; then
        port="$candidate_port"
        break
      fi
    fi
  done < <(get_candidate_ports "$previous_port")

  if [ -z "$port" ]; then
    for candidate_port in $(seq 8770 8799); do
      if test_port_available "$candidate_port"; then
        port="$candidate_port"
        break
      fi
    done
  fi

  if [ -z "$port" ]; then
    write_log "No available viewer port found." "ERROR"
    return 0
  fi

  rm -f "$server_stdout" "$server_stderr"

  write_log "Start Express server"
  write_log "NodeCmd=$node_cmd"
  write_log "WorkingDirectory=$viewer_dir"
  write_log "PORT=$port"
  write_log "ARTIFACT_DIR=$artifact_dir"

  mkdir -p "$artifact_dir"
  (
    cd "$viewer_dir" || exit 1
    PORT="$port" ARTIFACT_DIR="$artifact_dir" CLAUDE_PROJECT_DIR="$project_dir" nohup "$node_cmd" server.js > "$server_stdout" 2> "$server_stderr" &
    printf '%s\n' "$!" > "$pid_file"
  )

  local server_pid
  server_pid="$(read_int_file "$pid_file" || true)"
  printf '%s\n' "$port" > "$port_file"
  write_log "ServerPid=${server_pid:-'(unknown)'}"

  sleep 0.15
  if [ -n "$server_pid" ] && ! kill -0 "$server_pid" 2>/dev/null; then
    write_log "Server exited immediately." "ERROR"
    write_log "ServerStderrTail=$(printf '\n%s' "$(get_log_tail "$server_stderr" 120)")" "ERROR"
    write_log "ServerStdoutTail=$(printf '\n%s' "$(get_log_tail "$server_stdout" 120)")" "ERROR"
    return 0
  fi

  local healthy="false"
  local attempt
  for attempt in $(seq 1 25); do
    write_log "HealthAttempt=$attempt"
    local health
    health="$(get_viewer_health "$port" "$artifact_dir")"
    if health_is_same_viewer "$health"; then
      healthy="true"
      break
    fi
    if [ -n "$server_pid" ] && ! kill -0 "$server_pid" 2>/dev/null; then
      write_log "Server exited during health check." "ERROR"
      break
    fi
    sleep 0.2
  done

  if [ "$healthy" != "true" ]; then
    write_log "Health check failed." "ERROR"
    write_log "ServerStderrTail=$(printf '\n%s' "$(get_log_tail "$server_stderr" 120)")" "ERROR"
    write_log "ServerStdoutTail=$(printf '\n%s' "$(get_log_tail "$server_stdout" 120)")" "ERROR"
  fi

  open_viewer_url "http://localhost:$port/"
  printf 'Viewer: http://localhost:%s/\n' "$port" >&2
  write_log "open-viewer.sh finished"
  return 0
}

main "$@"
exit 0
