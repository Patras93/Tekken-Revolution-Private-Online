@echo off
setlocal
start "" /min powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "%~dp0Start Patras1993 Host.ps1"
exit /b 0
