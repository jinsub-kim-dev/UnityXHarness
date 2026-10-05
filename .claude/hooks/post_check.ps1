# [PostToolUse] C# 파일 수정 후 FindObjectOfType 사용 감지

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$raw = [Console]::In.ReadToEnd()
$data = $raw | ConvertFrom-Json

$toolName = $data.tool_name
$filePath = $data.tool_input.file_path

if ($toolName -notin @("Write", "Edit")) { exit 0 }
if ($filePath -notmatch "\.cs$") { exit 0 }

$content = Get-Content $filePath -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
if ($null -eq $content) { exit 0 }

if ($content -match "FindObjectOfType") {
    @{decision='block';reason="[컨벤션 위반] FindObjectOfType 사용이 감지됐습니다: $filePath`nVContainer DI 주입으로 대체하세요."} | ConvertTo-Json -Compress
    exit 0
}

exit 0
