$ErrorActionPreference='Stop'
$rpcs3=Read-Host 'Podaj pelna sciezke do katalogu RPCS3'
$rpcs3=$rpcs3.Trim('"')
if(-not (Test-Path (Join-Path $rpcs3 'rpcs3.exe'))){throw 'Nie znaleziono rpcs3.exe.'}
$game=Join-Path $rpcs3 'dev_hdd0\game\NPUB31250\USRDIR\EBOOT.BIN'
if(-not (Test-Path $game)){throw 'Nie znaleziono Tekken Revolution NPUB31250.'}
Start-Process -FilePath (Join-Path $rpcs3 'rpcs3.exe') -ArgumentList ('"'+$game+'"') -WorkingDirectory $rpcs3
