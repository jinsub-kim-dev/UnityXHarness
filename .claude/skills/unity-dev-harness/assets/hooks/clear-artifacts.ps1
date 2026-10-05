# artifacts 폴더 초기화 - 프롬프트 시작 시 실행 (chain-log, improvement-log 제외)
# UserPromptSubmit 훅에 등록

$ErrorActionPreference = 'Stop'

$HookDir     = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir  = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } `
               else { Split-Path -Parent (Split-Path -Parent $HookDir) }
$ArtifactDir = if ($env:ARTIFACT_DIR) { $env:ARTIFACT_DIR } `
               else { Join-Path $ProjectDir 'artifacts' }

$StateDir = Join-Path $HookDir '.viewer-state'
$exclude = @('chain-log.md', 'improvement-log.md')

# 이 시각 이후 수정된 .cs 파일을 unity-validate가 감지할 수 있도록 타임스탬프 기록
New-Item -ItemType Directory -Force -Path $StateDir | Out-Null
(Get-Date -Format 'o') | Out-File -FilePath (Join-Path $StateDir 'last-clear-ts.txt') -Encoding ascii -Force

if (Test-Path $ArtifactDir) {
    $removed = Get-ChildItem -Path $ArtifactDir -Filter '*.md' -ErrorAction SilentlyContinue |
        Where-Object { $exclude -notcontains $_.Name }
    $removed | Remove-Item -Force -ErrorAction SilentlyContinue
    $count = ($removed | Measure-Object).Count
    if ($count -gt 0) {
        [Console]::Error.WriteLine("artifacts cleared ($count files)")
    }
}

exit 0
