@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Set Practice Online Health.ps1" -Mode Off
echo.
pause
