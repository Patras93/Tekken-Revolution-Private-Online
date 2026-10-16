$ErrorActionPreference = 'Stop'

$configPath = Join-Path $PSScriptRoot 'guest_config.json'
if (-not (Test-Path -LiteralPath $configPath)) {
    throw 'Najpierw uruchom Guest\Setup Online Guest.cmd.'
}

$cfg = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
$rpcs3 = [string]$cfg.rpcs3_directory
$hostIp = [string]$cfg.host_tailscale_ip
$buildAtSetup = [string]$cfg.rpcs3_build_at_setup

$rpcs3Exe = Join-Path $rpcs3 'rpcs3.exe'
$game = Join-Path $rpcs3 'dev_hdd0\game\NPUB31250\USRDIR\EBOOT.BIN'
$patch = Join-Path $rpcs3 'patches\NPUB31250_patch.yml'
$rpcnConfig = Join-Path $rpcs3 'config\rpcn.yml'

if (-not (Test-Path -LiteralPath $rpcs3Exe)) {
    throw 'Zapisana sciezka RPCS3 jest nieprawidlowa. Uruchom ponownie Setup Online Guest.cmd.'
}
if (-not (Test-Path -LiteralPath $game)) {
    throw 'Nie znaleziono Tekken Revolution NPUB31250.'
}
if (-not (Test-Path -LiteralPath $patch)) {
    throw 'Brak patcha Patras1993 Revolution. Uruchom ponownie Setup Online Guest.cmd.'
}
# Wersja RPCS3 moze sie zmienic od Setup, nie blokuj nowego buildu.
if ($buildAtSetup) {
    Write-Host "RPCS3 w dniu konfiguracji: $buildAtSetup (informacyjnie)."
}

if (-not (Test-Path -LiteralPath $rpcnConfig)) {
    throw 'Brak config\rpcn.yml. Uruchom ponownie Setup Online Guest.cmd.'
}

$rpcnText = Get-Content -LiteralPath $rpcnConfig -Raw
if ($hostIp -and $rpcnText -notmatch ('(?m)^Host:\s*' + [regex]::Escape($hostIp) + '\s*$')) {
    throw 'RPCN nie wskazuje na host Patras1993. Uruchom ponownie Setup Online Guest.cmd.'
}

if ($hostIp) {
    Write-Host ('Sprawdzanie Patras1993 RPCN: ' + $hostIp + ':31313...')
    $rpcnReachable = Test-NetConnection -ComputerName $hostIp -Port 31313 -InformationLevel Quiet -WarningAction SilentlyContinue
    if (-not $rpcnReachable) {
        throw ('Nie mozna polaczyc sie z Patras1993 RPCN pod ' + $hostIp + ':31313. Sprawdz Tailscale i czy Host jest uruchomiony.')
    }
}

Write-Host 'Patras1993 RPCN: OK'
Write-Host 'RPCS3: OK (bez sztywnej blokady numeru buildu)'
Write-Host 'Patch Revolution: OK'
Write-Host 'Uruchamianie Tekken Revolution...'

Start-Process -FilePath $rpcs3Exe -ArgumentList ('"' + $game + '"') -WorkingDirectory $rpcs3
