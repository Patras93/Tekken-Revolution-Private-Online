$ErrorActionPreference = 'Stop'

$configPath = Join-Path $PSScriptRoot 'guest_config.json'
if (-not (Test-Path -LiteralPath $configPath)) {
    throw 'Najpierw uruchom Guest\Setup Online Guest.cmd.'
}

$cfg = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
$rpcs3 = [string]$cfg.rpcs3_directory
$rpcnHost = '127.0.0.1'
if (($cfg.PSObject.Properties.Name -contains 'rpcn_host') -and [string]$cfg.rpcn_host) {
    $rpcnHost = [string]$cfg.rpcn_host
}
$expectedBuild = [string]$cfg.required_rpcs3_build

$rpcs3Exe = Join-Path $rpcs3 'rpcs3.exe'
$game = Join-Path $rpcs3 'dev_hdd0\game\NPUB31250\USRDIR\EBOOT.BIN'
$patch = Join-Path $rpcs3 'patches\NPUB31250_patch.yml'
$marker = Join-Path $rpcs3 'patras1993_rpc3_build.txt'
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
if (-not (Test-Path -LiteralPath $marker)) {
    throw 'Brak potwierdzenia wersji RPCS3. Uruchom Update RPCS3 for Patras1993.cmd.'
}

$markerValue = (Get-Content -LiteralPath $marker -Raw).Trim()
$supportedBuilds = @('0.0.43-20161-96ccd89c','0.0.43-20147-dfc0542a')
if ($supportedBuilds -notcontains $markerValue) {
    throw "Nieobslugiwany build RPCS3: $markerValue. Preferowany: 20161-96ccd89c; fallback: 20147-dfc0542a."
}
if ($expectedBuild -and $markerValue -ne $expectedBuild) {
    Write-Host "UWAGA: konfiguracja zapisala $expectedBuild, a wykryty marker to $markerValue."
}

if (-not (Test-Path -LiteralPath $rpcnConfig)) {
    throw 'Brak config\rpcn.yml. Uruchom ponownie Setup Online Guest.cmd.'
}

$rpcnText = Get-Content -LiteralPath $rpcnConfig -Raw
if ($rpcnText -notmatch ('(?m)^Host:\s*' + [regex]::Escape($rpcnHost) + '\s*

Write-Host 'Patras1993 RPCN przez lokalny tunel: OK'
Write-Host 'TCP 31313: OK'
Write-Host 'UDP 3657: OK'
Write-Host ('RPCS3: ' + $markerValue)
Write-Host 'Patch Revolution: OK'
Write-Host 'Uruchamianie Tekken Revolution...'

Start-Process -FilePath $rpcs3Exe -ArgumentList ('"' + $game + '"') -WorkingDirectory $rpcs3
)) {
    throw 'RPCN nie wskazuje na lokalny tunel 127.0.0.1. Uruchom ponownie Setup Online Guest.cmd.'
}

Write-Host ('Sprawdzanie lokalnego tunelu RPCN: ' + $rpcnHost + ':31313...')
$rpcnReachable = Test-NetConnection -ComputerName $rpcnHost -Port 31313 -InformationLevel Quiet -WarningAction SilentlyContinue
if (-not $rpcnReachable) {
    throw 'Lokalny tunel TCP 31313 nie dziala. Uruchom Patras Tekken Client.exe i nacisnij Polacz.'
}

$udpReady = [bool](Get-NetUDPEndpoint -LocalPort 3657 -ErrorAction SilentlyContinue)
if (-not $udpReady) {
    throw 'Lokalny tunel UDP 3657 nie dziala. Uruchom Patras Tekken Client.exe i nacisnij Polacz.'
}

Write-Host 'Patras1993 RPCN: OK'
Write-Host ('RPCS3: ' + $markerValue)
Write-Host 'Patch Revolution: OK'
Write-Host 'Uruchamianie Tekken Revolution...'

Start-Process -FilePath $rpcs3Exe -ArgumentList ('"' + $game + '"') -WorkingDirectory $rpcs3
