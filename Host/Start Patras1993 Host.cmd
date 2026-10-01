@echo off
setlocal
title Patras1993 Host
echo === PATRA1993 HOST START ===
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Start Patras1993 Host.ps1"
set "ERR=%ERRORLEVEL%"
echo.
echo PowerShell zakonczyl prace. Kod: %ERR%
echo.
pause
exit /b %ERR%
