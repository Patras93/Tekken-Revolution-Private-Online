$ErrorActionPreference = 'SilentlyContinue'

$hostDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$configPath = Join-Path $hostDir 'host_config.json'
$logDir = Join-Path $hostDir 'logs'

Write-Host '=== PATRAS1993 RPCN PROTOCOL DIAGNOSTIC ==='
Write-Host ''

if (-not (Test-Path -LiteralPath $configPath)) {
    Write-Host 'BLAD: brak host_config.json.'
    exit 2
}

$cfg = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
$rpcs3Dir = [string]$cfg.rpcs3_directory
$rpcs3Log = Join-Path $rpcs3Dir 'RPCS3.log'
$rpcnCfg = Join-Path $rpcs3Dir 'config\rpcn.yml'
$rpcnExe = Join-Path (Split-Path -Parent $hostDir) 'local_rpcn\rpcn.exe'
$versionMarker = Join-Path (Split-Path -Parent $hostDir) 'local_rpcn\rpcn_version.txt'
$rpcnOut = Join-Path $logDir 'rpcn.out.log'
$rpcnErr = Join-Path $logDir 'rpcn.err.log'

Write-Host '--- RPCN CONFIG ---'
if (Test-Path -LiteralPath $rpcnCfg) {
    Get-Content -LiteralPath $rpcnCfg | Where-Object { $_ -match '^(Host|Hosts):' } | ForEach-Object { Write-Host $_ }
} else {
    Write-Host 'Brak config\rpcn.yml'
}
Write-Host ''

Write-Host '--- RPCN VERSION MARKER ---'
if (Test-Path -LiteralPath $versionMarker) {
    Write-Host ((Get-Content -LiteralPath $versionMarker -Raw).Trim())
} else {
    Write-Host 'BRAK'
}
Write-Host ''

Write-Host '--- RPCN LISTENER TCP 31313 ---'
$listener = Get-NetTCPConnection -State Listen -LocalPort 31313 -ErrorAction SilentlyContinue | Select-Object -First 1
if ($listener) {
    Write-Host ('PID: ' + $listener.OwningProcess)
    $proc = Get-CimInstance Win32_Process -Filter ("ProcessId=" + $listener.OwningProcess) -ErrorAction SilentlyContinue
    if ($proc) {
        Write-Host ('EXE: ' + $proc.ExecutablePath)
        Write-Host ('CMD: ' + $proc.CommandLine)
    }
} else {
    Write-Host 'BRAK LISTENERA'
}
Write-Host ''

Write-Host '--- EXPECTED LOCAL RPCN EXE ---'
Write-Host $rpcnExe
if (Test-Path -LiteralPath $rpcnExe) {
    Write-Host ('SHA256: ' + (Get-FileHash -LiteralPath $rpcnExe -Algorithm SHA256).Hash)
} else {
    Write-Host 'BRAK PLIKU'
}
Write-Host ''

Write-Host '--- RPCN SERVER LOG ---'
if (Test-Path -LiteralPath $rpcnOut) {
    Get-Content -LiteralPath $rpcnOut -Tail 60 | ForEach-Object { Write-Host $_ }
} else {
    Write-Host 'Brak rpcn.out.log'
}
if (Test-Path -LiteralPath $rpcnErr) {
    $err = Get-Content -LiteralPath $rpcnErr -Tail 30
    if ($err) {
        Write-Host '--- RPCN STDERR ---'
        $err | ForEach-Object { Write-Host $_ }
    }
}
Write-Host ''

Write-Host '--- RPCS3 RPCN LOG ---'
if (Test-Path -LiteralPath $rpcs3Log) {
    $matches = Select-String -LiteralPath $rpcs3Log -Pattern 'RPCS3 v|RPCS3 0\.|rpcn:|Server returned protocol version|Protocol version' -CaseSensitive:$false
    if ($matches) {
        $matches | Select-Object -Last 80 | ForEach-Object { Write-Host $_.Line }
    } else {
        Write-Host 'Brak wpisow RPCN w RPCS3.log'
    }
} else {
    Write-Host 'Brak RPCS3.log'
}

Write-Host ''
Write-Host 'KONIEC DIAGNOSTYKI. Nic nie zostalo zmienione.'
