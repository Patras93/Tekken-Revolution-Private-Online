@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Set P1 Health Shield.ps1" -Mode On
echo.
pause
