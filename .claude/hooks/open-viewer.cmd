@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
set "STATE_DIR=%SCRIPT_DIR%.viewer-state"
set "CMD_LOG=%STATE_DIR%\open-viewer-cmd.log"
set "PS1_PATH=%SCRIPT_DIR%open-viewer.ps1"

if not exist "%STATE_DIR%" mkdir "%STATE_DIR%" >nul 2>nul

echo ============================================================ > "%CMD_LOG%"
echo Start open-viewer.cmd: %DATE% %TIME% >> "%CMD_LOG%"
echo SCRIPT_DIR=%SCRIPT_DIR% >> "%CMD_LOG%"
echo CURRENT_DIR=%CD% >> "%CMD_LOG%"
echo CLAUDE_PROJECT_DIR=%CLAUDE_PROJECT_DIR% >> "%CMD_LOG%"
echo CLAUDE_SESSION_ID=%CLAUDE_SESSION_ID% >> "%CMD_LOG%"
echo PS1_PATH=%PS1_PATH% >> "%CMD_LOG%"
echo ============================================================ >> "%CMD_LOG%"

if not exist "%PS1_PATH%" (
  echo PS1 not found: %PS1_PATH% >> "%CMD_LOG%"
  echo PS1 not found: %PS1_PATH%
  if "%OPEN_VIEWER_PAUSE%"=="1" pause
  exit /b 1
)

where powershell.exe >> "%CMD_LOG%" 2>&1
if errorlevel 1 (
  echo powershell.exe not found. >> "%CMD_LOG%"
  echo powershell.exe not found.
  if "%OPEN_VIEWER_PAUSE%"=="1" pause
  exit /b 1
)

echo Running PowerShell script... >> "%CMD_LOG%"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS1_PATH%" >> "%CMD_LOG%" 2>&1
set "EXIT_CODE=%ERRORLEVEL%"
echo PowerShell exit code: %EXIT_CODE% >> "%CMD_LOG%"

echo.
echo open-viewer.cmd finished.
echo.
echo Check logs:
echo   %CMD_LOG%
echo   %SCRIPT_DIR%open-viewer.bootstrap.log
echo   %STATE_DIR%\open-viewer.log
echo   %STATE_DIR%\server.stderr.log
echo   %STATE_DIR%\npm-install.log
echo.

if "%OPEN_VIEWER_PAUSE%"=="1" pause
exit /b %EXIT_CODE%
