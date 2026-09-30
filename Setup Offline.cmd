@echo off
setlocal
net session >nul 2>&1
if not "%errorlevel%"=="0" (
  powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)
set "HOSTS=%SystemRoot%\System32\drivers\etc\hosts"
findstr /I /C:"patch.tekkenbtb.online" "%HOSTS%" >nul || echo 127.0.0.1 patch.tekkenbtb.online>>"%HOSTS%"
findstr /I /C:"rpcn.tekkenbtb.online" "%HOSTS%" >nul || echo 127.0.0.1 rpcn.tekkenbtb.online>>"%HOSTS%"
ipconfig /flushdns >nul
echo.
echo GOTOWE. Lokalny backend i RPCN sa ustawione.
echo Skopiuj swoja gre do dev_hdd0\game\NPUB31250
echo Potem uruchom Start Tekken Revolution Offline.cmd
echo.
pause