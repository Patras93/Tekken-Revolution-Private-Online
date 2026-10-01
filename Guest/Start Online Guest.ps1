$ErrorActionPreference='Stop'
$configPath=Join-Path $PSScriptRoot 'guest_config.json'
if(-not (Test-Path $configPath)){throw 'Najpierw uruchom Guest\\Setup Online Guest.cmd.'}
$cfg=Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
$rpcs3=$cfg.rpcs3_directory
if(-not (Test-Path (Join-Path $rpcs3 'rpcs3.exe'))){throw 'Zapisana sciezka RPCS3 jest nieprawidlowa. Uruchom ponownie Setup Online Guest.cmd.'}
$game=Join-Path $rpcs3 'dev_hdd0\game\NPUB31250\USRDIR\EBOOT.BIN'
if(-not (Test-Path $game)){throw 'Nie znaleziono Tekken Revolution NPUB31250.'}
Start-Process -FilePath (Join-Path $rpcs3 'rpcs3.exe') -ArgumentList ('"'+$game+'"') -WorkingDirectory $rpcs3
