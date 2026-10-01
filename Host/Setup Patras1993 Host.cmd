@echo off
setlocal
net session >nul 2>&1
if not "%errorlevel%"=="0" (
  powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Setup Patras1993 Host.ps1"
if errorlevel 1 (
  echo.
  echo KONFIGURACJA NIEUDANA.
  pause
  exit /b 1
)
echo.
echo PATRA1993 HOST GOTOWY.
pause
