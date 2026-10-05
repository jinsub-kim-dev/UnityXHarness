# Unity Dev Harness - Express viewer launcher
# Location:
#   <project>/.claude/hooks/open-viewer.ps1
# Viewer:
#   <project>/.claude/hooks/viewer/server.js
# Artifacts:
#   <project>/artifacts/*.md

$ErrorActionPreference = 'Stop'

$script:BootstrapLog = $null
$script:MainLog = $null
$script:StateDir = $null

function Get-SafeScriptPath {
  if ($PSCommandPath) {
    return $PSCommandPath
  }

  if ($MyInvocation.MyCommand.Path) {
    return $MyInvocation.MyCommand.Path
  }

  return $null
}

function Write-ViewerLog {
  param([string]$Message, [string]$Level = 'INFO')

  $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
  $line = "[$timestamp][$Level] $Message"

  try {
    Write-Host $line
  }
  catch {
  }

  foreach ($target in @($script:BootstrapLog, $script:MainLog)) {
    if (-not [string]::IsNullOrWhiteSpace($target)) {
      try {
        Add-Content -Path $target -Value $line -Encoding UTF8
      }
      catch {
      }
    }
  }
}

function Initialize-BootstrapLog {
  $scriptPath = Get-SafeScriptPath

  if ($scriptPath) {
    $scriptDir = Split-Path -Parent $scriptPath
  }
  else {
    $scriptDir = (Get-Location).Path
  }

  if ([string]::IsNullOrWhiteSpace($scriptDir)) {
    $scriptDir = (Get-Location).Path
  }

  $script:BootstrapLog = Join-Path $scriptDir 'open-viewer.bootstrap.log'

  try {
    Add-Content -Path $script:BootstrapLog -Value '' -Encoding UTF8
    Add-Content -Path $script:BootstrapLog -Value '============================================================' -Encoding UTF8
    Add-Content -Path $script:BootstrapLog -Value ('Start open-viewer.ps1: ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')) -Encoding UTF8
    Add-Content -Path $script:BootstrapLog -Value '============================================================' -Encoding UTF8
  }
  catch {
  }

  Write-ViewerLog ('BootstrapLog=' + $script:BootstrapLog)
  return $scriptDir
}

function Initialize-MainLog {
  param([string]$StateDir)

  $script:StateDir = $StateDir
  New-Item -ItemType Directory -Force -Path $script:StateDir | Out-Null
  $script:MainLog = Join-Path $script:StateDir 'open-viewer.log'

  Add-Content -Path $script:MainLog -Value '' -Encoding UTF8
  Add-Content -Path $script:MainLog -Value '============================================================' -Encoding UTF8
  Add-Content -Path $script:MainLog -Value ('Start open-viewer.ps1: ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')) -Encoding UTF8
  Add-Content -Path $script:MainLog -Value '============================================================' -Encoding UTF8

  Write-ViewerLog ('MainLog=' + $script:MainLog)
}

function Write-ErrorDetail {
  param($ErrorRecord)

  Write-ViewerLog ('Exception=' + $ErrorRecord.Exception.Message) 'ERROR'
  Write-ViewerLog ('ExceptionType=' + $ErrorRecord.Exception.GetType().FullName) 'ERROR'

  if ($ErrorRecord.InvocationInfo) {
    Write-ViewerLog ('Line=' + $ErrorRecord.InvocationInfo.Line) 'ERROR'
    Write-ViewerLog ('Position=' + $ErrorRecord.InvocationInfo.PositionMessage) 'ERROR'
  }
}

