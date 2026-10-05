# Gate 3 독립 실행용 스크립트 (수동 테스트 / 디버그용)
# Stop hook에서는 unity-validate.ps1이 play mode 안에서 직접 호출함.
# 이 스크립트는 play mode 없이 gate3_run_test만 호출 (inject:true 테스트 시 play mode 수동 진입 필요).

$ErrorActionPreference = "Stop"

$MCP_URL  = if ($env:MCP_URL) { $env:MCP_URL } else { "http://127.0.0.1:8080/mcp" }
$HookDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$StateDir = Join-Path $HookDir ".viewer-state"
$TestFile = Join-Path $StateDir "gate3-test.json"
$LogFile  = Join-Path $StateDir "gate3-test-runner.log"
$script:SessionId = $null
$script:RequestId = 0

function Log {
    param([string]$Msg, [string]$Level = "INFO")
    $line = "[$(Get-Date -Format 'HH:mm:ss')][$Level] $Msg"
    [Console]::Error.WriteLine("[gate3] $line")
    Add-Content -Path $LogFile -Value $line -Encoding UTF8 -ErrorAction SilentlyContinue
}

Add-Content -Path $LogFile -Value "" -Encoding UTF8 -ErrorAction SilentlyContinue
Add-Content -Path $LogFile -Value ("=" * 60) -Encoding UTF8 -ErrorAction SilentlyContinue
Log "gate3-test-runner started (standalone mode)"

if (-not (Test-Path $TestFile)) {
    Log "gate3-test.json not found. Skipping." "WARN"
    exit 0
}

$testConfig = Get-Content $TestFile -Raw -Encoding UTF8
Log "Config: $($testConfig.Trim())"

function Send-McpRequest {
    param([hashtable]$Payload, [int]$TimeoutSec = 15)
    $h = @{ "Content-Type" = "application/json"; "Accept" = "application/json, text/event-stream" }
    if ($script:SessionId) { $h["Mcp-Session-Id"] = $script:SessionId }
    $body = $Payload | ConvertTo-Json -Depth 20 -Compress
    $r = Invoke-WebRequest -Uri $MCP_URL -Method Post -Headers $h -Body $body -UseBasicParsing -TimeoutSec $TimeoutSec
    $sh = $r.Headers["Mcp-Session-Id"]
    if ($sh) { $script:SessionId = if ($sh -is [array]) { $sh[0] } else { $sh } }
    $c = $r.Content.Trim()
    if ($c -match "(?m)^data:\s*(.+)$") { $c = $Matches[1].Trim() }
    if ([string]::IsNullOrWhiteSpace($c)) { return $null }
    return $c | ConvertFrom-Json
}

function Invoke-Tool {
    param([string]$Name, [hashtable]$ToolArgs)
    return Send-McpRequest @{
        jsonrpc = "2.0"; id = (++$script:RequestId); method = "tools/call"
        params  = @{ name = $Name; arguments = $ToolArgs }
    }
}

Log "Connecting to MCP..."
try {
    Send-McpRequest @{
        jsonrpc = "2.0"; id = (++$script:RequestId); method = "initialize"
        params  = @{ protocolVersion = "2024-11-05"; capabilities = @{}
                     clientInfo = @{ name = "gate3-test-runner"; version = "2.0" } }
    } | Out-Null
    Send-McpRequest @{ jsonrpc = "2.0"; method = "notifications/initialized"; params = @{} } | Out-Null
    Log "MCP session established (id=$script:SessionId)"
} catch {
    Log "MCP not available: $_" "WARN"
    exit 0
}

Log "Calling gate3_run_test..."
$t0 = Get-Date
try {
    $cfg = $testConfig | ConvertFrom-Json
    $toolArgs = @{ type_name = $cfg.type_name }
    if ($null -ne $cfg.call_start)            { $toolArgs["call_start"] = [bool]$cfg.call_start }
    if ($null -ne $cfg.inject)                { $toolArgs["inject"] = [bool]$cfg.inject }
    if ($null -ne $cfg.check_non_null_fields) { $toolArgs["check_non_null_fields"] = $cfg.check_non_null_fields }

    $result = Invoke-Tool "gate3_run_test" $toolArgs
    Log "responded in $([int]((Get-Date)-$t0).TotalSeconds)s"
} catch {
    Log "gate3_run_test failed: $_" "ERROR"
    exit 0
}

if (-not $result) { Log "No result returned" "ERROR"; exit 0 }

$text = ""
if ($result.result.structuredContent) {
    $p = $result.result.structuredContent
    $text = if ($p.message) { "$($p.message)" } else { "$($p.data)" }
} else {
    $raw = ($result.result.content | Where-Object { $_.type -eq "text" } | Select-Object -First 1).text
    try { $p = $raw | ConvertFrom-Json; $text = if ($p.message) { "$($p.message)" } else { "$($p.data)" } }
    catch { $text = $raw }
}

if ($result.error)                    { Log "ERROR: $($result.error.message)" "ERROR"; exit 0 }
if ($result.result.isError -eq $true) { Log "FAIL (isError): $text" "ERROR"; exit 0 }

if ($text -match "^PASS")     { Log "PASS: $text" }
elseif ($text -match "^FAIL") { Log "FAIL: $text" "ERROR" }
else                          { Log "RESULT: $text" "WARN" }

Log "gate3-test-runner finished"
exit 0
