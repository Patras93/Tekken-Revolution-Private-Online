$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$cfgPath = Join-Path $root 'host_config.json'
$expectedHash = 'PPU-1504b75ba97abccdf2d0a93dd93aaff10591a01e'
$expectedDescription = 'Patras1993 Revolution Runtime Patches'

Write-Host '=== PATRAS1993 REVOLUTION DIAGNOSE ==='
Write-Host ''

if (-not (Test-Path -LiteralPath $cfgPath)) {
    throw 'Brak Host\host_config.json. Najpierw uruchom Setup Patras1993 Host.cmd.'
}

$cfg = Get-Content -LiteralPath $cfgPath -Raw | ConvertFrom-Json
$rpcs3Dir = [string]$cfg.rpcs3_directory
if (-not $rpcs3Dir -or -not (Test-Path -LiteralPath $rpcs3Dir)) {
    throw "Nieprawidlowa sciezka RPCS3 w host_config.json: $rpcs3Dir"
}

$patchFile = Join-Path $rpcs3Dir 'patches\NPUB31250_patch.yml'
$patchConfig = Join-Path $rpcs3Dir 'config\patch_config.yml'
$logCandidates = @(
    (Join-Path $rpcs3Dir 'RPCS3.log'),
    (Join-Path $rpcs3Dir 'RPCS3.log.gz'),
    (Join-Path $rpcs3Dir 'log\RPCS3.log'),
    (Join-Path $rpcs3Dir 'logs\RPCS3.log')
)

Write-Host "RPCS3: $rpcs3Dir"
Write-Host ''

Write-Host '=== SIEC / TAILSCALE / RPCN ==='
$tailscaleCmd = Get-Command tailscale.exe -ErrorAction SilentlyContinue
if ($tailscaleCmd) {
    $tailscaleIp = (& $tailscaleCmd.Source ip -4 2>$null | Select-Object -First 1)
    if ($tailscaleIp) { Write-Host "Tailscale IPv4: $tailscaleIp" }
    else { Write-Host 'Tailscale IPv4: BRAK' }
}
else {
    Write-Host 'Tailscale: nie znaleziono tailscale.exe.'
}

$rpcnListen = $false
try {
    $rpcnListen = [bool](Get-NetTCPConnection -LocalPort 31313 -State Listen -ErrorAction Stop)
}
catch {}
Write-Host ("RPCN TCP 31313 nasluch: " + ($(if($rpcnListen){'OK'}else{'BRAK'})))

$fw = Get-NetFirewallRule -DisplayName 'Patras1993 RPCN TCP' -ErrorAction SilentlyContinue | Select-Object -First 1
if ($fw) {
    Write-Host ("Firewall RPCN TCP: " + $fw.Enabled + ', ' + $fw.Direction + ', ' + $fw.Action)
}
else {
    Write-Host 'Firewall RPCN TCP: BRAK REGULY'
}
Write-Host ''

if (Test-Path -LiteralPath $patchFile) {
    $patchText = Get-Content -LiteralPath $patchFile -Raw
    $count = ([regex]::Matches($patchText, '\[ be32,')).Count
    $hashOk = $patchText.Contains($expectedHash)
    Write-Host "PATCH FILE: OK"
    Write-Host "  sciezka: $patchFile"
    Write-Host "  be32: $count"
    Write-Host "  hash: $hashOk"
}
else {
    Write-Host "PATCH FILE: BRAK"
    Write-Host "  oczekiwano: $patchFile"
}

Write-Host ''

if (Test-Path -LiteralPath $patchConfig) {
    $configText = Get-Content -LiteralPath $patchConfig -Raw
    $descOk = $configText.Contains($expectedDescription)
    $enabledOk = $configText -match '(?ms)Patras1993 Revolution Runtime Patches.*?NPUB31250:.*?01\.05:.*?Enabled:\s*true'
    Write-Host "PATCH CONFIG: OK"
    Write-Host "  opis znaleziony: $descOk"
    Write-Host "  Enabled true: $enabledOk"
}
else {
    Write-Host "PATCH CONFIG: BRAK"
    Write-Host "  oczekiwano: $patchConfig"
}

Write-Host ''

$logPath = $logCandidates | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf -and $_ -notlike '*.gz' } | Select-Object -First 1

if (-not $logPath) {
    Write-Host 'RPCS3 LOG: nie znaleziono zwyklego tekstowego RPCS3.log.'
    Write-Host 'Po uruchomieniu gry zamknij RPCS3 i uruchom diagnostyk ponownie.'
    exit 0
}

Write-Host "RPCS3 LOG: $logPath"
$logLines = Get-Content -LiteralPath $logPath -ErrorAction Stop

$hashLine = $logLines | Where-Object { $_ -like "*PPU executable hash: $expectedHash*" } | Select-Object -Last 1
$applied = $logLines | Where-Object { $_ -like "*Applied patch*Patras1993 Revolution Runtime Patches*" } | Select-Object -Last 5
$patErrors = $logLines | Where-Object { $_ -match 'PAT:.*(Error|Fatal|Skipping|Failed)' } | Select-Object -Last 20
$tss = $logLines | Where-Object { $_ -like '*sceNpTssGetDataAsync*slotId=14*' } | Select-Object -Last 5

Write-Host ''
Write-Host '=== PPU HASH ==='
if ($hashLine) { $hashLine | ForEach-Object { Write-Host $_ } }
else { Write-Host 'Nie znaleziono oczekiwanego hasha w aktualnym logu.' }

Write-Host ''
Write-Host '=== APPLIED PATCH ==='
if ($applied) { $applied | ForEach-Object { Write-Host $_ } }
else { Write-Host 'BRAK wpisu Applied patch dla Patras1993 Revolution Runtime Patches.' }

Write-Host ''
Write-Host '=== PAT ERRORS ==='
if ($patErrors) { $patErrors | ForEach-Object { Write-Host $_ } }
else { Write-Host 'Brak bledow PAT w logu.' }

Write-Host ''
Write-Host '=== TSS SLOT 14 ==='
if ($tss) { $tss | ForEach-Object { Write-Host $_ } }
else { Write-Host 'Brak wywolania TSS slot 14 w aktualnym logu.' }

Write-Host ''
Write-Host '=== KONIEC DIAGNOSTYKI ==='
