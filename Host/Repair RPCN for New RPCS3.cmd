@echo off
setlocal
net session >nul 2>&1
if not "%errorlevel%"=="0" (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Repair RPCN for New RPCS3.ps1"
set "ERR=%ERRORLEVEL%"
echo.
if "%ERR%"=="0" (echo RPCN: naprawa zakonczona.) else (echo RPCN: BLAD naprawy, kod %ERR%.)
pause
exit /b %ERR%
