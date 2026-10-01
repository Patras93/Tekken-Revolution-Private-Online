@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Set Private Match Rules.ps1" -Mode On
echo.
pause
