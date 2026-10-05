# [PreToolUse] Unity 프로젝트 파일 직접 삭제 차단

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$raw = [Console]::In.ReadToEnd()
$data = $raw | ConvertFrom-Json
$cmd = $data.tool_input.command

if ($cmd -match "rm[^\w].*\.(unity|prefab|asset)") {
    @{hookSpecificOutput=@{hookEventName='PreToolUse';permissionDecision='deny';permissionDecisionReason='Unity 프로젝트 파일 직접 삭제는 허용되지 않습니다. Unity 에디터를 통해 삭제하세요.'}} | ConvertTo-Json -Compress
    exit 0
}
exit 0