function Normalize-PathText {
  param([string]$PathText)

  if ([string]::IsNullOrWhiteSpace($PathText)) {
    return ''
  }

  try {
    return [System.IO.Path]::GetFullPath($PathText).TrimEnd([char[]]@('\', '/'))
  }
  catch {
    return $PathText.TrimEnd([char[]]@('\', '/'))
  }
}

function Resolve-ProjectDir {
  param([string]$ScriptDir)

  Write-ViewerLog ('Resolve-ProjectDir.ScriptDir=' + $ScriptDir)

  if (-not [string]::IsNullOrWhiteSpace($env:CLAUDE_PROJECT_DIR)) {
    Write-ViewerLog ('Use CLAUDE_PROJECT_DIR=' + $env:CLAUDE_PROJECT_DIR)
    return $env:CLAUDE_PROJECT_DIR
  }

  $dir = (Resolve-Path $ScriptDir).Path

  while (-not [string]::IsNullOrWhiteSpace($dir)) {
    $candidateHooks = Join-Path $dir '.claude\hooks'
    $candidateViewer = Join-Path $candidateHooks 'viewer'
    Write-ViewerLog ('CheckProjectCandidate=' + $dir)

    if ((Test-Path $candidateHooks) -or (Test-Path $candidateViewer)) {
      Write-ViewerLog ('ProjectDirResolved=' + $dir)
      return $dir
    }

    $parent = Split-Path -Parent $dir

    if ([string]::IsNullOrWhiteSpace($parent) -or $parent -eq $dir) {
      break
    }

    $dir = $parent
  }

  $fallback = (Get-Location).Path
  Write-ViewerLog ('ProjectDirFallback=' + $fallback) 'WARN'
  return $fallback
}

function Get-CommandPath {
  param([string]$Name)

  try {
    $cmd = Get-Command $Name -ErrorAction Stop

    if ($cmd.Source) {
      Write-ViewerLog ("Command.$Name=" + $cmd.Source)
      return $cmd.Source
    }

    if ($cmd.Path) {
      Write-ViewerLog ("Command.$Name=" + $cmd.Path)
      return $cmd.Path
    }

    Write-ViewerLog ("Command.$Name found but path empty") 'WARN'
    return $Name
  }
  catch {
    Write-ViewerLog ("Command.$Name not found") 'WARN'
    return $null
  }
}

function Read-IntFile {
  param([string]$Path)

  if (-not (Test-Path $Path)) {
    return $null
  }

  try {
    $text = (Get-Content -Path $Path -ErrorAction Stop | Select-Object -First 1)
    $value = 0

    if ([int]::TryParse(($text -as [string]).Trim(), [ref]$value)) {
      return $value
    }
  }
  catch {
    Write-ViewerLog ('ReadIntFileFailed=' + $Path + ' / ' + $_.Exception.Message) 'WARN'
  }

  return $null
}

function Test-PortAvailable {
  param([int]$Port)

  try {
    $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $Port)
    $listener.Start()
    $listener.Stop()
    Write-ViewerLog ('PortAvailable=' + $Port)
    return $true
  }
  catch {
    Write-ViewerLog ('PortUnavailable=' + $Port + ' / ' + $_.Exception.Message) 'WARN'
    return $false
  }
}

function Get-PortProcessIds {
  param([int]$Port)

  $ids = @()

  try {
    $connections = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction Stop

    foreach ($connection in $connections) {
      if ($connection.OwningProcess) {
        $ids += [int]$connection.OwningProcess
      }
    }
  }
  catch {
    Write-ViewerLog ('Get-NetTCPConnection failed. Fallback to netstat. Port=' + $Port + ' / ' + $_.Exception.Message) 'WARN'

    try {
      $lines = & netstat -ano -p tcp | Select-String 'LISTENING'

      foreach ($line in $lines) {
        $parts = ($line.ToString() -split '\s+') | Where-Object { $_ }

        if ($parts.Count -lt 5) {
          continue
        }

        $localAddress = $parts[1]
        $pidText = $parts[$parts.Count - 1]

        if ($localAddress -match (':' + [regex]::Escape([string]$Port) + '$')) {
          $pidValue = 0

          if ([int]::TryParse($pidText, [ref]$pidValue)) {
            $ids += $pidValue
          }
        }
      }
    }
    catch {
      Write-ViewerLog ('netstat fallback failed. Port=' + $Port + ' / ' + $_.Exception.Message) 'WARN'
    }
  }

  return @($ids | Select-Object -Unique)
}

function Stop-ProcessSafe {
  param([int]$ProcessId, [string]$Reason)

  if ($ProcessId -eq $PID) {
    Write-ViewerLog ('Skip current PowerShell process. PID=' + $ProcessId) 'WARN'
    return $false
  }

  $process = Get-Process -Id $ProcessId -ErrorAction SilentlyContinue

  if (-not $process) {
    Write-ViewerLog ('Process already gone. PID=' + $ProcessId) 'WARN'
    return $true
  }

  $allowKillNonNode = ($env:VIEWER_KILL_NON_NODE -eq '1')
  $isNode = ($process.ProcessName -ieq 'node') -or ($process.ProcessName -ieq 'node.exe')

  if ((-not $isNode) -and (-not $allowKillNonNode)) {
    Write-ViewerLog ('Skip non-node process on viewer port. PID=' + $ProcessId + ', Name=' + $process.ProcessName + ', Reason=' + $Reason + ', Set VIEWER_KILL_NON_NODE=1 to force.') 'WARN'
    return $false
  }

  Write-ViewerLog ('StopProcess PID=' + $ProcessId + ', Name=' + $process.ProcessName + ', Reason=' + $Reason) 'WARN'
  Stop-Process -Id $ProcessId -Force -ErrorAction SilentlyContinue
  Start-Sleep -Milliseconds 250
  return $true
}

function Stop-PortProcesses {
  param([int]$Port, [string]$Reason)

  $ids = Get-PortProcessIds $Port

  if ($ids.Count -eq 0) {
    Write-ViewerLog ('No listening process found on port ' + $Port)
    return
  }

  foreach ($id in $ids) {
    Stop-ProcessSafe $id $Reason | Out-Null
  }
}

function Get-ViewerHealth {
  param([int]$Port, [string]$ExpectedArtifactDir)

  $result = [ordered]@{
    Reachable = $false
    IsViewer = $false
    IsSameArtifactDir = $false
    StatusCode = $null
    Message = ''
  }

  try {
    $url = 'http://127.0.0.1:' + $Port + '/api/health'
    $response = Invoke-WebRequest -UseBasicParsing -Uri $url -TimeoutSec 1
    $result.Reachable = $true
    $result.StatusCode = $response.StatusCode

    $payload = $null

    try {
      $payload = $response.Content | ConvertFrom-Json
    }
    catch {
      $payload = $null
    }

    if ($payload) {
      $hasViewerMarker = ($payload.app -eq 'unity-dev-harness-viewer')
      $hasArtifactDir = -not [string]::IsNullOrWhiteSpace($payload.artifactDir)
      $result.IsViewer = $hasViewerMarker -or $hasArtifactDir

      if ($hasArtifactDir) {
        $actual = Normalize-PathText ([string]$payload.artifactDir)
        $expected = Normalize-PathText $ExpectedArtifactDir
        $result.IsSameArtifactDir = ($actual -ieq $expected)
        $result.Message = 'artifactDir=' + $actual
      }
      else {
        $result.IsSameArtifactDir = $hasViewerMarker
        $result.Message = 'viewer marker without artifactDir'
      }
    }
    else {
      $result.Message = 'health endpoint returned non-json'
    }
  }
  catch {
    $result.Message = $_.Exception.Message
  }

  Write-ViewerLog ('Health Port=' + $Port + ', Reachable=' + $result.Reachable + ', IsViewer=' + $result.IsViewer + ', SameArtifacts=' + $result.IsSameArtifactDir + ', Message=' + $result.Message)
  return [pscustomobject]$result
}

function Open-ViewerUrl {
  param([string]$Url)

  Write-ViewerLog ('OpenUrl=' + $Url)
  Start-Process $Url | Out-Null
}

function Get-LogTail {
  param([string]$Path, [int]$LineCount = 80)

  if (-not (Test-Path $Path)) {
    return '(file not found)'
  }

  try {
    return (Get-Content -Path $Path -Tail $LineCount -ErrorAction Stop) -join [Environment]::NewLine
  }
  catch {
    return ('(read failed) ' + $_.Exception.Message)
  }
}

function Get-CandidatePorts {
  param($PreviousPort)

  $ports = @()

  if ($PreviousPort) {
    $ports += [int]$PreviousPort
  }

  if ($env:VIEWER_PORT) {
    $envPort = 0

    if ([int]::TryParse($env:VIEWER_PORT, [ref]$envPort)) {
      $ports += $envPort
    }
  }

  $ports += @(8765, 8766, 8767, 8768, 8769)
  return @($ports | Select-Object -Unique)
}

try {
  $scriptDir = Initialize-BootstrapLog
  Write-ViewerLog 'open-viewer.ps1 started'
  Write-ViewerLog ('PowerShellVersion=' + $PSVersionTable.PSVersion.ToString())
  Write-ViewerLog ('CurrentDirectory=' + (Get-Location).Path)
  Write-ViewerLog ('ScriptDir=' + $scriptDir)
  Write-ViewerLog ('CLAUDE_PROJECT_DIR=' + $(if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { '(empty)' }))
  Write-ViewerLog ('CLAUDE_SESSION_ID=' + $(if ($env:CLAUDE_SESSION_ID) { $env:CLAUDE_SESSION_ID } else { '(empty)' }))

  $projectDir = Resolve-ProjectDir $scriptDir
  $hookDir = Join-Path $projectDir '.claude\hooks'
  $viewerDir = Join-Path $hookDir 'viewer'
  $artifactDir = Join-Path $projectDir 'artifacts'
  $stateDir = Join-Path $hookDir '.viewer-state'

  if (-not (Test-Path $hookDir)) {
    Write-ViewerLog ('HookDir not found. Use scriptDir state fallback. HookDir=' + $hookDir) 'WARN'
    $stateDir = Join-Path $scriptDir '.viewer-state'
  }

  Initialize-MainLog $stateDir

  # 대화(세션)당 1회만 실행: 매 턴마다 브라우저 탭을 새로 여는 것을 막는다.
  # 같은 CLAUDE_SESSION_ID면 스킵. 강제로 다시 열려면 FORCE_REOPEN_VIEWER=1
  $sessionFlagFile = Join-Path $stateDir "viewer-session.txt"
  if ($env:CLAUDE_SESSION_ID -and ($env:FORCE_REOPEN_VIEWER -ne "1")) {
    $prevSession = $null
    if (Test-Path $sessionFlagFile) {
      try { $prevSession = (Get-Content $sessionFlagFile -ErrorAction Stop | Select-Object -First 1).Trim() } catch { }
    }
    if ($prevSession -eq $env:CLAUDE_SESSION_ID) {
      Write-ViewerLog ("Already opened once for this conversation (session=" + $env:CLAUDE_SESSION_ID + "). Skipping. Set FORCE_REOPEN_VIEWER=1 to force.")
      exit 0
    }
    try {
      $env:CLAUDE_SESSION_ID | Out-File -FilePath $sessionFlagFile -Encoding ascii -Force
    } catch { }
  }

  # .cs 변경 감지: last-clear-ts 이후 변경된 파일이 없으면 뷰어 스킵
  $tsFile = Join-Path $stateDir 'last-clear-ts.txt'
  if (Test-Path $tsFile) {
    try {
      $lastClear = [datetime]::Parse((Get-Content $tsFile -ErrorAction Stop | Select-Object -First 1).Trim())
      $changed = Get-ChildItem -Path (Join-Path $projectDir 'Assets') -Recurse -Filter '*.cs' -ErrorAction SilentlyContinue |
        Where-Object { $_.LastWriteTime -gt $lastClear }
      if (-not $changed) {
        Write-ViewerLog 'No .cs changes since last prompt. Skipping viewer.'
        exit 0
      }
    }
    catch {
      Write-ViewerLog ('TsFile check failed: ' + $_.Exception.Message) 'WARN'
    }
  }

  $pidFile = Join-Path $stateDir 'server.pid'
  $portFile = Join-Path $stateDir 'server.port'
  $serverStdout = Join-Path $stateDir 'server.stdout.log'
  $serverStderr = Join-Path $stateDir 'server.stderr.log'
  $npmInstallLog = Join-Path $stateDir 'npm-install.log'

  Write-ViewerLog ('ProjectDir=' + $projectDir)
  Write-ViewerLog ('HookDir=' + $hookDir)
  Write-ViewerLog ('ViewerDir=' + $viewerDir)
  Write-ViewerLog ('ArtifactDir=' + $artifactDir)
  Write-ViewerLog ('StateDir=' + $stateDir)
  Write-ViewerLog ('PidFile=' + $pidFile)
  Write-ViewerLog ('PortFile=' + $portFile)

  $validationFile = Join-Path $artifactDir '02-validation.md'
  Write-ViewerLog ('ValidationFile=' + $validationFile)

  if (-not (Test-Path $validationFile)) {
    Write-ViewerLog '02-validation.md not found. Viewer still opens, but validation section may be empty.' 'WARN'
  }

  $serverJs = Join-Path $viewerDir 'server.js'
  $packageJson = Join-Path $viewerDir 'package.json'
  $nodeModules = Join-Path $viewerDir 'node_modules'

  Write-ViewerLog ('ServerJs=' + $serverJs)
  Write-ViewerLog ('PackageJson=' + $packageJson)
  Write-ViewerLog ('NodeModules=' + $nodeModules)

  if (-not (Test-Path $serverJs)) {
    Write-ViewerLog 'server.js not found.' 'ERROR'
    exit 0
  }

  $previousPid = Read-IntFile $pidFile
  $previousPort = Read-IntFile $portFile

  Write-ViewerLog ('PreviousPid=' + $(if ($previousPid) { $previousPid } else { '(none)' }))
  Write-ViewerLog ('PreviousPort=' + $(if ($previousPort) { $previousPort } else { '(none)' }))

  if ($previousPort) {
    $previousHealth = Get-ViewerHealth $previousPort $artifactDir

    if ($previousHealth.IsViewer -and $previousHealth.IsSameArtifactDir) {
      Write-ViewerLog 'Existing viewer server is healthy. Reuse it and open browser only.'
      Open-ViewerUrl ('http://localhost:' + $previousPort + '/')
      exit 0
    }

    if (-not (Test-PortAvailable $previousPort)) {
      Write-ViewerLog 'Previous port is occupied but not usable for this project. Stop previous port processes.' 'WARN'
      Stop-PortProcesses $previousPort 'previous viewer port occupied but health check failed or points to another artifactDir'
    }
  }

  if ($previousPid) {
    $oldProcess = Get-Process -Id $previousPid -ErrorAction SilentlyContinue

    if ($oldProcess) {
      Write-ViewerLog ('Previous PID still alive after port check. PID=' + $previousPid + ', Name=' + $oldProcess.ProcessName) 'WARN'
      Stop-ProcessSafe $previousPid 'stale recorded viewer process' | Out-Null
    }
  }

  foreach ($candidatePort in (Get-CandidatePorts $previousPort)) {
    $candidateHealth = Get-ViewerHealth $candidatePort $artifactDir

    if ($candidateHealth.IsViewer -and $candidateHealth.IsSameArtifactDir) {
      Write-ViewerLog ('Viewer already running on candidate port. Port=' + $candidatePort)
      $candidatePort | Out-File -FilePath $portFile -Encoding ascii -Force
      Open-ViewerUrl ('http://localhost:' + $candidatePort + '/')
      exit 0
    }
  }

  $nodeCmd = Get-CommandPath 'node'
  $npmCmd = Get-CommandPath 'npm'

  if (-not $nodeCmd) {
    Write-ViewerLog 'Node.js not found. Opening install page.' 'ERROR'
    Open-ViewerUrl 'https://nodejs.org/'
    exit 0
  }

  try {
    $nodeVersion = & $nodeCmd -v
    Write-ViewerLog ('NodeVersion=' + $nodeVersion)
  }
  catch {
    Write-ViewerLog ('NodeVersionFailed=' + $_.Exception.Message) 'WARN'
  }

  if ($npmCmd) {
    try {
      $npmVersion = & $npmCmd -v
      Write-ViewerLog ('NpmVersion=' + $npmVersion)
    }
    catch {
      Write-ViewerLog ('NpmVersionFailed=' + $_.Exception.Message) 'WARN'
    }
  }

  if ((-not (Test-Path $nodeModules)) -and (Test-Path $packageJson)) {
    if ($npmCmd) {
      Write-ViewerLog 'Run npm install --silent'
      Push-Location $viewerDir
      try {
        & $npmCmd install --silent *> $npmInstallLog
        Write-ViewerLog ('NpmInstallExitCode=' + $LASTEXITCODE)

        if ($LASTEXITCODE -ne 0) {
          Write-ViewerLog ('NpmInstallLogTail=' + [Environment]::NewLine + (Get-LogTail $npmInstallLog 120)) 'ERROR'
        }
      }
      finally {
        Pop-Location
      }
    }
    else {
      Write-ViewerLog 'npm not found. Cannot install dependencies.' 'ERROR'
    }
  }
  else {
    Write-ViewerLog 'Skip npm install.'
  }

  $port = $null

  foreach ($candidatePort in (Get-CandidatePorts $previousPort)) {
    if (Test-PortAvailable $candidatePort) {
      $port = $candidatePort
      break
    }

    if ($previousPort -and ($candidatePort -eq $previousPort)) {
      Write-ViewerLog ('Candidate is previous port but still occupied. Force stop and retry. Port=' + $candidatePort) 'WARN'
      Stop-PortProcesses $candidatePort 'reuse previous viewer port'

      if (Test-PortAvailable $candidatePort) {
        $port = $candidatePort
        break
      }
    }
  }

  if (-not $port) {
    $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, 0)
    $listener.Start()
    $port = $listener.LocalEndpoint.Port
    $listener.Stop()
    Write-ViewerLog ('DynamicPort=' + $port)
  }

  if (Test-Path $serverStdout) {
    Remove-Item $serverStdout -Force
  }

  if (Test-Path $serverStderr) {
    Remove-Item $serverStderr -Force
  }

  Write-ViewerLog 'Start Express server'
  Write-ViewerLog ('NodeCmd=' + $nodeCmd)
  Write-ViewerLog ('WorkingDirectory=' + $viewerDir)
  Write-ViewerLog ('PORT=' + $port)
  Write-ViewerLog ('ARTIFACT_DIR=' + $artifactDir)

  # env vars를 현재 세션에 설정하면 자식 프로세스가 상속한다.
  # Start-Process 의 파일 리다이렉트는 파이프가 아닌 파일 핸들을 node 가 직접 소유하므로
  # 이 PS 스크립트가 종료돼도 node 서버가 EPIPE 로 죽지 않는다.
  $env:PORT = [string]$port
  $env:ARTIFACT_DIR = $artifactDir
  $env:CLAUDE_PROJECT_DIR = $projectDir

  $proc = Start-Process `
    -FilePath $nodeCmd `
    -ArgumentList 'server.js' `
    -WorkingDirectory $viewerDir `
    -WindowStyle Hidden `
    -RedirectStandardOutput $serverStdout `
    -RedirectStandardError $serverStderr `
    -PassThru

  Write-ViewerLog ('ServerPid=' + $proc.Id)
  $proc.Id | Out-File -FilePath $pidFile -Encoding ascii -Force
  $port | Out-File -FilePath $portFile -Encoding ascii -Force

  Start-Sleep -Milliseconds 150

  $proc.Refresh()

  if ($proc.HasExited) {
    Write-ViewerLog ('Server exited immediately. ExitCode=' + $proc.ExitCode) 'ERROR'
    Write-ViewerLog ('ServerStderrTail=' + [Environment]::NewLine + (Get-LogTail $serverStderr 120)) 'ERROR'
    Write-ViewerLog ('ServerStdoutTail=' + [Environment]::NewLine + (Get-LogTail $serverStdout 120)) 'ERROR'
    exit 0
  }

  $healthy = $false

  for ($i = 1; $i -le 25; $i++) {
    Write-ViewerLog ('HealthAttempt=' + $i)
    $health = Get-ViewerHealth $port $artifactDir

    if ($health.IsViewer -and $health.IsSameArtifactDir) {
      $healthy = $true
      break
    }

    $proc.Refresh()

    if ($proc.HasExited) {
      Write-ViewerLog ('Server exited during health check. ExitCode=' + $proc.ExitCode) 'ERROR'
      break
    }

    Start-Sleep -Milliseconds 200
  }

  if (-not $healthy) {
    Write-ViewerLog 'Health check failed.' 'ERROR'
    Write-ViewerLog ('ServerStderrTail=' + [Environment]::NewLine + (Get-LogTail $serverStderr 120)) 'ERROR'
    Write-ViewerLog ('ServerStdoutTail=' + [Environment]::NewLine + (Get-LogTail $serverStdout 120)) 'ERROR'
  }

  Open-ViewerUrl ('http://localhost:' + $port + '/')
  Write-ViewerLog 'open-viewer.ps1 finished'
  [Console]::Error.WriteLine('Viewer: http://localhost:' + $port + '/')
  exit 0
}
catch {
  Write-ErrorDetail $_
  [Console]::Error.WriteLine('open-viewer.ps1 error: ' + $_.Exception.Message)
  exit 0
}
